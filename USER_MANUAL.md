# Medicare — User Manual

A hospital management system for managing patients, appointments, prescriptions,
pharmacy inventory, billing, and staff rosters.

This manual covers **v1.0.0**. Screens, fields, and workflows described below
reflect what is currently in the application.

---

## 1. Getting Started

### 1.1 Logging in

1. Open the Medicare site in your browser.
2. Enter your **email** and **password** on the login screen.
3. Click **Sign In**.

On successful login you are taken to the **Dashboard**. If your account has no
matching profile (for doctors without a linked doctor record), you will be
unable to access role-restricted pages — contact an admin.

### 1.2 Forgot password

1. From the login screen, click **Forgot password?**
2. Enter the email on your account.
3. Open the password reset email and follow the link to set a new password.

### 1.3 Registering a new account

The **Register Account** screen is used by admins to onboard new staff. It
creates a Firebase Auth user and the matching `users/{uid}` Firestore record
with a role, hospitalId, and phone number.

> **Note:** Self-service registration is not intended for clinical staff. In a
> production rollout, new accounts should be created by an administrator.

### 1.4 Logging out

Open the user menu in the top-right of the header and click **Log out**.

---

## 2. Roles and what each role can do

Medicare supports four roles. Access is enforced both in the sidebar menu and
by server-side Firestore rules.

| Role | Access |
|---|---|
| **Admin** | Full access to every screen — Patients, Doctors, Appointments, Pharmacy, Prescriptions, Billing, Roster, Reports, Settings |
| **Doctor** | Patients, Doctors (read), Appointments, **Doctor Portal**, Chat |
| **Nurse** | Patients, Doctors (read), Appointments, Chat |
| **Receptionist** | Pharmacy, Prescription Queue, Billing, Chat |

If you navigate to a screen your role is not permitted to access, you are
redirected back to the Dashboard.

---

## 3. Dashboard

The Dashboard is the landing page after login. It shows:

- **Stat cards**: Total Patients, Total Doctors, Today's Appointments, Revenue
  (click any card to jump to the matching list)
- **Charts**: appointment trends and revenue summaries
- **Refresh** button (top-right) to reload counts

---

## 4. Patients

Available to: **admin, doctor, nurse**.

### 4.1 Patient list (`/admin/patient/list`)

- Lists all patients for your hospital.
- Search by name, phone, or ID.
- Click a row to open the patient detail page.
- Click **+ Add Patient** to create a new record.

### 4.2 Add a patient

1. From the patient list, click **+ Add Patient**.
2. Fill in:
   - Name, date of birth, gender, mobile number
   - Allergies, chronic conditions (optional but important)
   - Emergency contact (name, relationship, phone)
3. Click **Save**.

### 4.3 Patient detail

The patient detail screen has four tabs:

- **Overview** — demographics, allergies, chronic conditions, emergency contact
- **Vitals** — time-series of BP, pulse, temperature, weight, etc. Click
  **+ Add Vitals** to record a new set.
- **Records** — medical records (consultations, lab orders, prescriptions)
- **Appointments** — upcoming and past appointments for this patient

From this screen a doctor can also **write a prescription** which is stored on
the record and pushed to the pharmacy prescription queue (see §8).

### 4.4 Edit / delete

Click the pencil icon on a patient row (or **Edit** on the detail page) to
update demographics. Deletion is restricted to admins.

---

## 5. Doctors

Available to: **admin, doctor, nurse** (read). Add/edit restricted to **admin**.

### 5.1 Doctor list (`/admin/doctor/list`)

- Shows all doctors for your hospital: name, specialty, phone.
- Click a row for the detail view.

### 5.2 Add a doctor (admin only)

1. From the doctor list, click **+ Add Doctor**.
2. Enter: name, email, phone, specialty, hospital, bio.
3. If the doctor is also a login user, link their Firebase Auth UID so they
   can log in and see their portal.
4. Click **Save**.

### 5.3 Doctor detail

Shows profile info, schedule, and recent appointments. Admins can edit from
here; doctors can view their own record.

---

## 6. Appointments

Available to: **admin, doctor, nurse**.

### 6.1 Appointment list (`/admin/appointment/list`)

- Columns: date, patient, doctor, status (scheduled / completed / cancelled),
  actions.
- Filter by status.
- **Actions on each row:**
  - **Edit** (pencil) — change date, time, doctor, status
  - **Delete** (trash) — remove (admin)
  - **Bill** (green receipt icon, **completed appointments only**) — opens
    the invoice create screen pre-filled with patient and doctor. See §10.

### 6.2 Book an appointment

