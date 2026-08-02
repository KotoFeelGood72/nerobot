const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const nodemailer = require('nodemailer');
const crypto = require('crypto');

initializeApp();

const SMTP_PASSWORD = defineSecret('SMTP_PASSWORD');

const OTP_TTL_MS = 10 * 60 * 1000;
const RESEND_COOLDOWN_MS = 60 * 1000;
const MAX_ATTEMPTS = 5;
const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

const SMTP_HOST = process.env.SMTP_HOST || 'sm39.hosting.reg.ru';
const SMTP_PORT = Number(process.env.SMTP_PORT || 465);
const SMTP_USER = process.env.SMTP_USER || 'info@raznorabochii.ru';
const SMTP_FROM =
  process.env.SMTP_FROM || '"Разнорабочий" <info@raznorabochii.ru>';

/** Тестовые входы: TEST_LOGIN_EMAILS=a@x.ru,b@y.ru  TEST_LOGIN_OTP=111111 */
function getTestLoginConfig() {
  const emails = String(process.env.TEST_LOGIN_EMAILS || '')
    .split(',')
    .map((e) => normalizeEmail(e))
    .filter(Boolean);
  const code = String(process.env.TEST_LOGIN_OTP || '').trim();
  return {
    emails: new Set(emails),
    code: /^\d{6}$/.test(code) ? code : null,
  };
}

function isTestLoginEmail(email) {
  const { emails, code } = getTestLoginConfig();
  return Boolean(code && emails.has(email));
}

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function otpDocId(email) {
  return crypto.createHash('sha256').update(email).digest('hex');
}

function hashOtp(code, salt) {
  return crypto.createHash('sha256').update(`${salt}:${code}`).digest('hex');
}

function generateOtp() {
  return String(crypto.randomInt(100000, 1000000));
}

function isEmulator() {
  return process.env.FUNCTIONS_EMULATOR === 'true';
}

function resolveSmtpPassword() {
  // В проде — Secret Manager; локально/эмулятор — env.
  try {
    const secret = SMTP_PASSWORD.value();
    if (secret) return secret;
  } catch (_) {
    // secret не привязан (эмулятор / локальный запуск)
  }
  return process.env.SMTP_PASSWORD || '';
}

function createTransport() {
  const pass = resolveSmtpPassword();
  if (!pass) {
    throw new Error('SMTP_PASSWORD is not configured');
  }

  return nodemailer.createTransport({
    host: SMTP_HOST,
    port: SMTP_PORT,
    secure: SMTP_PORT === 465,
    auth: {
      user: SMTP_USER,
      pass,
    },
    tls: {
      // Сертификат может быть на имя хостинга, а не на IP.
      rejectUnauthorized: false,
    },
  });
}

async function sendOtpEmail(toEmail, code) {
  const transporter = createTransport();
  await transporter.sendMail({
    from: SMTP_FROM,
    to: toEmail,
    subject: 'Код входа в Разнорабочий',
    text: `Ваш код для входа: ${code}\n\nКод действует 10 минут.\nЕсли вы не запрашивали вход — просто проигнорируйте письмо.`,
    html: `
      <div style="font-family:Arial,sans-serif;line-height:1.5">
        <p>Ваш код для входа:</p>
        <p style="font-size:28px;font-weight:700;letter-spacing:4px">${code}</p>
        <p>Код действует 10 минут.</p>
        <p style="color:#666">Если вы не запрашивали вход — просто проигнорируйте письмо.</p>
      </div>
    `,
  });
}

