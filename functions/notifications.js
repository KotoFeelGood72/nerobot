const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

const ANDROID_CHANNEL_ID = 'nerobot_alerts_v2';
const INACTIVE_DAYS = 7;
const INACTIVE_NOTIFY_COOLDOWN_DAYS = 7;

function cityTopicId(city) {
  const normalized = String(city || '').trim().toLowerCase();
  if (!normalized) return null;
  const encoded = Buffer.from(normalized, 'utf8')
    .toString('base64url')
    .replace(/=/g, '')
    .slice(0, 16);
  return `city_${encoded}`;
}

function prefEnabled(prefs, key, defaultValue = true) {
  if (!prefs || typeof prefs !== 'object') return defaultValue;
  if (prefs[key] === undefined) return defaultValue;
  return prefs[key] === true;
}

function buildMessage({ title, body, data = {} }) {
  const stringData = {};
  for (const [key, value] of Object.entries(data)) {
    if (value !== undefined && value !== null) {
      stringData[key] = String(value);
    }
  }

  return {
    notification: { title, body },
    data: stringData,
    android: {
      priority: 'high',
      notification: {
        channelId: ANDROID_CHANNEL_ID,
        // Маленькая иконка (drawable без расширения) + цвет бренда
        icon: 'ic_stat_notification',
        color: '#5E5BE6',
        sound: 'default',
        defaultSound: true,
        defaultVibrateTimings: true,
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        },
      },
    },
  };
}

async function sendToTokens(tokens, payload) {
  const uniqueTokens = [...new Set(tokens.filter(Boolean))];
  if (uniqueTokens.length === 0) return;

  const messaging = getMessaging();
  const response = await messaging.sendEachForMulticast({
    tokens: uniqueTokens,
    ...payload,
  });

  if (response.failureCount > 0) {
    console.warn(
      `Push partial failure: ${response.failureCount}/${uniqueTokens.length}`,
    );
  }
}

async function sendToUser(uid, { title, body, data, prefKey }) {
  if (!uid) return;

  const db = getFirestore();
  const snap = await db.collection('users').doc(uid).get();
  if (!snap.exists) return;

  const user = snap.data();
  const prefs = user.notificationPreferences || {};
  if (prefKey && !prefEnabled(prefs, prefKey)) return;

  const tokens = user.device_tokens || [];
  await sendToTokens(tokens, buildMessage({ title, body, data }));
}

async function sendToTopic(topic, { title, body, data }) {
  if (!topic) return;

  const messaging = getMessaging();
  await messaging.send({
    topic,
    ...buildMessage({ title, body, data }),
  });
}

async function notifyWorkersAboutNewOrder(orderId, order) {
  const city = order.city;
  const title = order.title || 'Новое задание';
  const bodyCity = `Есть задание в вашем городе: «${title}»`;
  const bodyNew = `Появилось новое задание: «${title}»`;
  const data = {
    type: 'new_task',
    orderId,
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
  };

  if (city) {
    const topic = cityTopicId(city);
    await sendToTopic(topic, {
      title: 'Задание в вашем городе',
      body: bodyCity,
      data: { ...data, subtype: 'city_task' },
    });
  }

  await sendToTopic('new_tasks', {
    title: 'Есть новые задания',
    body: bodyNew,
    data: { ...data, subtype: 'new_tasks' },
  });
}

const onOrderCreated = onDocumentCreated(
  {
    document: 'orders/{orderId}',
    region: 'europe-west1',
  },
  async (event) => {
    const order = event.data?.data();
    if (!order) return;

    if (order.deleted === true) return;
    if (order.status && order.status !== 'open') return;

    await notifyWorkersAboutNewOrder(event.params.orderId, order);
  },
);