1. Click **+ Book Appointment**.
2. Select: patient, doctor, date, time.
3. Add reason / notes.
4. Click **Save**. Patient receives an SMS if SMS is configured.

### 6.3 Scheduling view

Use **Schedule** (`/admin/appointment/schedule`) to see the calendar view of
appointments across doctors.

### 6.4 Status transitions

- New appointments are **scheduled**.
- After the consultation, change status to **completed** from the edit dialog.
- This unlocks the **Bill** button on the appointment list row.

---

## 7. Doctor Portal

Available to: **doctor**.

Route: `/doctor/portal`.

A focused view for the logged-in doctor showing **only their own**:

- Today's appointments
- This week's schedule
- Quick links to each appointment's patient record

Doctors can start a consultation from here and write prescriptions without
going through the full appointment list.

---

## 8. Prescriptions & Pharmacy

### 8.1 Writing a prescription (doctor)

From the **patient detail** page, open the prescription form, add drug items
(name, dose, frequency, duration, quantity), and save. The prescription:

1. Is stored on the patient's medical record.
2. Is pushed to the **Prescription Queue** for pharmacy fulfillment.

### 8.2 Prescription queue (`/admin/pharmacy/prescriptions`)

Available to: **admin, receptionist**.

- Shows all pending prescriptions filtered by hospital.
- Status chips: **pending**, **fulfilled**.
- Click **Fulfill** on a row to jump to the pharmacy checkout pre-loaded with
  the patient and prescription items.

### 8.3 Pharmacy list (`/admin/pharmacy/list`)

Inventory of drugs and supplies. Columns: name, price, stock, expiry, actions.

- **+ Add Item** to add a new drug (admin only for permanent add; receptionist
  can view).
- Click an item for the detail screen with full info.
- **Edit** (admin only) to change price or stock.

### 8.4 Pharmacy cart and checkout

1. From pharmacy list or prescription queue, add items to the cart.
2. Open the **Cart** screen to review quantities and subtotal.
3. Click **Checkout**.
4. Select patient (pre-filled if coming from a prescription).
5. Choose **Cash** or **Mobile Money**. For MoMo, pick network (MTN /
   Vodafone / AirtelTigo) and enter phone + reference.
6. Click **Complete Sale**.

Behind the scenes this writes a `sale` document, decrements stock on each
line item, and (if linked) marks the prescription as fulfilled.

### 8.5 Receipt

After checkout you are taken to the **Receipt** screen. Print or share with
the patient.

---

## 9. Billing & Invoicing

Available to: **admin, receptionist**.

Use Billing for consultation fees, procedures, lab charges, and NHIS claims —
anything beyond over-the-counter pharmacy sales.

### 9.1 Billing list (`/admin/billing/list`)

- Shows all invoices for your hospital, newest first.
- Filter chips: **All**, **Pending**, **Paid**, **Claimed**.
- Columns: invoice #, patient (NHIS badge shown if covered), date, items,
  subtotal, net payable, status, view action.
- Click **+ New Invoice** to create one manually.

### 9.2 Create an invoice (`/admin/billing/create`)

Two ways to get here:

- Manually from the Billing list
- Automatically from the **Bill** button on a completed appointment (patient
  and doctor are pre-filled)

Steps:

1. Confirm or pick the patient.
2. Add **line items**. For each item, enter description, type
   (consultation / procedure / lab / other), unit price, and quantity.
3. Toggle **NHIS applies** if the patient is covered. Set the **coverage
   percentage** (e.g. 0.80 for 80 %). The invoice will calculate the NHIS
   deduction and the net payable.
4. Select a **payment method**: Cash / MoMo / NHIS / Insurance.
   - MoMo requires network + phone + reference.
5. Click either:
   - **Save as Pending** — creates a draft invoice; patient hasn't paid yet.
   - **Save & Mark Paid** — creates the invoice and records payment
     immediately.

### 9.3 Invoice detail (`/admin/billing/detail`)

- Full invoice view with line items, totals, and NHIS claim banner.
- **Actions panel:**
  - **Record Payment** — for pending invoices; choose method and (for MoMo)
    enter network, phone, reference.
  - **Submit NHIS Claim** — for NHIS-covered invoices; sets claim status to
    *submitted*.
  - **Mark Approved / Rejected** — update claim status after NHIS responds.

### 9.4 Invoice statuses

- **draft / pending** — created, not yet paid
- **paid** — payment recorded
- **claimed** — NHIS claim submitted (may still be approved/rejected)

---

## 10. Staff Roster

Available to: **admin**.

Route: `/admin/roster`.

A weekly grid for scheduling staff shifts.

### 10.1 The grid