exports.sendEmailOtp = onCall(
  {
    region: 'europe-west1',
    secrets: [SMTP_PASSWORD],
  },
  async (request) => {
    const email = normalizeEmail(request.data?.email);
    if (!EMAIL_RE.test(email)) {
      throw new HttpsError('invalid-argument', 'Неверный формат email');
    }

    const db = getFirestore();
    const ref = db.collection('email_otps').doc(otpDocId(email));
    const existing = await ref.get();
    const now = Date.now();
    const testLogin = isTestLoginEmail(email);

    if (existing.exists && !testLogin) {
      const lastSentAt = existing.data()?.lastSentAt?.toMillis?.() ?? 0;
      if (now - lastSentAt < RESEND_COOLDOWN_MS) {
        throw new HttpsError(
          'resource-exhausted',
          'Код уже отправлен. Подождите минуту перед повторной отправкой',
        );
      }
    }

    const code = testLogin ? getTestLoginConfig().code : generateOtp();
    const salt = crypto.randomBytes(16).toString('hex');

    await ref.set({
      email,
      codeHash: hashOtp(code, salt),
      salt,
      attempts: 0,
      createdAt: FieldValue.serverTimestamp(),
      lastSentAt: FieldValue.serverTimestamp(),
      expiresAt: new Date(now + (testLogin ? 24 * 60 * 60 * 1000 : OTP_TTL_MS)),
      isTestLogin: testLogin,
    });

    if (testLogin) {
      // Письмо не отправляем — код фиксированный из env.
      return { ok: true };
    }

    try {
      await sendOtpEmail(email, code);
    } catch (e) {
      console.error('Failed to send OTP email', e);
      await ref.delete().catch(() => {});
      throw new HttpsError('internal', 'Не удалось отправить письмо');
    }

    const response = { ok: true };
    if (isEmulator()) {
      response.debugCode = code;
    }
    return response;
  },
);

exports.verifyEmailOtp = onCall({ region: 'europe-west1' }, async (request) => {
  const email = normalizeEmail(request.data?.email);
  const code = String(request.data?.code || '').trim();

  if (!EMAIL_RE.test(email)) {
    throw new HttpsError('invalid-argument', 'Неверный формат email');
  }
  if (!/^\d{6}$/.test(code)) {
    throw new HttpsError('invalid-argument', 'Введите 6-значный код');
  }

  const db = getFirestore();
  const ref = db.collection('email_otps').doc(otpDocId(email));
  const snap = await ref.get();

  if (!snap.exists) {
    throw new HttpsError('not-found', 'Сначала запросите код');
  }

  const data = snap.data();
  const expiresAt = data.expiresAt?.toMillis?.() ?? data.expiresAt?.getTime?.() ?? 0;
  if (Date.now() > expiresAt) {
    await ref.delete();
    throw new HttpsError('deadline-exceeded', 'Код истёк. Запросите новый');
  }

  if ((data.attempts || 0) >= MAX_ATTEMPTS) {
    await ref.delete();
    throw new HttpsError(
      'resource-exhausted',
      'Слишком много попыток. Запросите новый код',
    );
  }

  const expected = hashOtp(code, data.salt);
  if (expected !== data.codeHash) {
    await ref.update({ attempts: FieldValue.increment(1) });
    throw new HttpsError('permission-denied', 'Неверный код');
  }

  const auth = getAuth();
  let user;
  try {
    user = await auth.getUserByEmail(email);
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      user = await auth.createUser({
        email,
        emailVerified: true,
      });
    } else {
      console.error('get/create user failed', e);
      throw new HttpsError('internal', 'Не удалось создать пользователя');
    }
  }

  let customToken;
  try {
    customToken = await auth.createCustomToken(user.uid, { email });
  } catch (e) {
    console.error('createCustomToken failed', e);
    throw new HttpsError('internal', 'Не удалось выдать токен входа');
  }

  await ref.delete();
  return { customToken };
});

const {
  onOrderCreated,
  onResponseCreated,
  onChatUpdated,
  onInactiveUsersReminder,
} = require('./notifications');

exports.onOrderCreated = onOrderCreated;
exports.onResponseCreated = onResponseCreated;
exports.onChatUpdated = onChatUpdated;
exports.onInactiveUsersReminder = onInactiveUsersReminder;

const { deleteAccount } = require('./delete_account');
exports.deleteAccount = deleteAccount;
