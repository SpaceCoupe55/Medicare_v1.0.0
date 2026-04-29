'use strict';
// Patches existing appointments: replaces doctorId (Auth UID) with
// the corresponding Firestore doctors/{id} document ID.

const admin = require('firebase-admin');
const path  = require('path');

admin.initializeApp({
  credential: admin.credential.cert(require(path.join(__dirname, 'serviceAccount.json'))),
  projectId:  'medicare-admin-b7266',
});

const db = admin.firestore();
const HOSPITAL_ID = 'demo-hospital';

async function main() {
  // 1. Build email → Firestore doc ID map from doctors collection
  const doctorsSnap = await db.collection('doctors')
    .where('hospitalId', '==', HOSPITAL_ID).get();
  const emailToDocId = {};
  doctorsSnap.forEach(doc => {
    const email = doc.data().email;
    if (email) emailToDocId[email] = doc.id;
  });
  console.log('Doctor email → docId map:', emailToDocId);

  // 2. Build Auth UID → Firestore doc ID map via users collection
  const usersSnap = await db.collection('users')
    .where('hospitalId', '==', HOSPITAL_ID).get();
  const uidToDocId = {};
  usersSnap.forEach(doc => {
    const email = doc.data().email;
    const docId = emailToDocId[email];
    if (docId) uidToDocId[doc.id] = docId;
  });
  console.log('Auth UID → docId map:', uidToDocId);

  // 3. Load all appointments for this hospital
  const apptSnap = await db.collection('appointments')
    .where('hospitalId', '==', HOSPITAL_ID).get();

  console.log(`\nPatching ${apptSnap.size} appointments...`);

  const batch = db.batch();
  let patched = 0;

  apptSnap.forEach(doc => {
    const data = doc.data();
    const currentDoctorId = data.doctorId;
    // If doctorId is an Auth UID (exists in our map), replace it
    const correctDocId = uidToDocId[currentDoctorId];
    if (correctDocId && correctDocId !== currentDoctorId) {
      batch.update(doc.ref, {
        doctorId:     correctDocId,
        doctorAuthId: currentDoctorId,
      });
      patched++;
      console.log(`  ${doc.id}: ${currentDoctorId} → ${correctDocId}`);
    }
  });

  if (patched === 0) {
    console.log('  Nothing to patch — all appointments already use doc IDs.');
    process.exit(0);
  }

  await batch.commit();
  console.log(`\n✅ Patched ${patched} appointments.`);
  process.exit(0);
}

main().catch(err => {
  console.error('❌', err.message);
  process.exit(1);
});
