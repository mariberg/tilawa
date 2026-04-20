# 📖 Tilawa

_Your mind arrives, before your voice does._

Tilawa is a pre-recitation companion for Quran readers. Before you begin a session, it generates **personalized summaries and key concepts** — adapted to your Arabic level and familiarity. This is done using AWS serverless architecture and Amazon Nova (LLM).

---


## 🧠 What this project does

Tilawa enhances Quran reading by:

**Before each session**:
- AI-generated summaries of the pages you're about to read adapted to your familiarity level
- Key vocabulary, adapted to your Arabic level (set once at account creation or modified in app settings)

**Across sessions**:
- Keeping track of the keywords you are already familiar with so that each session helps you to progress by showing only new keywords
- Syncing reading sessions and activity days with the Quran Foundation API — your progress is portable across any app using the same authentication
- Making your progress available across apps — so you can continue in a Quran reading app from exactly where Tilawa left off

---

## 👤 User Experience

1. **Account setup** — Select your Arabic level (beginner / intermediate / advanced)
2. **Session start** — Rate your familiarity with the upcoming content for that session
3. **AI preparation** — Tilawa generates a summary and keyword list calibrated to both inputs
4. **Recitation** — Read with context already in mind

---

## 📐 Design Approach

- **Mobile-First** — The app is designed primarily for mobile usage, with layouts and interactions optimized for small screens. This allows a seamless transition to a native mobile app in the future, which aligns with the primary use case of recitation on-the-go.

---

## 🏗️ System Architecture

The system is fully serverless and built on AWS.

```text id="xq8v1p"
Frontend (Flutter Web)
        ↓
API Gateway
        ↓
AWS Lambda (Core Orchestration)
   ├── Quran Content API
   ├── User Preferences and session history (DynamoDB)
   ├── Quran User API (session sync)
   └── Amazon Bedrock (Nova Lite)
                ↓
     AI-generated summary + keywords
                ↓
          Frontend Response
```

![tilawa_diagram](/assets/tilawa_diagram.png)

---

## 🔄 How a Session is Prepared

When a user starts a session, the backend orchestrates several steps to produce personalized preparation material:

1. The user selects a surah or page range and rates their familiarity with the content (new, somewhat familiar, or well known)
2. The backend retrieves the user's Arabic level (beginner, intermediate, or advanced) from their stored preferences
3. Verse text and translations are fetched from the Quran Foundation Content API
4. The passage, familiarity rating, and Arabic level are sent to Amazon Bedrock (Nova Lite), which generates a 3-bullet overview and a ranked list of key vocabulary
5. The keyword list is then filtered in two passes:
   - **Level-based filtering** — removes common or high-frequency Quranic words based on the user's Arabic level. Beginners see all words; intermediate users skip common ones; advanced users skip both common and high-frequency words.
   - **User-specific filtering** — removes any keywords the user has already marked as "known" in previous sessions, so each session only surfaces new vocabulary.
6. The final overview and up to 20 filtered keywords are returned to the frontend as preparation material

---

## 🎯 Hackathon Requirements Mapping

This project fulfills the following technical requirements:

### ☁️ Use at least one Quran Foundation Content API

* chapters
* verses by page
* verses by chapter

### 🤖 Use at least one Quran Foundation User API

* reading sessions
* activity days

#### Current behaviour:

Sessions are synced with the Quran Foundation API once a session is completed. This means a user's reading history is available to other apps using the same authentication.

#### Future enhancement:

In a future iteration, live session sync would allow a user to start a session in Tilawa, receive their preparation material, then open a Quran reading app and see that session already loaded as their "current session" — ready to read.

### 🔐 Authentication

* OAuth2 integration via Quran Foundation

---


## 🚀 Live Demo

👉 **Deployed App:** https://d1ecei39yukg0a.cloudfront.net/

The app is fully deployed and ready to test.

### 🔐 Test Access

This application uses **Quran Foundation pre-production credentials**.

Judges can log in using the provided hackathon credentials:

* OAuth2 login via Quran Foundation
* No setup required

---

## 🧱 Repository Structure

```bash id="repo123"
.
├── frontend/   # Flutter application (UI + state management)
├── backend/    # AWS Lambda functions + API logic
└── README.md   # This file
```

Each module contains its own detailed README:

* [`frontend/README.md`](./frontend/README.md) → UI, state management, Flutter architecture
* [`backend/README.md`](./backend/README.md) → Infrastructure as Code, AWS Lambda, API, Bedrock integration

---

## ⚙️ Tech Stack

### Frontend

* Flutter Web

### Backend

* AWS Lambda
* API Gateway
* DynamoDB

### AI Layer

* Amazon Bedrock (Nova Lite)

### External Integrations

* Quran Foundation OAuth2
* Quran Foundation Content API
* Quran Foundation User API

---