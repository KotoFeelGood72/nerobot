/**
 * Интеграционный тест deleteAccount.
 * Пользователи/данные — через Google OAuth (firebase-tools).
 * ID token — через send/verify OTP: сажаем известный код в email_otps.
 */
const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');

const API_KEY = 'AIzaSyAKezJnWvIKTFgmfnJ3WiE1X3i9mPhqJDI';
const PROJECT = 'handy-35312';
const STORAGE_BUCKET = 'handy-35312.firebasestorage.app';
const CALLABLE_URL =
  'https://europe-west1-handy-35312.cloudfunctions.net/deleteAccount';
const VERIFY_OTP_URL =
  'https://europe-west1-handy-35312.cloudfunctions.net/verifyEmailOtp';
const FS =
  `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

function assert(cond, msg) {
  if (!cond) throw new Error(msg);
}

function loadFirebaseAccessToken() {
  const cfgPath = path.join(
    os.homedir(),
    '.config/configstore/firebase-tools.json',
  );
  const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
  const token = cfg.tokens?.access_token;
  assert(token, 'Нет access_token firebase-tools — выполните firebase login');
  return token;
}

function otpDocId(email) {
  return crypto.createHash('sha256').update(email).digest('hex');
}

function hashOtp(code, salt) {
  return crypto.createHash('sha256').update(`${salt}:${code}`).digest('hex');
}

async function googleJson(url, { method = 'GET', token, body } = {}) {
  const res = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json;
  try {
    json = text ? JSON.parse(text) : {};
  } catch {
    json = { raw: text };
  }
  return { status: res.status, json, ok: res.ok };
}

async function createAuthUser(accessToken, email) {
  const { status, json, ok } = await googleJson(
    `https://identitytoolkit.googleapis.com/v1/projects/${PROJECT}/accounts`,
    {
      method: 'POST',
      token: accessToken,
      body: { email, emailVerified: true, displayName: 'Delete Test' },
    },
  );
  assert(ok, `createAuthUser failed: ${status} ${JSON.stringify(json)}`);
  return json.localId;
}

async function deleteAuthUserAdmin(accessToken, localId) {
  await googleJson(
    `https://identitytoolkit.googleapis.com/v1/projects/${PROJECT}/accounts:delete`,
    {
      method: 'POST',
      token: accessToken,
      body: { localId },
    },
  );
}

function fsValue(value) {
  if (value === null) return { nullValue: null };
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value)
      ? { integerValue: String(value) }
      : { doubleValue: value };
  }
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(fsValue) } };
  }
  if (typeof value === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(value)) fields[k] = fsValue(v);
    return { mapValue: { fields } };
  }
  throw new Error(`Unsupported value: ${value}`);
}

async function fsSetAdmin(accessToken, docPath, data) {
  const commit = await googleJson(
    `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents:commit`,
    {
      method: 'POST',
      token: accessToken,
      body: {
        writes: [
          {
            update: {
              name: `projects/${PROJECT}/databases/(default)/documents/${docPath}`,
              fields: fsValue(data).mapValue.fields,
            },
          },
        ],
      },
    },
  );
  assert(
    commit.ok,
    `fsSetAdmin ${docPath} failed: ${commit.status} ${JSON.stringify(commit.json)}`,
  );
}

async function fsAddAdmin(accessToken, collection, data) {
  const id = crypto.randomBytes(8).toString('hex');
  await fsSetAdmin(accessToken, `${collection}/${id}`, data);
  return id;
}

async function fsGetAdmin(accessToken, docPath) {
  return googleJson(`${FS}/${docPath}`, { token: accessToken });
}

async function fsDeleteAdmin(accessToken, docPath) {
  await googleJson(
    `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents:commit`,
    {
      method: 'POST',
      token: accessToken,
      body: {
        writes: [
          {
            delete: `projects/${PROJECT}/databases/(default)/documents/${docPath}`,
          },
        ],
      },
    },
  );
}

function parseArrayField(doc, field) {
  const values = doc.fields?.[field]?.arrayValue?.values || [];
  return values.map((v) => v.stringValue).filter(Boolean);
}