- Rows: staff members (filter by role with the chips: All / Doctors / Nurses /
  Reception).
- Columns: Mon–Sun with dates for the current week. Today's column is
  highlighted.
- Navigate weeks with the **previous / next** arrows above the grid.

### 10.2 Adding a shift

1. Click an empty cell for the staff member and date you want.
2. In the dialog, pick a **shift type**:
   - **Morning** (06:00–14:00, amber)
   - **Afternoon** (14:00–22:00, blue)
   - **Night** (22:00–06:00, purple)
   - **Custom** (set your own start/end, teal)
3. Optionally add notes.
4. Click **Save**.

### 10.3 Removing a shift

Click the shift chip and confirm delete in the prompt.

### 10.4 Legend

At the bottom of the grid, the colour legend shows what each shift type looks
like.

---

## 11. Chat

Available to: **all authenticated users**.

Internal messaging between staff. Use it for quick coordination — a doctor
asking a pharmacist about stock, reception checking availability with a
nurse, etc.

> **Note:** Chat is for operational coordination. Do not use it to transmit
> confidential patient information that should be in the patient record.

---

## 12. Reports

Available to: **admin**.

Route: `/admin/reports`. Revenue, appointment volumes, pharmacy sales, and
other summary statistics.

---

## 13. Settings

Available to: **admin**.

Route: `/admin/setting`. Hospital profile, SMS templates, default branding,
and other admin-only preferences.

- **SMS templates** — edit the text used for appointment confirmations,
  reminders, and prescription-ready notifications.

---

## 14. Offline support

The app uses Firestore's built-in offline cache.

- If you lose internet mid-session, the app continues to work with the data
  you've already loaded.
- New writes (e.g. recording vitals, creating an invoice) are **queued
  locally** and sync automatically when you're back online.
- You do **not** need to re-enter data after a brief disconnect.

> **Caution:** Do not close your browser tab while offline with unsynced
> writes pending — the queue can be lost. Wait for a green "synced" state
> before closing.

---

## 15. Common end-to-end workflows

### 15.1 New patient visit → consultation → prescription → fulfillment

1. **Receptionist:** Create patient record (§4.2).
2. **Receptionist:** Book an appointment with a doctor (§6.2).
3. **Doctor:** Open patient from Doctor Portal → run consultation → record
   vitals (§4.3) → write prescription.
4. **Doctor:** Mark appointment as **completed**.
5. **Receptionist:** Open Prescription Queue (§8.2) → click **Fulfill**.
6. **Receptionist:** Complete pharmacy checkout (§8.4). Patient gets receipt.

### 15.2 Billing a completed appointment

1. Appointment is marked **completed**.
2. On the Appointment List, click the green **Bill** icon on that row.
3. Invoice Create opens with patient and doctor pre-filled.
4. Add consultation fee + any procedures → apply NHIS if applicable → save.

### 15.3 Weekly roster planning

1. Admin opens **Roster** on Monday.
2. Filters to **Doctors**, assigns morning / afternoon / night shifts for the
   week.
3. Switches filter to **Nurses**, does the same.
4. Repeats for **Reception**.
5. Clicks **Next week** arrow to plan ahead.

---

## 16. Troubleshooting

| Problem | Fix |
|---|---|
| "Doctor profile not linked" on login | Your Firebase Auth UID is not attached to a doctor record. An admin must edit the doctor record and set the UID. |
| Appointments not showing for a doctor | Check the date range — past appointments don't appear in "upcoming" views. Confirm the doctor record's hospitalId matches yours. |
| Sidebar missing newly added menu items | Hard-refresh the browser (Cmd/Ctrl + Shift + R). Flutter web caches aggressively via a service worker. |
| "Permission denied" writing a record | Your role doesn't have write access to that collection. Ask an admin. |
| Invoice total looks wrong with NHIS | Check coverage percentage is a decimal (0.80, not 80). The net payable = subtotal × (1 − coverage). |
| SMS not sending | Check Settings → SMS templates are configured and the sender ID is approved. |

For issues not listed here, contact your system administrator.

---

## 17. Glossary

- **Hospital ID** — the unique identifier that scopes all data (patients,
  doctors, shifts, invoices) to your hospital.
- **NHIS** — Ghana's National Health Insurance Scheme. In this app, applying
  NHIS to an invoice deducts the covered portion and tracks the claim.
- **MoMo** — mobile money (MTN, Vodafone, AirtelTigo).
- **Prescription queue** — the backlog of prescriptions waiting to be
  dispensed by pharmacy staff.
- **Service worker** — the browser component that caches the app for offline
  use. Hard-refresh to bypass it after a deploy.
