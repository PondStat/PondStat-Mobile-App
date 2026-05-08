import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const BASE_PATH = "artifacts/pondstat-app-v1/public/data";

/**
 * Triggered when a new measurement is recorded.
 * If an 'alert' payload is present, it sends push notifications to all pond members
 * and logs the notification in their in-app inbox.
 */
export const onMeasurementCreated = functions.firestore
  .document(`${BASE_PATH}/measurements/{measurementId}`)
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    if (!data || !data.alert) {
      return null;
    }

    const {pondId, alert} = data;
    const {title, body} = alert;

    try {
      // 1. Get pond members
      const pondDoc = await db.doc(`${BASE_PATH}/ponds/${pondId}`).get();
      if (!pondDoc.exists) {
        console.error(`Pond ${pondId} not found`);
        return null;
      }

      const memberIds: string[] = pondDoc.data()?.memberIds || [];
      if (memberIds.length === 0) {
        return null;
      }

      // 2. Fetch FCM tokens and write to in-app inbox for each member
      const tokens: string[] = [];
      const notificationPromises: Promise<any>[] = [];

      for (const memberId of memberIds) {
        // Write to in-app notifications subcollection
        const notificationRef = db
          .collection(`${BASE_PATH}/users/${memberId}/notifications`)
          .doc();

        notificationPromises.push(
          notificationRef.set({
            title,
            body,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false,
            type: "alert",
            pondId,
            measurementId: context.params.measurementId,
          })
        );

        // Fetch user FCM token
        const userDoc = await db.doc(`${BASE_PATH}/users/${memberId}`).get();
        const fcmToken = userDoc.data()?.fcmToken;
        if (fcmToken) {
          tokens.push(fcmToken);
        } else {
          console.warn(`User ${memberId} has no fcmToken assigned.`);
        }
      }

      // Execute in-app notification logs
      await Promise.all(notificationPromises);

      // 3. Send push notifications via FCM
      if (tokens.length > 0) {
        const message: admin.messaging.MulticastMessage = {
          tokens,
          notification: {
            title,
            body,
          },
          android: {
            priority: "high",
            notification: {
              channelId: "fcm_alerts",
              color: "#0A74DA",
            },
          },
          apns: {
            payload: {
              aps: {
                contentAvailable: true,
                interruptionLevel: "time-sensitive",
              },
            },
          },
        };

        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(`${response.successCount} messages sent successfully`);
      }

      return null;
    } catch (error) {
      console.error("Error sending notifications:", error);
      return null;
    }
  });
