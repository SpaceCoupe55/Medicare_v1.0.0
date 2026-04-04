# Medicare — Deployment Guide

## Prerequisites

| Tool | Min version | Install |
|------|-------------|---------|
| Flutter | 3.x stable | `flutter upgrade` |
| Firebase CLI | latest | `npm install -g firebase-tools` |
| FlutterFire CLI | latest | `dart pub global activate flutterfire_cli` |
| Node.js | 22 | [nodejs.org](https://nodejs.org) |

---

## 1. Local development

```bash
# Clone and enter the project
cd Medicare

# Install Flutter dependencies
flutter pub get

# Run in Chrome against the prod Firebase project
flutter run -d chrome --dart-define=FLUTTER_APP_ENV=dev
```

---

## 2. FlutterFire — configuring a new environment

Run this once per Firebase project (dev, staging, prod). It regenerates
`lib/firebase_options.dart` (or a named variant) from the live project config.

```bash
# Prod (default)
flutterfire configure --project=medicare-admin-b7266

# Dev (separate project)
flutterfire configure \
  --project=<dev-project-id> \
  --out=lib/firebase_options_dev.dart

# Staging (separate project)
flutterfire configure \
  --project=<staging-project-id> \
  --out=lib/firebase_options_staging.dart
```

After generating each file, open `lib/config/environment.dart` and uncomment
the matching import + return statement inside `firebaseOptions`.

---

## 3. Manual deployment (one-off)

```bash
# Build
flutter build web --release --web-renderer canvaskit \
  --dart-define=FLUTTER_APP_ENV=prod

# Deploy hosting only
firebase deploy --only hosting --project medicare-admin-b7266

# Deploy everything (hosting + functions + firestore rules)
firebase deploy --project medicare-admin-b7266
```

---

## 4. GitHub Actions CI/CD

The workflow at `.github/workflows/deploy.yml` runs automatically:

| Event | Action |
|-------|--------|
| Push to `main` | Deploys to the **live** Firebase Hosting channel |
| Pull request to `main` | Deploys to a **preview** channel and posts the URL as a PR comment |

### Required GitHub secret

| Secret name | Value |
|-------------|-------|
| `FIREBASE_SERVICE_ACCOUNT` | JSON content of a Firebase service account key |

**How to create it:**

1. Firebase Console → Project Settings → Service Accounts
2. Select `firebase-adminsdk-*@medicare-admin-b7266.iam.gserviceaccount.com`
3. Click **Generate new private key** → download the JSON
4. GitHub repo → Settings → Secrets and variables → Actions → **New repository secret**
5. Name: `FIREBASE_SERVICE_ACCOUNT`, value: paste the entire JSON content
6. Ensure the service account has the **Service Usage Consumer** IAM role
   (Cloud Console → IAM → edit the service account → add role)

### Running tests

The workflow runs `flutter test`. The default widget test at `test/widget_test.dart`
uses Firebase — add `@Skip('requires Firebase')` or replace it with unit tests
that do not need a live Firebase connection.

---

## 5. Custom domain

1. Firebase Console → Hosting → **Add custom domain**
2. Enter your domain (e.g. `app.yourhospital.com`)
3. Add the two DNS records shown (TXT for verification, A/CNAME for routing)
4. Firebase provisions a TLS certificate automatically within ~24 hours

For a `www` redirect, add a second custom domain entry for `www.yourhospital.com`
and choose **Redirect to** `app.yourhospital.com`.

---

## 6. Seeding the first hospital admin

Every new hospital needs one admin user. Use the `createHospitalAdmin`
Cloud Function (already deployed) — call it once from a trusted environment:

```js
// Node.js one-liner (run from functions/ directory)
const { initializeApp } = require('firebase-admin/app');
const { getFunctions }  = require('firebase-admin/functions');

initializeApp({ projectId: 'medicare-admin-b7266' });

getFunctions().httpsCallable('createHospitalAdmin')({
  email:        'admin@yourhospital.com',
  password:     'StrongPassword123!',
  name:         'Hospital Administrator',
  hospitalId:   'your-hospital-id',   // unique slug, e.g. "city-general"
  hospitalName: 'City General Hospital',
});
```

Or call it from the Firebase Console → Functions → `createHospitalAdmin` →
**Test function** with the same JSON payload.

The function guards against duplicate admins per hospital — re-running it
for the same `hospitalId` returns an `already-exists` error safely.

---

## 7. Environment variables reference

| `--dart-define` key | Values | Effect |
|---------------------|--------|--------|
| `FLUTTER_APP_ENV` | `dev` / `staging` / `prod` | Selects Firebase project via `lib/config/environment.dart` |

Set in CI: already included in the workflow as `--dart-define=FLUTTER_APP_ENV=prod`.
Set locally: add to your IDE run configuration or pass on the command line.

---

## 8. Firestore security rules & indexes

```bash
# Deploy rules only
firebase deploy --only firestore:rules

# Deploy indexes only
firebase deploy --only firestore:indexes
```

Indexes are defined in `firestore.indexes.json`. Add compound indexes there
when Firestore logs a "missing index" link in the console.

---

## 9. Useful commands cheatsheet

```bash
# Watch Cloud Function logs live
firebase functions:log --follow

# Open Firestore emulator UI
firebase emulators:start --only firestore,auth

# Check which Firebase project is active
firebase use

# Switch project
firebase use medicare-admin-b7266
```
