# RUPI-EYE Groq Proxy

Small local backend for online currency recognition. Keep `GROQ_API_KEY` here at runtime, not inside the Flutter app.

## Run

```sh
export GROQ_API_KEY="your_groq_key"
npm start
```

Optional environment variables:

```sh
export GROQ_MODEL="meta-llama/llama-4-scout-17b-16e-instruct"
export PORT=8787
```

## Flutter

```sh
flutter run --dart-define=RUPIEYE_ONLINE_RECOGNIZER_URL=http://10.0.2.2:8787/recognize-currency
```
