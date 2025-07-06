const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendMessageNotification = functions
  .region("us-central1")
  .firestore
  .document("users/{senderId}/chats/{receiverId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const message = snap.data();

    // 👇 SADECE gerçek gönderenin koleksiyonundaki tetikte devam et
    if (context.params.senderId !== message.senderUserId) {
      console.log("Duplicate message document — no notification sent");
      return;
    }

    const receiverId = context.params.receiverId;
    const userDoc = await admin.firestore().doc(`users/${receiverId}`).get();
    const token = userDoc.data()?.fcmToken;

    if (!token) {
      console.warn("No FCM token for receiver:", receiverId);
      return;
    }

    const payload = {
      token,
      notification: {
        title: message.senderUserName || "Yeni Mesaj",
        body: message.lastMessage || "Bir mesajınız var!",
      },
      data: {
        senderId: String(message.senderUserId),
        messageId: String(message.messageId),
      },
    };

    try {
      const resp = await admin.messaging().send(payload);
      console.log("Notification sent:", resp);
    } catch (err) {
      console.error("Notification error:", err);
    }
  });
