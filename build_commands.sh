#!/bin/bash
# Build commands untuk TFLite + Groq AI Integration
# File ini berisi contoh build commands yang siap pakai

# ============================================================================
# SETUP: Dapatkan API Key terlebih dahulu
# ============================================================================
# Groq API Key: https://console.groq.com/keys
# Roboflow Key (opsional): https://console.roboflow.com
# 
# Model Groq yang digunakan:
#   Default: meta-llama/llama-4-scout-17b-16e-instruct (Cepat & Akurat)
#   
# Contoh API Key:
#   Groq:    gsk_1234567890abcdefghijklmnopqrst
#   Roboflow: rxXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# ============================================================================
# 1. BUILD DENGAN GROQ AI (RECOMMENDED)
# ============================================================================
# Menggunakan TFLite + Groq AI Hybrid
# Strategi: TFLite (cepat) → Groq jika perlu

build-with-groq() {
  echo "🔨 Building APK dengan TFLite + Groq AI..."
  
  read -p "Masukkan Groq API Key (gsk_...): " GROQ_API_KEY
  
  flutter build apk --release \
    --dart-define=RUPIEYE_GROQ_API_KEY=$GROQ_API_KEY
  
  echo "✓ Build selesai!"
  echo "📱 APK tersedia di: build/app/outputs/flutter-apk/app-release.apk"
}

# ============================================================================
# 2. BUILD DENGAN GROQ + ROBOFLOW (PRIORITY: Groq > Roboflow)
# ============================================================================
# Fallback chain: Groq → Roboflow → TFLite

build-with-groq-and-roboflow() {
  echo "🔨 Building APK dengan TFLite + Groq + Roboflow..."
  
  read -p "Masukkan Groq API Key: " GROQ_API_KEY
  read -p "Masukkan Roboflow API Key: " ROBOFLOW_API_KEY
  read -p "Masukkan Roboflow Model ID (default: deteksi-rupiah/3): " ROBOFLOW_MODEL_ID
  ROBOFLOW_MODEL_ID=${ROBOFLOW_MODEL_ID:-"deteksi-rupiah/3"}
  
  flutter build apk --release \
    --dart-define=RUPIEYE_GROQ_API_KEY=$GROQ_API_KEY \
    --dart-define=RUPIEYE_ROBOFLOW_API_KEY=$ROBOFLOW_API_KEY \
    --dart-define=RUPIEYE_ROBOFLOW_MODEL_ID=$ROBOFLOW_MODEL_ID
  
  echo "✓ Build selesai!"
}

# ============================================================================
# 3. BUILD HANYA TFLITE (OFFLINE ONLY)
# ============================================================================
# Tanpa internet, tidak perlu API key

build-tflite-only() {
  echo "🔨 Building APK dengan TFLite saja (Offline)..."
  
  flutter build apk --release
  
  echo "✓ Build selesai!"
  echo "🌐 Aplikasi akan berjalan offline tanpa API"
}

# ============================================================================
# 4. DEV MODE: Run dengan Groq untuk testing
# ============================================================================

run-with-groq() {
  echo "▶️ Running app dengan Groq AI..."
  
  read -p "Masukkan Groq API Key: " GROQ_API_KEY
  
  flutter run --dart-define=RUPIEYE_GROQ_API_KEY=$GROQ_API_KEY
}

# ============================================================================
# 5. DEV MODE: Run tanpa Groq (TFLite only)
# ============================================================================

run-tflite-only() {
  echo "▶️ Running app dengan TFLite saja..."
  flutter run
}

# ============================================================================
# 6. CLEAN BUILD (Jika ada error)
# ============================================================================

clean-build() {
  echo "🧹 Cleaning build artifacts..."
  flutter clean
  flutter pub get
  
  echo "✓ Clean selesai! Silakan build ulang."
}

# ============================================================================
# MENU UTAMA
# ============================================================================

show-menu() {
  echo ""
  echo "╔═══════════════════════════════════════════════════════════╗"
  echo "║  TFLite + Groq AI Build Commands                         ║"
  echo "╠═══════════════════════════════════════════════════════════╣"
  echo "║  PRODUCTION BUILD                                        ║"
  echo "║  1) Build dengan Groq AI (RECOMMENDED)                  ║"
  echo "║  2) Build dengan Groq + Roboflow (Fallback chain)       ║"
  echo "║  3) Build TFLite saja (Offline)                         ║"
  echo "║                                                         ║"
  echo "║  DEVELOPMENT (flutter run)                              ║"
  echo "║  4) Run dengan Groq AI (Testing)                        ║"
  echo "║  5) Run dengan TFLite saja                              ║"
  echo "║                                                         ║"
  echo "║  MAINTENANCE                                             ║"
  echo "║  6) Clean build (Jika ada error)                        ║"
  echo "║  0) Keluar                                               ║"
  echo "╚═══════════════════════════════════════════════════════════╝"
  echo ""
}

# ============================================================================
# MAIN LOOP
# ============================================================================

main() {
  cd /home/fidz/Project/rupieye
  
  while true; do
    show-menu
    read -p "Pilih opsi (0-6): " choice
    
    case $choice in
      1)
        build-with-groq
        ;;
      2)
        build-with-groq-and-roboflow
        ;;
      3)
        build-tflite-only
        ;;
      4)
        run-with-groq
        ;;
      5)
        run-tflite-only
        ;;
      6)
        clean-build
        ;;
      0)
        echo "Sampai jumpa! 👋"
        exit 0
        ;;
      *)
        echo "❌ Opsi tidak valid. Silakan pilih 0-6."
        ;;
    esac
    
    echo ""
    read -p "Tekan Enter untuk lanjut..."
  done
}

# Jalankan main atau function spesifik jika argument diberikan
if [ $# -gt 0 ]; then
  "$@"
else
  main
fi
