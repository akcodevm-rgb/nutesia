# Nuto Backend

This folder contains the server-side Go API. The Flutter application remains in `../nuto` and calls this API for profiles, food logs, and AI analysis. The Flutter client does not contain the Groq credential.

## Layout

- `cmd/server`: API entry point and dependency wiring.
- `internal/handler`: HTTP request/response layer and server-side AI prompt selection.
- `internal/repository`: Persistence boundary supporting both MongoDB Atlas (`MongoRepository`) and local file storage (`FileRepository`).
- `data/`: Local fallback API data directory, generated at runtime if `MONGO_URI` is not set.
- `DEPLOYMENT.md`: Step-by-step production deployment blueprint for DigitalOcean + MongoDB Atlas.

## Run locally

1. Copy `.env.example` to `.env`:

```powershell
cp .env.example .env
```

2. Set your environment variables in `.env`:
   - Set `GROQ_API_KEY` with your Groq API key.
   - For **MongoDB Atlas / Local MongoDB**: Set `MONGO_URI=mongodb+srv://<username>:<password>@cluster0.xxxx.mongodb.net/?retryWrites=true&w=majority` (or `mongodb://localhost:27017`).
   - For **Local File Storage**: Leave `MONGO_URI` blank to use `./data`.

3. Run the server:

```powershell
go mod tidy
go run ./cmd/server
```

The health check is available at `GET http://localhost:8080/health`.

Set `API_BASE_URL` in the Flutter runtime config to the reachable API URL:

```text
# Android emulator
API_BASE_URL=http://10.0.2.2:8080
# iOS simulator / Flutter web on the same machine
API_BASE_URL=http://localhost:8080
```

## API endpoints

- `GET` / `PUT /api/v1/users/:deviceId`
- `GET` / `PUT /api/v1/users/:deviceId/days/:date`
- `GET /api/v1/users/:deviceId/days?start=YYYY-MM-DD&end=YYYY-MM-DD`
- `GET /api/v1/users/:deviceId/wallet` (also applies the server-side daily grant)
- `POST /api/v1/users/:deviceId/wallet/rewarded-ad`
- `POST /api/v1/users/:deviceId/ai/food-parse` with `{ "input": "..." }`
- `POST /api/v1/users/:deviceId/ai/deficiency-analysis` with a date range. The API loads the saved profile and food logs itself.

The current API trusts the Firebase UID used by the existing Flutter auth flow. Add Firebase JWT verification before exposing this server publicly; without it, a caller could request another user's UID.