const onResponseCreated = onDocumentCreated(
  {
    document: 'responses/{responseId}',
    region: 'europe-west1',
  },
  async (event) => {
    const response = event.data?.data();
    if (!response) return;

    const creatorId = response.order_creator;
    const orderId = response.order;
    if (!creatorId || !orderId) return;

    const db = getFirestore();
    const orderSnap = await db.collection('orders').doc(orderId).get();
    const orderTitle = orderSnap.data()?.title || 'ваше задание';

    await sendToUser(creatorId, {
      title: 'Новый отклик',
      body: `На ваше задание «${orderTitle}» откликнулись`,
      prefKey: 'orderResponse',
      data: {
        type: 'order_response',
        orderId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    });
  },
);

const onChatUpdated = onDocumentUpdated(
  {
    document: 'chats/{chatId}',
    region: 'europe-west1',
  },
  async (event) => {
    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};

    const beforeMessages = Array.isArray(before.messages) ? before.messages : [];
    const afterMessages = Array.isArray(after.messages) ? after.messages : [];
    if (afterMessages.length <= beforeMessages.length) return;

    const lastMessage = afterMessages[afterMessages.length - 1];
    if (!lastMessage || typeof lastMessage !== 'object') return;

    const senderId = lastMessage.sender;
    const text = String(lastMessage.text || '').trim();
    if (!senderId || !text) return;

    const participants = Array.isArray(after.participants)
      ? after.participants
      : [];
    const recipients = participants.filter((uid) => uid && uid !== senderId);
    if (recipients.length === 0) return;

    const orderId = after.order_id || lastMessage.order_id || '';
    const preview = text.length > 120 ? `${text.slice(0, 117)}...` : text;

    await Promise.all(
      recipients.map((uid) =>
        sendToUser(uid, {
          title: 'Новое сообщение',
          body: `Вам написали: ${preview}`,
          prefKey: 'messages',
          data: {
            type: 'chat_message',
            chatId: event.params.chatId,
            orderId,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
        }),
      ),
    );
  },
);

const onInactiveUsersReminder = onSchedule(
  {
    schedule: '0 10 * * *',
    timeZone: 'Europe/Moscow',
    region: 'europe-west1',
  },
  async () => {
    const db = getFirestore();
    const now = Date.now();
    const inactiveMs = INACTIVE_DAYS * 24 * 60 * 60 * 1000;
    const cooldownMs = INACTIVE_NOTIFY_COOLDOWN_DAYS * 24 * 60 * 60 * 1000;

    const usersSnap = await db.collection('users').get();
    const tasks = [];

    for (const doc of usersSnap.docs) {
      const user = doc.data();
      const prefs = user.notificationPreferences || {};
      if (!prefEnabled(prefs, 'inactiveReminder')) continue;

      const tokens = user.device_tokens || [];
      if (tokens.length === 0) continue;

      const lastActiveRaw = user.lastActiveAt;
      const lastActiveMs =
        lastActiveRaw?.toMillis?.() ??
        (typeof lastActiveRaw === 'number' ? lastActiveRaw : 0);
      if (!lastActiveMs || now - lastActiveMs < inactiveMs) continue;

      const lastNotifyRaw = user.lastInactiveNotifyAt;
      const lastNotifyMs =
        lastNotifyRaw?.toMillis?.() ??
        (typeof lastNotifyRaw === 'number' ? lastNotifyRaw : 0);
      if (lastNotifyMs && now - lastNotifyMs < cooldownMs) continue;

      tasks.push(
        (async () => {
          await sendToTokens(
            tokens,
            buildMessage({
              title: 'Давно не виделись',
              body: 'Вы давно не заходили. Загляните — возможно, есть новые задания',
              data: {
                type: 'inactive_reminder',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
              },
            }),
          );
          await doc.ref.update({
            lastInactiveNotifyAt: FieldValue.serverTimestamp(),
          });
        })(),
      );
    }

    await Promise.all(tasks);
  },
);

module.exports = {
  onOrderCreated,
  onResponseCreated,
  onChatUpdated,
  onInactiveUsersReminder,
  cityTopicId,
};
