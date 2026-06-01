# &#x20;Grantify MVP

Grantify is a mobile application built with Flutter designed to democratize, streamline, and speed up the process of finding European grants and funding opportunities for Romanian SMEs, corporations, and startups.

The application utilizes a local deterministic hard-criteria matching engine integrated with a serverless AWS infrastructure for live news delivery, dynamic real-time CUI business lookups via the `getcif.dev` API, and Firebase for scalable real-time persistence and data streaming.

---

# Application Flow & Core Screens

The workspace is organized into a bottom-navigation tab structure that separates operational lookups from automated data delivery systems.

## 1. Home Screen (`HomeNewsTab`)

A modern financial news hub designed like a dynamic newspaper interface.

### Features

* Optimized internal RAM cache abstraction layer (`NewsService`)
* Manual refresh-only update strategy
* AWS-driven live news feeds
* Expand/collapse rendering system

---

## 2. Matching Calculator Screen (`MatchingTab`)

The operational core of the application.

### Path A — "Am o Idee"

A predictive stateful form that allows entrepreneurs to manually configure:

* CAEN code
* Company age
* Geographic classification
* Urban / Rural combined eligibility

### Path B — "Am deja o Firmă"

An automated fiscal lookup flow where entering a Romanian CUI triggers a real-time registry lookup.

---

## 3. Project Vault Archive (`VaultTab`)

A persistent registry storing matched funding profiles.

Each saved entry includes historical matching context:

```text
Profil utilizat la potrivire:
CAEN 6201 | Locație: Urban | Vechime: 2 ani
```

---

## 4. Settings & Administration Panel (`SettingsTab`)

Centralized configuration area for:

* User preferences
* Authorization roles
* Profile identifiers
* Topic subscriptions

Supported topic flags:

```json
[
  "digitalizare",
  "productie",
  "servicii"
]
```

Administrative users (`isAdmin == true`) gain access to:

* Manual schema insertion
* Direct JSON grant uploads
* Global database management tools

---

# Infrastructure & Third-Party API Integrations

The platform follows a client-heavy serverless architecture focused on minimizing backend operational complexity.

---

# 1. Cloud Firestore & Firebase Authentication

Provides:

* Real-time persistence
* Reactive UI streams
* Authentication handling
* Session tracking

## Firestore Collections

### `users1`

Stores:

* Profile states
* Authorization flags
* Topic subscriptions

Example:

```json
{
  "subscribed_topics": [
    "digitalizare",
    "productie"
  ]
}
```

### `sessions1`

Stores:

```json
{
  "login_timestamp": "...",
  "last_active": "..."
}
```

### `grants1`

Contains all active grant programs synchronized from administrative entries or JSON imports.

### `historyvault1`

Persists saved analysis snapshots with backwards compatibility safeguards.

Example:

```json
{
  "user_profile": {
    "caen": "6201",
    "locatie": "Urban",
    "locantie": "Urban",
    "vechime": 2
  }
}
```

---

# 2. Live News System (AWS Serverless Integration)

## Amazon S3

Stores markdown source files organized by category:

* `digitalizare/`
* `productie/`
* `servicii/`

### S3 Requirements

* Public object read access
* CORS configuration allowing:

  * `GET`
  * all origins (`*`)

---

## AWS Lambda

Python-based lightweight processing layer that:

* Iterates S3 directories
* Extracts metadata
* Returns normalized JSON payloads

---

## AWS API Gateway

Regional deployment (`us-east-1`) exposing:

```text
/v1/news?topics=...
```

Consumed directly by the Flutter client.

---

# 3. Dynamic Fiscal Lookup (GetCIF.dev API)

Production integration endpoint:

```text
https://api.getcif.dev/v1/cifs/$cui/raw
```

---

## Data Normalization Pipeline

### CAEN Standardization

Transforms compact CAEN values:

```text
610 -> 0610
```

---

### Location Classification

The address payload is scanned for rural indicators:

* `sat`
* `comuna`
* `com.`

If matched:

```text
Rural
```

Otherwise:

```text
Urban
```

---

### Lifespan Calculation

Uses:

```text
data_inregistrare
```

to dynamically calculate company age relative to the active grant year context (2026).

---

### Resilience Fallback

If the external API fails or times out:

* predefined local company profiles are loaded
* matching logic remains functional
* demonstrations remain stable during testing

---

# Local Setup & Installation

## Prerequisites

* Flutter SDK `>= 3.0.0`
* Android Studio or Xcode
* Active Firebase project
* Android/iOS emulator or physical device

---

# Setup Instructions

## 1. Clone Repository

```bash
git clone https://github.com/your-username/grantify-mvp.git
cd grantify-mvp
```

---

## 2. Install Dependencies

```bash
flutter pub get
```

---

## 3. Configure AWS API Gateway

Open:

```text
lib/services/news_service.dart
```

Replace:

```dart
const String kApiGatewayId = 'ujlp5nu15d';
```

with your active AWS API Gateway ID.

---

## 4. Configure Firebase

Install Firebase CLI and run:

```bash
flutterfire configure
```

---

## 5. Run Application

```bash
flutter run
```

---

# Core Dependencies

## Firebase

* `cloud_firestore`
* `firebase_auth`

## Networking

* `http`

## Rendering

* `flutter_markdown`

Used for parsing and rendering downloaded markdown content into rich UI layouts.
