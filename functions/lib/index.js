"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onMeasurementCreated = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
const db = admin.firestore();
const BASE_PATH = "artifacts/pondstat-app-v1/public/data";
/**
 * Triggered when a new measurement is recorded.
 * If an 'alert' payload is present, it sends push notifications to all pond members
 * and logs the notification in their in-app inbox.
 */
exports.onMeasurementCreated = functions.firestore
    .document(`${BASE_PATH}/measurements/{measurementId}`)
    .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    if (!data || !data.alert) {
        return null;
    }
    const { pondId, alert } = data;
    const { title, body } = alert;
    try {
        // 1. Get pond members
        const pondDoc = await db.doc(`${BASE_PATH}/ponds/${pondId}`).get();
        if (!pondDoc.exists) {
            console.error(`Pond ${pondId} not found`);
            return null;
        }
        const memberIds = pondDoc.data()?.memberIds || [];
        if (memberIds.length === 0) {
            return null;
        }
        // 2. Fetch FCM tokens and write to in-app inbox for each member
        const tokens = [];
        const notificationPromises = [];
        for (const memberId of memberIds) {
            // Write to in-app notifications subcollection
            const notificationRef = db
                .collection(`${BASE_PATH}/users/${memberId}/notifications`)
                .doc();
            notificationPromises.push(notificationRef.set({
                title,
                body,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                type: "alert",
                pondId,
                measurementId: context.params.measurementId,
            }));
            // Fetch user FCM token
            const userDoc = await db.doc(`${BASE_PATH}/users/${memberId}`).get();
            const fcmToken = userDoc.data()?.fcmToken;
            if (fcmToken) {
                tokens.push(fcmToken);
            }
            else {
                console.warn(`User ${memberId} has no fcmToken assigned.`);
            }
        }
        // Execute in-app notification logs
        await Promise.all(notificationPromises);
        // 3. Send push notifications via FCM
        if (tokens.length > 0) {
            const message = {
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
    }
    catch (error) {
        console.error("Error sending notifications:", error);
        return null;
    }
});
//# sourceMappingURL=index.js.map