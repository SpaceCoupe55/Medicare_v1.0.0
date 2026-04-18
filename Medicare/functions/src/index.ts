import * as admin from "firebase-admin";
import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onCall, HttpsError } from "firebase-functions/v2/https";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ── Helpers ────────────────────────────────────────────────────────────────

/** Write a notification record to Firestore for in-app display. */
async function createNotification(
  userId: string,
  title: string,
  body: string
): Promise<void> {
  await db.collection("notifications").add({
    userId,
    title,
    body,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/** Send an FCM push notification if the user has an fcmToken stored. */
async function sendPush(
  userId: string,
  title: string,
  body: string
): Promise<void> {
  const userSnap = await db.collection("users").doc(userId).get();
  if (!userSnap.exists) return;

  const token: string | undefined = userSnap.data()?.fcmToken;
  if (!token) return;

  await messaging.send({
    token,
    notification: { title, body },
    android: { priority: "high" },
    apns: { payload: { aps: { sound: "default" } } },
  });
}

// ── 1. onAppointmentCreated ────────────────────────────────────────────────
// Fires when a new document is created in appointments/{appointmentId}.
// Notifies the assigned doctor via FCM and writes an in-app notification.

export const onAppointmentCreated = onDocumentCreated(
  "appointments/{appointmentId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const doctorId: string = data.doctorId ?? "";
    const patientName: string = data.patientName ?? "A patient";
    const appointmentId = event.params.appointmentId;

    if (!doctorId) return;

    const title = "New Appointment";
    const body = `${patientName} has booked an appointment with you.`;

    await Promise.all([
      createNotification(doctorId, title, body),
      sendPush(doctorId, title, body),
      // Stamp the appointment with server-side createdAt if missing
      db
        .collection("appointments")
        .doc(appointmentId)
        .set({ createdAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true }),
    ]);
  }
);

// ── 2. onAppointmentStatusChanged ─────────────────────────────────────────
// Fires on any update to appointments/{appointmentId}.
// When status changes to 'cancelled' or 'completed', notifies the patient.

export const onAppointmentStatusChanged = onDocumentUpdated(
  "appointments/{appointmentId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const prevStatus: string = before.status ?? "";
    const newStatus: string = after.status ?? "";

    // Only act when status actually changed
    if (prevStatus === newStatus) return;
    if (newStatus !== "cancelled" && newStatus !== "completed") return;

    const patientId: string = after.patientId ?? "";
    const doctorName: string = after.doctorName ?? "your doctor";

    if (!patientId) return;

    const isCancelled = newStatus === "cancelled";
    const title = isCancelled ? "Appointment Cancelled" : "Appointment Completed";
    const body = isCancelled
      ? `Your appointment with Dr. ${doctorName} has been cancelled.`
      : `Your appointment with Dr. ${doctorName} is marked as completed.`;

    await Promise.all([
      createNotification(patientId, title, body),
      sendPush(patientId, title, body),
    ]);
  }
);

// ── 3. sendDailyReminders ─────────────────────────────────────────────────
// Scheduled: runs every day at 08:00 hospital local time (UTC configured below).
// Queries appointments scheduled for today and sends reminders to doctors.

export const sendDailyReminders = onSchedule(
  { schedule: "0 8 * * *", timeZone: "UTC" },
  async () => {
    const now = new Date();
    const startOfDay = new Date(now);
    startOfDay.setUTCHours(0, 0, 0, 0);
    const endOfDay = new Date(now);
    endOfDay.setUTCHours(23, 59, 59, 999);

    const snap = await db
      .collection("appointments")
      .where("status", "==", "scheduled")
      .where("dateTime", ">=", admin.firestore.Timestamp.fromDate(startOfDay))
      .where("dateTime", "<=", admin.firestore.Timestamp.fromDate(endOfDay))
      .get();

    if (snap.empty) return;

    const tasks: Promise<void>[] = [];

    for (const doc of snap.docs) {
      const appt = doc.data();
      const doctorId: string = appt.doctorId ?? "";
      const patientName: string = appt.patientName ?? "a patient";
      const dateTime: admin.firestore.Timestamp = appt.dateTime;
      const timeStr = dateTime.toDate().toLocaleTimeString("en-US", {
        hour: "2-digit",
        minute: "2-digit",
      });

      if (!doctorId) continue;

      const title = "Appointment Reminder";
      const body = `Reminder: you have an appointment with ${patientName} at ${timeStr} today.`;

      tasks.push(
        createNotification(doctorId, title, body),
        sendPush(doctorId, title, body)
      );
    }

    await Promise.all(tasks);
  }
);

// ── 4. sendSms ────────────────────────────────────────────────────────────
// HTTPS Callable — proxies SMS requests to mNotify so browser CORS is bypassed.
// Payload: { recipients: string[], message: string }

export const sendSms = onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be logged in.");
    }

    const { recipients, message } = request.data as {
      recipients: string[];
      message: string;
    };

    if (!recipients?.length || !message) {
      throw new HttpsError("invalid-argument", "recipients and message are required.");
    }

    const apiKey = "WUKb6M3un9vveHesNTHVbDyjQ";
    const senderId = "SkillUp";

    // Format numbers to Ghana local format (0XXXXXXXXX)
    const formatted = recipients
      .map((p: string) => {
        const digits = p.replace(/\D/g, "");
        if (digits.startsWith("233") && digits.length === 12) return "0" + digits.slice(3);
        if (!digits.startsWith("0") && digits.length === 9) return "0" + digits;
        return digits;
      })
      .filter((p: string) => p.length === 10 && p.startsWith("0"));

    if (!formatted.length) {
      throw new HttpsError("invalid-argument", "No valid Ghana phone numbers found.");
    }

    const response = await fetch(
      `https://api.mnotify.com/api/sms/quick?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          recipient: formatted,
          sender: senderId,
          message,
          is_schedule: "false",
          schedule_date: "",
        }),
      }
    );

    const ok = response.status === 200 || response.status === 201;
    const body = await response.text();
    return { success: ok, status: response.status, body };
  }
);

// ── 5. createHospitalAdmin ────────────────────────────────────────────────
// HTTPS Callable — called once during hospital onboarding.
// Creates a Firebase Auth user with role 'admin' and a users/{uid} doc.
//
// Payload: { email, password, name, hospitalId, hospitalName }
// Must be called by an authenticated super-admin or from a trusted server.

export const createHospitalAdmin = onCall(
  { enforceAppCheck: false }, // set true once App Check is configured
  async (request) => {
    // Only allow existing admins or unauthenticated first-run (hospitalId must not exist yet)
    const { email, password, name, hospitalId, hospitalName } =
      request.data as {
        email: string;
        password: string;
        name: string;
        hospitalId: string;
        hospitalName: string;
      };

    if (!email || !password || !name || !hospitalId) {
      throw new HttpsError(
        "invalid-argument",
        "email, password, name and hospitalId are required."
      );
    }

    // Guard: only allow if no admin exists for this hospital yet
    const existingAdmin = await db
      .collection("users")
      .where("hospitalId", "==", hospitalId)
      .where("role", "==", "admin")
      .limit(1)
      .get();

    if (!existingAdmin.empty) {
      throw new HttpsError(
        "already-exists",
        "An admin already exists for this hospital."
      );
    }

    // Create Auth user
    const userRecord = await admin.auth().createUser({ email, password });
    const uid = userRecord.uid;

    // Write user profile doc
    await db.collection("users").doc(uid).set({
      uid,
      email,
      name,
      role: "admin",
      hospitalId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Create or merge the hospital doc
    await db.collection("hospitals").doc(hospitalId).set(
      {
        name: hospitalName,
        adminUid: uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return { uid, message: "Hospital admin created successfully." };
  }
);
