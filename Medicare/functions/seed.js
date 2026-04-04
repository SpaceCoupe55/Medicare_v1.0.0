/**
 * Medicare Demo Data Seeder
 * ─────────────────────────────────────────────────────────────────────────────
 * Seeds one hospital, 5 users (auth + Firestore), 5 doctors, 12 patients,
 * 24 appointments (spread across the year), 8 pharmacy items, and
 * a handful of notifications.
 *
 * USAGE
 *   cd functions
 *   node seed.js
 *
 * CREDENTIALS — pick one:
 *   Option A (recommended): download a service account key from
 *     Firebase Console → Project Settings → Service Accounts →
 *     "Generate new private key" → save as functions/serviceAccount.json
 *
 *   Option B: run `gcloud auth application-default login` first,
 *     then delete the serviceAccount lines below and use
 *     admin.initializeApp({ projectId: 'medicare-admin-b7266' })
 *
 * The script is IDEMPOTENT — re-running it skips already-existing records.
 */

'use strict';

const admin = require('firebase-admin');
const path  = require('path');
const fs    = require('fs');

// ── Credentials ───────────────────────────────────────────────────────────────
const saPath = path.join(__dirname, 'serviceAccount.json');
if (!fs.existsSync(saPath)) {
  console.error(
    '\n❌  serviceAccount.json not found in functions/.\n' +
    '   Download it from Firebase Console → Project Settings → Service Accounts.\n'
  );
  process.exit(1);
}
admin.initializeApp({
  credential: admin.credential.cert(require(saPath)),
  projectId:  'medicare-admin-b7266',
});

const db   = admin.firestore();
const auth = admin.auth();
const FieldValue = admin.firestore.FieldValue;
const Timestamp  = admin.firestore.Timestamp;

const HOSPITAL_ID = 'demo-hospital';

// ── Helpers ───────────────────────────────────────────────────────────────────

function daysAgo(n) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  d.setHours(9 + Math.floor(Math.random() * 8), 0, 0, 0);
  return d;
}

function daysFromNow(n) {
  const d = new Date();
  d.setDate(d.getDate() + n);
  d.setHours(9 + Math.floor(Math.random() * 8), 0, 0, 0);
  return d;
}

function monthsAgo(m, day) {
  const d = new Date();
  d.setMonth(d.getMonth() - m);
  if (day) d.setDate(day);
  d.setHours(10, 0, 0, 0);
  return d;
}

/** Create or get an existing Firebase Auth user. Returns the uid. */
async function upsertAuthUser(email, password, displayName) {
  try {
    const existing = await auth.getUserByEmail(email);
    console.log(`  ↩  user exists: ${email} (${existing.uid})`);
    return existing.uid;
  } catch {
    const user = await auth.createUser({ email, password, displayName });
    console.log(`  ✅ created auth user: ${email} (${user.uid})`);
    return user.uid;
  }
}

/** Write a Firestore doc only if it doesn't already exist. */
async function upsertDoc(ref, data) {
  const snap = await ref.get();
  if (snap.exists) {
    return false; // already seeded
  }
  await ref.set(data);
  return true;
}

// ── 1. Hospital ───────────────────────────────────────────────────────────────

async function seedHospital() {
  console.log('\n── Hospital');
  const ref = db.collection('hospitals').doc(HOSPITAL_ID);
  const created = await upsertDoc(ref, {
    name:      'City General Hospital',
    contact:   '+1 (555) 123-4567',
    address:   '100 Health Blvd, San Francisco, CA 94105',
    createdAt: FieldValue.serverTimestamp(),
  });
  console.log(created ? '  ✅ hospital created' : '  ↩  hospital exists');
}

// ── 2. Users (Auth + Firestore) ───────────────────────────────────────────────

const USERS = [
  { email: 'admin@medicare.demo',     password: 'Demo@1234', name: 'Sarah Mitchell',  role: 'admin'         },
  { email: 'dr.chen@medicare.demo',   password: 'Demo@1234', name: 'James Chen',      role: 'doctor'        },
  { email: 'dr.patel@medicare.demo',  password: 'Demo@1234', name: 'Priya Patel',     role: 'doctor'        },
  { email: 'nurse.mary@medicare.demo',password: 'Demo@1234', name: 'Mary Johnson',    role: 'nurse'         },
  { email: 'reception@medicare.demo', password: 'Demo@1234', name: 'Tom Richards',    role: 'receptionist'  },
];

