'use strict';
// Refreshes "scheduled" appointment dateTimes to be relative to TODAY,
// so demo data stays relevant regardless of when the seed was first run.

const admin = require('firebase-admin');
const path  = require('path');

admin.initializeApp({
  credential: admin.credential.cert(require(path.join(__dirname, 'serviceAccount.json'))),
  projectId:  'medicare-admin-b7266',
});

const db = admin.firestore();
const Timestamp = admin.firestore.Timestamp;
const HOSPITAL_ID = 'demo-hospital';

function todayAt(hour) {
  const d = new Date();
  d.setHours(hour, 0, 0, 0);
  return d;
}
function daysFromNow(n, hour = 9) {
  const d = new Date();
  d.setDate(d.getDate() + n);
  d.setHours(hour, 0, 0, 0);
  return d;
}

async function main() {
  const snap = await db.collection('appointments')
    .where('hospitalId', '==', HOSPITAL_ID)
    .where('status', '==', 'scheduled')
    .get();

  console.log(`Found ${snap.size} scheduled appointments.`);

  // Sort by current dateTime so we can assign fresh relative dates in order
  const docs = snap.docs
    .map(d => ({ ref: d.ref, data: d.data() }))
    .sort((a, b) => a.data.dateTime.seconds - b.data.dateTime.seconds);

  // Assign fresh dates: spread across today and next 10 days by doctor
  const doctorCounters = {};
  const batch = db.batch();

  for (const { ref, data } of docs) {
    const dId = data.doctorId;
    if (!doctorCounters[dId]) doctorCounters[dId] = 0;
    const offset = doctorCounters[dId];
    doctorCounters[dId]++;

    let newDate;
    if (offset === 0) {
      newDate = todayAt(9 + Math.floor(Math.random() * 6)); // today
    } else {
      newDate = daysFromNow(offset * 2, 9 + Math.floor(Math.random() * 6));
    }

    batch.update(ref, { dateTime: Timestamp.fromDate(newDate) });
    console.log(`  ${data.doctorName} / ${data.patientName}: → ${newDate.toISOString()}`);
  }

  await batch.commit();
  console.log('\n✅ Appointment dates refreshed.');
  process.exit(0);
}

main().catch(err => {
  console.error('❌', err.message);
  process.exit(1);
});
