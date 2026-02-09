
// const { onValueUpdated } = require("firebase-functions/v2/database");
// const admin = require("firebase-admin");

// admin.initializeApp();

// exports.monitorFeedStorage = onValueUpdated(
//   "/users/{userId}/devices/mainStorage",
//   async (event) => {
//     try {
//       const userId = event.params.userId;

//       const beforeData = event.data.before.val();
//       const afterData = event.data.after.val();

//       if (!beforeData || !afterData) return;

//       const feedLevel = afterData.feedLevel;
//       const status = afterData.status;
//       const previousFeedLevel = beforeData.feedLevel;

//       console.log(
//         `📊 Feed level changed for user ${userId}: ${previousFeedLevel}% → ${feedLevel}%`
//       );

//       // LOW FEED ALERT
//       if (feedLevel <= 20 && status === "LOW" && previousFeedLevel > 20) {
//         console.log(`⚠️ LOW FEED ALERT for user ${userId}!`);

//         const userSnapshot = await admin
//           .database()
//           .ref(`/users/${userId}`)
//           .once("value");

//         const userData = userSnapshot.val();
//         const fcmToken = userData?.fcmToken;

//         if (!fcmToken) {
//           console.log(`❌ No FCM token found for user ${userId}`);
//           return;
//         }

//         const payload = {
//           notification: {
//             title: "🐷 Low Feed Alert!",
//             body: `Feed storage is at ${feedLevel}%. Time to refill your pig feeder!`,
//           },
//           data: {
//             type: "LOW_FEED",
//             feedLevel: feedLevel.toString(),
//             route: "/dashboard",
//           },
//         };

//         await admin.messaging().sendToDevice(fcmToken, payload);

//         await admin.database()
//           .ref(`/users/${userId}/notifications`)
//           .push({
//             type: "LOW_FEED",
//             message: `Feed storage is at ${feedLevel}%`,
//             feedLevel,
//             timestamp: admin.database.ServerValue.TIMESTAMP,
//             read: false,
//           });

//         console.log("✅ Low feed notification sent");
//       }

//       // FEED REFILLED
//       if (feedLevel > 20 && previousFeedLevel <= 20) {
//         console.log(`✅ Feed refilled for user ${userId}`);

//         const userSnapshot = await admin
//           .database()
//           .ref(`/users/${userId}`)
//           .once("value");

//         const fcmToken = userSnapshot.val()?.fcmToken;

//         if (fcmToken) {
//           await admin.messaging().sendToDevice(fcmToken, {
//             notification: {
//               title: "✅ Feed Refilled",
//               body: `Feed storage is now at ${feedLevel}%`,
//             },
//           });
//         }
//       }
//     } catch (error) {
//       console.error("❌ monitorFeedStorage error:", error);
//     }
//   }
// );

const { onValueWritten } = require("firebase-functions/v2/database");
const { initializeApp } = require("firebase-admin/app");
const { getDatabase } = require("firebase-admin/database");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.monitorFeedStorage = onValueWritten(
  {
    ref: "/users/{userId}/devices/mainStorage",
    region: "us-central1", // Change to your region if needed
  },
  async (event) => {

    console.log("🔥 monitorFeedStorage TRIGGERED");

    try {
      const userId = event.params.userId;

      const beforeData = event.data.before.val();
      const afterData = event.data.after.val();

      if (!afterData) {
        console.log("❌ No after data");
        return null;
      }

      const feedLevel = afterData.feedLevel || 0;
      const status = afterData.status || "UNKNOWN";
      const previousFeedLevel = beforeData ? beforeData.feedLevel || 0 : 100;

      console.log(
        `📊 Feed level changed for user ${userId}: ${previousFeedLevel}% → ${feedLevel}%`
      );

      // LOW FEED ALERT
      if (feedLevel <= 20 && status === "LOW" && previousFeedLevel > 20) {
        console.log(`⚠️ LOW FEED ALERT for user ${userId}!`);

        const db = getDatabase();
        const userSnapshot = await db.ref(`/users/${userId}`).once("value");

        const userData = userSnapshot.val();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
          console.log(`❌ No FCM token found for user ${userId}`);
          return null;
        }

        console.log(`📱 Sending notification to token: ${fcmToken.substring(0, 20)}...`);

        const message = {
          notification: {
            title: "🐷 Low Feed Alert!",
            body: `Feed storage is at ${feedLevel}%. Time to refill your pig feeder!`,
          },
          data: {
            type: "LOW_FEED",
            feedLevel: feedLevel.toString(),
            status: status,
            route: "/dashboard",
          },
          token: fcmToken,
        };

        try {
          const messaging = getMessaging();
          const response = await messaging.send(message);
          console.log("✅ Notification sent successfully:", response);

          // Save notification to database
          await db.ref(`/users/${userId}/notifications`).push({
            type: "LOW_FEED",
            title: "Low Feed Alert",
            message: `Feed storage is at ${feedLevel}%. Time to refill your pig feeder!`,
            feedLevel: feedLevel,
            status: status,
            timestamp: Date.now(),
            read: false,
          });

          console.log("✅ Notification saved to database");
        } catch (error) {
          console.error("❌ Error sending notification:", error);
        }

        return null;
      }

      // FEED REFILLED
      if (feedLevel > 20 && previousFeedLevel <= 20 && status === "SUFFICIENT") {
        console.log(`✅ Feed refilled for user ${userId}`);

        const db = getDatabase();
        const userSnapshot = await db.ref(`/users/${userId}`).once("value");
        const fcmToken = userSnapshot.val()?.fcmToken;

        if (fcmToken) {
          const message = {
            notification: {
              title: "✅ Feed Refilled",
              body: `Feed storage is now at ${feedLevel}%. Thank you!`,
            },
            data: {
              type: "FEED_REFILLED",
              feedLevel: feedLevel.toString(),
              status: status,
            },
            token: fcmToken,
          };

          try {
            const messaging = getMessaging();
            await messaging.send(message);
            console.log("✅ Refill notification sent");
          } catch (error) {
            console.error("❌ Error sending refill notification:", error);
          }
        }
      }

      return null;
    } catch (error) {
      console.error("❌ monitorFeedStorage error:", error);
      return null;
    }
  }
);