/** Returns a map of email → uid after seeding all auth users. */
async function seedUsers() {
  console.log('\n── Users');
  const uidMap = {};
  for (const u of USERS) {
    const uid = await upsertAuthUser(u.email, u.password, u.name);
    uidMap[u.email] = uid;
    const ref = db.collection('users').doc(uid);
    const created = await upsertDoc(ref, {
      uid,
      email:      u.email,
      name:       u.name,
      role:       u.role,
      hospitalId: HOSPITAL_ID,
      createdAt:  FieldValue.serverTimestamp(),
    });
    if (created) console.log(`  ✅ Firestore profile: ${u.name} (${u.role})`);

    // Update the hospital doc with adminUid once we know it.
    if (u.role === 'admin') {
      await db.collection('hospitals').doc(HOSPITAL_ID).update({ adminUid: uid });
    }
  }
  return uidMap;
}

// ── 3. Doctors ────────────────────────────────────────────────────────────────

const DOCTORS_TEMPLATE = [
  { name: 'James Chen',      specialization: 'Cardiology',      degree: 'MD, FACC',  email: 'dr.chen@medicare.demo',  phone: '+1 (555) 201-0001' },
  { name: 'Priya Patel',     specialization: 'Neurology',       degree: 'MD, FAAN',  email: 'dr.patel@medicare.demo', phone: '+1 (555) 201-0002' },
  { name: 'Robert Kim',      specialization: 'Orthopedics',     degree: 'MD, FAAOS', email: 'dr.kim@medicare.demo',   phone: '+1 (555) 201-0003' },
  { name: 'Emily Walsh',     specialization: 'Pediatrics',      degree: 'MD, FAAP',  email: 'dr.walsh@medicare.demo', phone: '+1 (555) 201-0004' },
  { name: 'David Okonkwo',   specialization: 'General Surgery', degree: 'MD, FACS',  email: 'dr.okonkwo@medicare.demo', phone: '+1 (555) 201-0005' },
];

/**
 * Returns a map of doctor name → Firestore doc ID.
 * Also sets doctorId on each doc to the auth UID for the two doctors who have
 * auth accounts (Chen, Patel).
 */
async function seedDoctors(uidMap) {
  console.log('\n── Doctors');
  const docIdMap = {};
  for (let i = 0; i < DOCTORS_TEMPLATE.length; i++) {
    const d = DOCTORS_TEMPLATE[i];
    // Check if already seeded (by email uniqueness)
    const existing = await db.collection('doctors')
      .where('email', '==', d.email)
      .where('hospitalId', '==', HOSPITAL_ID)
      .limit(1).get();

    if (!existing.empty) {
      docIdMap[d.name] = existing.docs[0].id;
      console.log(`  ↩  doctor exists: ${d.name}`);
      continue;
    }

    const uid = uidMap[d.email] ?? '';
    const ref = db.collection('doctors').doc();
    await ref.set({
      name:           d.name,
      specialization: d.specialization,
      degree:         d.degree,
      email:          d.email,
      phone:          d.phone,
      hospitalId:     HOSPITAL_ID,
      doctorId:       uid,
      joiningDate:    Timestamp.fromDate(monthsAgo(6 + i * 2, 1)),
      createdAt:      Timestamp.fromDate(monthsAgo(6 + i * 2, 1)),
    });
    docIdMap[d.name] = ref.id;
    console.log(`  ✅ ${d.name} — ${d.specialization}`);
  }
  return docIdMap;
}

// ── 4. Patients ───────────────────────────────────────────────────────────────

