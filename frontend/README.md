# Tilawa

A Flutter web app that helps users prepare for Quranic recitation sessions. Select a surah or page range, review keyword flashcards, record your recitation, and track your progress over time.

## Features

- **OAuth2 Authentication** — Login via Quran Foundation OAuth2 provider
- **Surah & Page Selection** — Typeahead search with fuzzy matching for surah names, or enter a page range directly
- **Arabic Level Selection** — Set your familiarity level to tailor session difficulty
- **Keyword Flashcards** — Flip-card prep interface with dot navigation to review key terms before reciting
- **Recitation Recording** — Record and submit your recitation session
- **Session Feedback** — Rate sessions as smooth, struggled, or revisit
- **Recent Sessions** — View and quickly resume past sessions
- **Loading Messages** — Contextual messages displayed while sessions are being prepared

## Tech Stack

- Flutter 3.9.2+ (Dart)
- Material Design 3
- OAuth2 / JWT authentication
- HTTP client for backend API
- `flutter_typeahead` for surah search
- `google_fonts` for typography
- `flutter_dotenv` for environment configuration

## Project Structure

```
lib/
├── main.dart                # App entry point, routes, theme
├── models/                  # Data models (Surah, Keyword, Session, etc.)
├── screens/                 # UI screens (Auth, Entry, Prep, Recitation, Feedback, Level, Settings)
├── services/                # Business logic (Auth, Session, Surah, Level, Selection tracking)
├── theme/                   # Colors and text styles
├── utils/                   # Helpers (JWT, date formatting, page parsing, loading messages)
└── widgets/                 # Reusable components (keyword cards, dot indicator, familiarity pills)
```

## Getting Started

### Prerequisites

- Flutter SDK `^3.9.2`
- A Quran Foundation OAuth2 client (client ID and secret)
- Backend API URL and key

### Setup

1. Clone the repository:
   ```bash
   git clone <repo-url>
   cd quran_prep
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Create a `.env` file from the example:
   ```bash
   cp .env.example .env
   ```

4. Fill in your `.env` values:
   ```
   BASE_URL=https://your-api-url.com
   API_KEY=your-api-key-here
   TOKEN_HOST=https://oauth2.quran.foundation
   CLIENT_ID=<your-client-id>
   CLIENT_SECRET=<your-client-secret>
   SCOPES=openid offline_access profile bookmark collection user
   ```

### Run

```bash
flutter run -d chrome
```

## Testing

```bash
flutter test
```

The project uses [glados](https://pub.dev/packages/glados) for property-based testing.

## License

This project is not published to pub.dev and is intended for private use.