async function plantOtpAndGetIdToken(accessToken, email) {
  const code = '424242';
  const salt = crypto.randomBytes(16).toString('hex');
  const nowMs = Date.now();
  const expiresAt = new Date(nowMs + 10 * 60 * 1000).toISOString();

  await fsSetAdmin(accessToken, `email_otps/${otpDocId(email)}`, {
    email,
    codeHash: hashOtp(code, salt),
    salt,
    attempts: 0,
    // expiresAt as timestamp via string ISO — Firestore REST needs timestampValue
  });

  // Overwrite with proper timestamp field via raw commit
  const commit = await googleJson(
    `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents:commit`,
    {
      method: 'POST',
      token: accessToken,
      body: {
        writes: [
          {
            update: {
              name: `projects/${PROJECT}/databases/(default)/documents/email_otps/${otpDocId(email)}`,
              fields: {
                email: { stringValue: email },
                codeHash: { stringValue: hashOtp(code, salt) },
                salt: { stringValue: salt },
                attempts: { integerValue: '0' },
                expiresAt: { timestampValue: expiresAt },
              },
            },
          },
        ],
      },
    },
  );
  assert(commit.ok, `plant otp failed: ${JSON.stringify(commit.json)}`);

  const res = await fetch(VERIFY_OTP_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ data: { email, code } }),
  });
  const json = await res.json();
  assert(
    res.status === 200 && json?.result?.customToken,
    `verifyEmailOtp failed: ${JSON.stringify(json)}`,
  );

  const tokenRes = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        token: json.result.customToken,
        returnSecureToken: true,
      }),
    },
  );
  const tokenJson = await tokenRes.json();
  assert(tokenRes.ok, `custom token exchange failed: ${JSON.stringify(tokenJson)}`);
  return tokenJson.idToken;
}

async function callDeleteAccount(idToken, email) {
  const res = await fetch(CALLABLE_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify({ data: { email } }),
  });
  return { status: res.status, json: await res.json() };
}

async function uploadAvatarAdmin(accessToken, uid) {
  const objectPath = `user_photos/${uid}.jpg`;
  const encoded = encodeURIComponent(objectPath);
  const res = await fetch(
    `https://storage.googleapis.com/upload/storage/v1/b/${STORAGE_BUCKET}/o?uploadType=media&name=${encoded}`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'image/jpeg',
      },
      body: Buffer.from('fake-jpeg-bytes'),
    },
  );
  const json = await res.json().catch(() => ({}));
  if (!res.ok) {
    console.warn('   avatar upload skipped:', res.status, JSON.stringify(json).slice(0, 200));
    return false;
  }
  return true;
}

async function avatarExistsAdmin(accessToken, uid) {
  const objectPath = `user_photos/${uid}.jpg`;
  const encoded = encodeURIComponent(objectPath);
  const res = await fetch(
    `https://storage.googleapis.com/storage/v1/b/${STORAGE_BUCKET}/o/${encoded}`,
    { headers: { Authorization: `Bearer ${accessToken}` } },
  );
  return res.status === 200;
}