const PATIENTS_TEMPLATE = [
  { name: 'Alice Monroe',    gender: 'female', dob: '1985-03-12', blood: 'A+',  phone: '+1 (555) 301-0001', address: '12 Oak St, San Francisco, CA', history: 'Hypertension',          months: 3, day: 5  },
  { name: 'Brian Torres',    gender: 'male',   dob: '1972-07-28', blood: 'O-',  phone: '+1 (555) 301-0002', address: '45 Maple Ave, Oakland, CA',    history: 'Type 2 Diabetes',       months: 3, day: 14 },
  { name: 'Catherine Lee',   gender: 'female', dob: '1990-11-03', blood: 'B+',  phone: '+1 (555) 301-0003', address: '78 Pine Rd, Berkeley, CA',     history: 'Asthma',                months: 2, day: 7  },
  { name: 'Daniel Smith',    gender: 'male',   dob: '1965-05-19', blood: 'AB+', phone: '+1 (555) 301-0004', address: '23 Elm St, San Jose, CA',      history: 'Coronary artery disease',months: 2, day: 20 },
  { name: 'Eva Martinez',    gender: 'female', dob: '2001-09-30', blood: 'A-',  phone: '+1 (555) 301-0005', address: '56 Cedar Ln, Palo Alto, CA',   history: 'Migraine',              months: 2, day: 25 },
  { name: 'Frank Johnson',   gender: 'male',   dob: '1958-12-15', blood: 'O+',  phone: '+1 (555) 301-0006', address: '89 Birch Blvd, Fremont, CA',   history: 'Osteoarthritis',        months: 1, day: 3  },
  { name: 'Grace Kim',       gender: 'female', dob: '1995-04-22', blood: 'B-',  phone: '+1 (555) 301-0007', address: '34 Walnut Dr, Sunnyvale, CA',  history: 'Anxiety disorder',      months: 1, day: 11 },
  { name: 'Henry Park',      gender: 'male',   dob: '1980-08-08', blood: 'A+',  phone: '+1 (555) 301-0008', address: '67 Ash Ave, Santa Clara, CA',  history: 'Lumbar disc herniation',months: 1, day: 18 },
  { name: 'Irene Thompson',  gender: 'female', dob: '2010-02-14', blood: 'O+',  phone: '+1 (555) 301-0009', address: '90 Spruce St, Hayward, CA',    history: 'Recurrent tonsillitis', months: 0, day: 5  },
  { name: 'Jacob Wilson',    gender: 'male',   dob: '1948-06-01', blood: 'AB-', phone: '+1 (555) 301-0010', address: '11 Hickory Ln, Richmond, CA',  history: 'Chronic kidney disease',months: 0, day: 12 },
  { name: 'Karen Adams',     gender: 'female', dob: '1978-10-25', blood: 'A+',  phone: '+1 (555) 301-0011', address: '44 Sycamore Rd, Concord, CA',  history: 'Hypothyroidism',        months: 0, day: 18 },
  { name: 'Liam Brown',      gender: 'male',   dob: '2005-01-17', blood: 'B+',  phone: '+1 (555) 301-0012', address: '77 Poplar Ave, Walnut Creek, CA', history: 'Seasonal allergies',  months: 0, day: 25 },
];

async function seedPatients(doctorIds) {
  console.log('\n── Patients');
  const patientIdMap = {};
  const docNames = Object.keys(doctorIds);

  for (let i = 0; i < PATIENTS_TEMPLATE.length; i++) {
    const p = PATIENTS_TEMPLATE[i];
    const existing = await db.collection('patients')
      .where('phone', '==', p.phone)
      .where('hospitalId', '==', HOSPITAL_ID)
      .limit(1).get();

    if (!existing.empty) {
      patientIdMap[p.name] = existing.docs[0].id;
      console.log(`  ↩  patient exists: ${p.name}`);
      continue;
    }

    const dob = new Date(p.dob);
    const now = new Date();
    const age = now.getFullYear() - dob.getFullYear() -
      ((now.getMonth() < dob.getMonth() ||
        (now.getMonth() === dob.getMonth() && now.getDate() < dob.getDate())) ? 1 : 0);

    const assignedDoctor = docNames[i % docNames.length];
    const createdAt = monthsAgo(p.months, p.day);

    const ref = db.collection('patients').doc();
    await ref.set({
      name:             p.name,
      gender:           p.gender,
      phone:            p.phone,
      bloodType:        p.blood,
      address:          p.address,
      status:           'active',
      age,
      dob:              Timestamp.fromDate(dob),
      email:            p.name.toLowerCase().replace(/\s+/g, '.') + '@example.com',
      medicalHistory:   p.history,
      assignedDoctorId: doctorIds[assignedDoctor] ?? '',
      hospitalId:       HOSPITAL_ID,
      createdAt:        Timestamp.fromDate(createdAt),
      updatedAt:        Timestamp.fromDate(createdAt),
    });
    patientIdMap[p.name] = ref.id;
    console.log(`  ✅ ${p.name} — ${p.blood} — ${p.history}`);
  }
  return patientIdMap;
}

