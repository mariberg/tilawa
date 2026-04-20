# Tilawa

A mobile-first Flutter web app that helps users prepare for Quranic recitation sessions. Select a surah or page range, review keyword flashcards, record your recitation, and track your progress over time.

## Features

- **OAuth2 Authentication** — Login via Quran Foundation OAuth2 provider
- **Surah & Page Selection** — Typeahead search with fuzzy matching for surah names, or enter a page range directly
- **Arabic Level Selection** — Set your familiarity level to tailor session difficulty
- **Keyword Flashcards** — Flip-card prep interface with dot navigation to review key terms before reciting
- **Recitation Recording** — Record and submit your recitation session
- **Session Feedback** — Rate sessions as smooth, struggled, or revisit
- **Recent Sessions** — View and quickly resume past sessions
- **Loading Messages** — Contextual messages displayed while sessions are being prepared

## Design Approach

- **Mobile-First** — The app is designed primarily for mobile usage, with layouts and interactions optimized for small screens. This allows a seamless transition to a native mobile app in the future, which aligns with the primary use case of recitation on-the-go.
- **Session-Based Flow** — Users move through a structured flow (selection → preparation → recitation → feedback) to mimic real learning sessions.

## Tech Stack

- Flutter 3.9.2+ (Dart)
- Material Design 3
- OAuth2 / JWT authentication
- HTTP client for backend API
- `flutter_typeahead` for surah search
- `google_fonts` for typography
- Compile-time configuration via `--dart-define-from-file`

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

3. Create a `config.json` from the example:
   ```bash
   cp config.example.json config.json
   ```

4. Fill in your `config.json` values:
   ```json
   {
     "BASE_URL": "https://your-api-url.com",
     "API_KEY": "your-api-key-here",
     "TOKEN_HOST": "https://oauth2.quran.foundation",
     "CLIENT_ID": "your-client-id",
     "CLIENT_SECRET": "your-client-secret",
     "SCOPES": "openid offline_access profile user reading_session activity_day",
     "REDIRECT_URI": "http://localhost:5000/auth/callback"
   }
   ```

   > **Note:** `config.json` is gitignored and never bundled into the build output as a readable file. Values are injected as compile-time constants into the compiled JS.
   >
   > **Security consideration:** Public OAuth2 parameters (`CLIENT_ID`, `TOKEN_HOST`, `SCOPES`, `REDIRECT_URI`) are safe to include — browsers need them to initiate the auth flow. However, `CLIENT_SECRET` and `API_KEY` should ideally be moved to the backend in a production setup. The backend already proxies the token exchange and could hold these secrets server-side.
   >
   > For production, set `REDIRECT_URI` to your HTTPS deployment URL (e.g. your CloudFront domain). The OAuth2 provider requires HTTPS for non-localhost redirect URIs.

### Run

```bash
flutter run -d chrome --dart-define-from-file=config.json
```

### Build for production

```bash
flutter build web --dart-define-from-file=config.json
```

## Testing

```bash
flutter test
```

The project uses [glados](https://pub.dev/packages/glados) for property-based testing.

## License

This project is not published to pub.dev and is intended for private use.
