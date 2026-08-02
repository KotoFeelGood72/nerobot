const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const crypto = require('crypto');

const BATCH_LIMIT = 400;

function otpDocId(email) {
  return crypto.createHash('sha256').update(email).digest('hex');
}

async function commitBatches(db, refsToDelete, updates = []) {
  let batch = db.batch();
  let ops = 0;

  const flush = async () => {
    if (ops === 0) return;
    await batch.commit();
    batch = db.batch();
    ops = 0;
  };

  for (const ref of refsToDelete) {
    batch.delete(ref);
    ops += 1;
    if (ops >= BATCH_LIMIT) await flush();
  }

  for (const { ref, data } of updates) {
    batch.update(ref, data);
    ops += 1;
    if (ops >= BATCH_LIMIT) await flush();
  }

  await flush();
}

async function collectQueryRefs(query) {
  const snap = await query.get();
  return snap.docs.map((d) => d.ref);
}

function storagePathFromDownloadUrl(url) {
  try {
    const marker = '/o/';
    const idx = String(url).indexOf(marker);
    if (idx === -1) return null;
    const rest = String(url).substring(idx + marker.length);
    const encoded = rest.split('?')[0];
    return decodeURIComponent(encoded);
  } catch (_) {
    return null;
  }
}

async function deleteStoragePrefix(bucket, prefix) {
  try {
    const [files] = await bucket.getFiles({ prefix });
    await Promise.all(files.map((file) => file.delete().catch(() => {})));
  } catch (e) {
    console.warn(`Storage prefix cleanup failed for ${prefix}`, e.message);
  }
}

async function deleteUserStorage(uid, feedbackUrls = []) {
  // Новый Firebase Storage bucket (не *.appspot.com).
  const bucket = getStorage().bucket(
    process.env.FIREBASE_STORAGE_BUCKET || 'handy-35312.firebasestorage.app',
  );

  await bucket.file(`user_photos/${uid}.jpg`).delete().catch(() => {});
  await deleteStoragePrefix(bucket, `user_photos/${uid}/`);

  for (const url of feedbackUrls) {
    const path = storagePathFromDownloadUrl(url);
    if (path) {
      await bucket.file(path).delete().catch(() => {});
    }
  }
}

/**
 * Каскадное удаление аккаунта (Admin SDK).
 * Клиент должен быть авторизован; Auth-пользователь удаляется в конце.
 */
exports.deleteAccount = onCall({ region: 'europe-west1' }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Нужна авторизация');
  }

  const uid = request.auth.uid;
  const db = getFirestore();
  const auth = getAuth();

  let email =
    normalizeOptionalEmail(request.auth.token?.email) ||
    normalizeOptionalEmail(request.data?.email);

  try {
    const userSnap = await db.collection('users').doc(uid).get();
    const userData = userSnap.data() || {};
    if (!email) {
      email = normalizeOptionalEmail(userData.email);
    }

    // Feedbacks + вложения
    const feedbackSnaps = await db
      .collection('feedbacks')
      .where('userId', '==', uid)
      .get();
    const feedbackUrls = [];
    const feedbackRefs = [];
    for (const doc of feedbackSnaps.docs) {
      feedbackRefs.push(doc.ref);
      const attachments = doc.data()?.attachments;
      if (Array.isArray(attachments)) {
        for (const url of attachments) {
          if (typeof url === 'string') feedbackUrls.push(url);
        }
      }
    }

    await deleteUserStorage(uid, feedbackUrls);

    const refsToDelete = [...feedbackRefs];

    // Responses где пользователь — исполнитель
    refsToDelete.push(
      ...(await collectQueryRefs(
        db.collection('responses').where('respondent', '==', uid),
      )),
    );

    // Reviews
    refsToDelete.push(
      ...(await collectQueryRefs(
        db.collection('reviews').where('from_user', '==', uid),
      )),
      ...(await collectQueryRefs(
        db.collection('reviews').where('to_user', '==', uid),
      )),
    );

    // Свои заказы
    refsToDelete.push(
      ...(await collectQueryRefs(
        db.collection('orders').where('creator', '==', uid),
      )),
    );

    // Чаты с участием пользователя
    refsToDelete.push(
      ...(await collectQueryRefs(
        db.collection('chats').where('participants', 'array-contains', uid),
      )),
    );

    // Чужие заказы: убрать uid из responses / workers
    const updates = [];
    const ordersWithResponse = await db
      .collection('orders')
      .where('responses', 'array-contains', uid)
      .get();
    for (const doc of ordersWithResponse.docs) {
      if (doc.data()?.creator === uid) continue; // уже удалим целиком
      updates.push({
        ref: doc.ref,
        data: { responses: FieldValue.arrayRemove(uid) },
      });
    }

    const ordersWithWorker = await db
      .collection('orders')
      .where('workers', 'array-contains', uid)
      .get();
    for (const doc of ordersWithWorker.docs) {
      if (doc.data()?.creator === uid) continue;
      updates.push({
        ref: doc.ref,
        data: { workers: FieldValue.arrayRemove(uid) },
      });
    }

    // Профиль
    refsToDelete.push(db.collection('users').doc(uid));

    // OTP-запись по email
    if (email) {
      refsToDelete.push(db.collection('email_otps').doc(otpDocId(email)));
    }

    await commitBatches(db, refsToDelete, updates);

    try {
      await auth.deleteUser(uid);
    } catch (e) {
      if (e.code !== 'auth/user-not-found') {
        console.error('auth.deleteUser failed', e);
        throw new HttpsError('internal', 'Не удалось удалить аккаунт Auth');
      }
    }

    return { ok: true };
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    console.error('deleteAccount failed', uid, e);
    throw new HttpsError('internal', 'Не удалось удалить аккаунт');
  }
});

function normalizeOptionalEmail(value) {
  const email = String(value || '')
    .trim()
    .toLowerCase();
  return email.includes('@') ? email : '';
}