// ── 5. Appointments ───────────────────────────────────────────────────────────

async function seedAppointments(uidMap, doctorIds, patientIds) {
  console.log('\n── Appointments');

  // Check if already seeded
  const existing = await db.collection('appointments')
    .where('hospitalId', '==', HOSPITAL_ID).limit(1).get();
  if (!existing.empty) {
    console.log('  ↩  appointments already seeded, skipping');
    return;
  }

  const doctorAuthId = {
    'James Chen':  uidMap['dr.chen@medicare.demo']  ?? '',
    'Priya Patel': uidMap['dr.patel@medicare.demo'] ?? '',
    'Robert Kim':  '',
    'Emily Walsh': '',
    'David Okonkwo': '',
  };

  const patientNames = Object.keys(patientIds);

  const APPTS = [
    // ── Jan (3 months ago) ──────────────────────────────────────────────────
    { patient: 0, doctor: 'James Chen',    daysBack: 92, status: 'completed', notes: 'Cardiac follow-up. ECG normal.' },
    { patient: 1, doctor: 'Priya Patel',   daysBack: 88, status: 'completed', notes: 'Neurological assessment. No new findings.' },
    { patient: 2, doctor: 'Emily Walsh',   daysBack: 85, status: 'completed', notes: 'Routine pediatric check.' },
    { patient: 3, doctor: 'James Chen',    daysBack: 82, status: 'completed', notes: 'Post-procedure review.' },

    // ── Feb (2 months ago) ──────────────────────────────────────────────────
    { patient: 4, doctor: 'Priya Patel',   daysBack: 58, status: 'completed', notes: 'Migraine management plan reviewed.' },
    { patient: 5, doctor: 'Robert Kim',    daysBack: 55, status: 'completed', notes: 'Knee X-ray reviewed. Physiotherapy recommended.' },
    { patient: 6, doctor: 'Priya Patel',   daysBack: 52, status: 'completed', notes: 'Anxiety follow-up. Medication adjusted.' },
    { patient: 7, doctor: 'Robert Kim',    daysBack: 48, status: 'cancelled',  notes: 'Patient rescheduled.' },
    { patient: 8, doctor: 'Emily Walsh',   daysBack: 45, status: 'completed', notes: 'Tonsil assessment. Referred for ENT.' },

    // ── Mar (last month) ────────────────────────────────────────────────────
    { patient: 9,  doctor: 'David Okonkwo',daysBack: 28, status: 'completed', notes: 'Pre-surgery consultation.' },
    { patient: 10, doctor: 'James Chen',   daysBack: 25, status: 'completed', notes: 'Thyroid cardiac monitoring.' },
    { patient: 11, doctor: 'Emily Walsh',  daysBack: 22, status: 'completed', notes: 'Allergy panel results reviewed.' },
    { patient: 0,  doctor: 'James Chen',   daysBack: 18, status: 'completed', notes: 'Blood pressure well-controlled.' },
    { patient: 1,  doctor: 'Priya Patel',  daysBack: 15, status: 'cancelled',  notes: 'Doctor unavailable.' },
    { patient: 3,  doctor: 'David Okonkwo',daysBack: 12, status: 'completed', notes: 'Post-op review. Healing well.' },

    // ── This week ────────────────────────────────────────────────────────────
    { patient: 2,  doctor: 'Priya Patel',  daysBack: 5, status: 'completed', notes: 'Follow-up: asthma control good.' },
    { patient: 5,  doctor: 'Robert Kim',   daysBack: 3, status: 'completed', notes: 'Six-week ortho review.' },
    { patient: 7,  doctor: 'Robert Kim',   daysBack: 2, status: 'completed', notes: 'MRI results discussed.' },

    // ── Today ────────────────────────────────────────────────────────────────
    { patient: 4,  doctor: 'James Chen',   daysBack: 0, hour: 9,  status: 'scheduled', notes: 'Routine cardiology check.' },
    { patient: 8,  doctor: 'Emily Walsh',  daysBack: 0, hour: 11, status: 'scheduled', notes: 'Post-ENT referral follow-up.' },
    { patient: 9,  doctor: 'David Okonkwo',daysBack: 0, hour: 14, status: 'scheduled', notes: 'Surgical planning discussion.' },

    // ── Upcoming ─────────────────────────────────────────────────────────────
    { patient: 6,  doctor: 'Priya Patel',  daysForward: 2,  hour: 10, status: 'scheduled', notes: 'Monthly anxiety review.' },
    { patient: 10, doctor: 'James Chen',   daysForward: 4,  hour: 9,  status: 'scheduled', notes: 'Thyroid medication adjustment.' },
    { patient: 11, doctor: 'Emily Walsh',  daysForward: 7,  hour: 13, status: 'scheduled', notes: 'Allergy immunotherapy session.' },
  ];

  const batch = db.batch();
  let count = 0;

  for (const a of APPTS) {
    const pName  = patientNames[a.patient] ?? patientNames[0];
    const pId    = patientIds[pName] ?? '';
    const dDocId = doctorIds[a.doctor]   ?? '';
    const dUid   = doctorAuthId[a.doctor] ?? '';

    let dt;
    if (a.daysForward !== undefined) {
      dt = daysFromNow(a.daysForward);
    } else {
      dt = daysAgo(a.daysBack);
    }
    if (a.hour !== undefined) dt.setHours(a.hour, 0, 0, 0);

    // createdAt is same as dateTime for past; booking time for future
    const createdAt = a.daysBack !== undefined && a.daysBack === 0
      ? new Date(dt.getTime() - 24 * 60 * 60 * 1000)  // booked yesterday
      : (a.daysForward !== undefined
          ? new Date()   // booked today
          : new Date(dt.getTime() - 2 * 24 * 60 * 60 * 1000));  // booked 2d before

    const ref = db.collection('appointments').doc();
    batch.set(ref, {
      patientId:    pId,
      patientName:  pName,
      patientPhone: PATIENTS_TEMPLATE[a.patient]?.phone ?? '',
      patientEmail: pName.toLowerCase().replace(/\s+/g, '.') + '@example.com',
      doctorId:     dUid,
      doctorDocId:  dDocId,
      doctorName:   a.doctor,
      gender:       PATIENTS_TEMPLATE[a.patient]?.gender ?? 'male',
      dateTime:     Timestamp.fromDate(dt),
      status:       a.status,
      notes:        a.notes,
      hospitalId:   HOSPITAL_ID,
      createdAt:    Timestamp.fromDate(createdAt),
    });
    count++;
  }

  await batch.commit();
  console.log(`  ✅ ${count} appointments created`);
}