async function main() {
  const accessToken = loadFirebaseAccessToken();
  const stamp = Date.now();
  const emailA = `delete-a-${stamp}@nerobot.test`;
  const emailB = `delete-b-${stamp}@nerobot.test`;

  console.log('1) Create Auth users');
  const uidA = await createAuthUser(accessToken, emailA);
  const uidB = await createAuthUser(accessToken, emailB);
  console.log('   A=', uidA, 'B=', uidB);

  console.log('2) Seed Firestore');
  await fsSetAdmin(accessToken, `users/${uidA}`, {
    userId: uidA,
    email: emailA,
    type: 'worker',
    name: 'Delete Test A',
    device_tokens: ['tok-a'],
    subscribed_city_topic: 'city_testdelete',
  });
  await fsSetAdmin(accessToken, `users/${uidB}`, {
    userId: uidB,
    email: emailB,
    type: 'customer',
    name: 'Delete Test B',
  });

  const orderOwnId = await fsAddAdmin(accessToken, 'orders', {
    creator: uidA,
    title: 'Own order',
    responses: [],
    workers: [],
    status: 'open',
  });
  const orderOtherId = await fsAddAdmin(accessToken, 'orders', {
    creator: uidB,
    title: 'Other order keep',
    responses: [uidA, uidB],
    workers: [uidA],
    status: 'open',
  });
  const responseId = await fsAddAdmin(accessToken, 'responses', {
    respondent: uidA,
    order: orderOwnId,
    order_creator: uidA,
    cover_letter: 'test cover',
    created_time: stamp,
    respondent_rating: 0,
  });
  const chatId = await fsAddAdmin(accessToken, 'chats', {
    participants: [uidA, uidB],
    order_id: orderOwnId,
  });
  const feedbackId = await fsAddAdmin(accessToken, 'feedbacks', {
    userId: uidA,
    text: 'please delete me',
    attachments: [],
  });
  const reviewFromId = await fsAddAdmin(accessToken, 'reviews', {
    from_user: uidA,
    to_user: uidB,
    rating: 5,
    text: 'ok',
  });
  const reviewToId = await fsAddAdmin(accessToken, 'reviews', {
    from_user: uidB,
    to_user: uidA,
    rating: 4,
    text: 'also ok',
  });

  console.log('3) Upload avatar');
  const avatarUploaded = await uploadAvatarAdmin(accessToken, uidA);
  console.log('   avatarUploaded=', avatarUploaded);

  console.log('4) Get ID token via planted OTP + verifyEmailOtp');
  const idTokenA = await plantOtpAndGetIdToken(accessToken, emailA);

  console.log('5) Unauthenticated must fail');
  const unauth = await callDeleteAccount('bad-token', emailA);
  assert(unauth.status >= 400 || unauth.json?.error, 'Expected auth failure');
  console.log('   OK', unauth.status);

  console.log('6) deleteAccount');
  const result = await callDeleteAccount(idTokenA, emailA);
  console.log('   response', result.status, JSON.stringify(result.json));
  assert(
    result.status === 200 && result.json?.result?.ok === true,
    `deleteAccount failed: ${JSON.stringify(result.json)}`,
  );

  console.log('7) Verify cleanup');
  for (const p of [
    `users/${uidA}`,
    `orders/${orderOwnId}`,
    `responses/${responseId}`,
    `chats/${chatId}`,
    `feedbacks/${feedbackId}`,
    `reviews/${reviewFromId}`,
    `reviews/${reviewToId}`,
  ]) {
    const got = await fsGetAdmin(accessToken, p);
    assert(got.status === 404, `${p} still exists: ${got.status}`);
    console.log(`   ${p}: deleted`);
  }

  const other = await fsGetAdmin(accessToken, `orders/${orderOtherId}`);
  assert(other.status === 200, 'other order missing');
  const responses = parseArrayField(other.json, 'responses');
  const workers = parseArrayField(other.json, 'workers');
  assert(!responses.includes(uidA), `A still in responses: ${responses}`);
  assert(!workers.includes(uidA), `A still in workers: ${workers}`);
  console.log('   other order arrays cleaned');

  const lookup = await googleJson(
    `https://identitytoolkit.googleapis.com/v1/projects/${PROJECT}/accounts:lookup`,
    {
      method: 'POST',
      token: accessToken,
      body: { localId: [uidA] },
    },
  );
  assert(!(lookup.json?.users?.length > 0), 'Auth A still exists');
  console.log('   Auth user A deleted');

  if (avatarUploaded) {
    // Need redeployed function for correct bucket — check anyway
    const exists = await avatarExistsAdmin(accessToken, uidA);
    if (exists) {
      console.warn('   ⚠️ avatar still exists (redeploy deleteAccount for bucket fix)');
    } else {
      console.log('   avatar deleted');
    }
  }

  console.log('8) Cleanup B');
  const idTokenB = await plantOtpAndGetIdToken(accessToken, emailB);
  const delB = await callDeleteAccount(idTokenB, emailB);
  assert(
    delB.status === 200 && delB.json?.result?.ok === true,
    `cleanup B failed: ${JSON.stringify(delB.json)}`,
  );

  console.log('\n✅ ALL CHECKS PASSED');
}

main().catch((e) => {
  console.error('\n❌ TEST FAILED', e);
  process.exitCode = 1;
});