// ── 6. Pharmacy ───────────────────────────────────────────────────────────────

const PHARMACY_ITEMS = [
  { name: 'Amoxicillin 500mg',       category: 'Antibiotics',      price: 12.99,  rate: 4.5, stock: 240 },
  { name: 'Metformin 850mg',          category: 'Antidiabetics',    price: 8.49,   rate: 4.7, stock: 185 },
  { name: 'Atorvastatin 20mg',        category: 'Cardiovascular',   price: 15.75,  rate: 4.6, stock: 320 },
  { name: 'Omeprazole 20mg',          category: 'Gastro',           price: 9.99,   rate: 4.3, stock: 410 },
  { name: 'Salbutamol Inhaler 100mcg',category: 'Respiratory',      price: 22.50,  rate: 4.8, stock: 95  },
  { name: 'Paracetamol 500mg',        category: 'Analgesics',       price: 4.25,   rate: 4.9, stock: 620 },
  { name: 'Lisinopril 10mg',          category: 'Cardiovascular',   price: 11.30,  rate: 4.4, stock: 275 },
  { name: 'Cetirizine 10mg',          category: 'Antihistamines',   price: 6.80,   rate: 4.6, stock: 350 },
];

async function seedPharmacy() {
  console.log('\n── Pharmacy');
  for (const item of PHARMACY_ITEMS) {
    const existing = await db.collection('pharmacy')
      .where('name', '==', item.name)
      .where('hospitalId', '==', HOSPITAL_ID)
      .limit(1).get();

    if (!existing.empty) {
      console.log(`  ↩  item exists: ${item.name}`);
      continue;
    }

    const ref = db.collection('pharmacy').doc();
    await ref.set({
      name:       item.name,
      category:   item.category,
      price:      item.price,
      rate:       item.rate,
      stock:      item.stock,
      imageUrl:   '',           // no image URL for demo; UI falls back gracefully
      hospitalId: HOSPITAL_ID,
    });
    console.log(`  ✅ ${item.name}`);
  }
}

// ── 7. Notifications ──────────────────────────────────────────────────────────

async function seedNotifications(uidMap) {
  console.log('\n── Notifications');

  const chenUid  = uidMap['dr.chen@medicare.demo'];
  const patelUid = uidMap['dr.patel@medicare.demo'];

  const existing = await db.collection('notifications')
    .where('hospitalId', '==', HOSPITAL_ID).limit(1).get();
  if (!existing.empty) {
    console.log('  ↩  notifications already seeded, skipping');
    return;
  }

  const NOTIFS = [
    { userId: chenUid,  title: 'New Appointment',       body: 'Alice Monroe has booked a cardiology appointment for today at 9:00 AM.',   daysBack: 1, read: false },
    { userId: chenUid,  title: 'Appointment Reminder',  body: 'Reminder: you have an appointment with Daniel Smith today at 2:00 PM.',     daysBack: 0, read: false },
    { userId: patelUid, title: 'New Appointment',       body: 'Eva Martinez has booked a neurology appointment for today at 11:00 AM.',    daysBack: 1, read: false },
    { userId: patelUid, title: 'Appointment Completed', body: 'Your appointment with Grace Kim is marked as completed.',                   daysBack: 2, read: true  },
    { userId: chenUid,  title: 'Appointment Cancelled', body: 'The appointment with Brian Torres has been cancelled by the patient.',      daysBack: 3, read: true  },
  ];

  const batch = db.batch();
  for (const n of NOTIFS) {
    const ref = db.collection('notifications').doc();
    batch.set(ref, {
      userId:     n.userId,
      title:      n.title,
      body:       n.body,
      read:       n.read,
      hospitalId: HOSPITAL_ID,
      createdAt:  Timestamp.fromDate(daysAgo(n.daysBack)),
    });
  }
  await batch.commit();
  console.log(`  ✅ ${NOTIFS.length} notifications created`);
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  console.log('🌱  Medicare demo data seeder');
  console.log(`    Project  : medicare-admin-b7266`);
  console.log(`    Hospital : ${HOSPITAL_ID}\n`);

  try {
    await seedHospital();
    const uidMap      = await seedUsers();
    const doctorIds   = await seedDoctors(uidMap);
    const patientIds  = await seedPatients(doctorIds);
    await seedAppointments(uidMap, doctorIds, patientIds);
    await seedPharmacy();
    await seedNotifications(uidMap);

    console.log('\n✅  Seeding complete!\n');
    console.log('Demo credentials:');
    console.log('  Admin       : admin@medicare.demo      / Demo@1234');
    console.log('  Doctor      : dr.chen@medicare.demo    / Demo@1234');
    console.log('  Doctor      : dr.patel@medicare.demo   / Demo@1234');
    console.log('  Nurse       : nurse.mary@medicare.demo / Demo@1234');
    console.log('  Receptionist: reception@medicare.demo  / Demo@1234\n');
  } catch (err) {
    console.error('\n❌  Seeder failed:', err.message);
    process.exit(1);
  } finally {
    process.exit(0);
  }
}

main();
