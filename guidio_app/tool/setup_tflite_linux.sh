#!/usr/bin/env bash
# Pasang runtime TFLite native untuk `flutter test` di host Linux.
#
# tflite_flutter memuat pustaka ini lewat FFI dari
#   ${Platform.resolvedExecutable}/../blobs/libtensorflowlite_c-linux.so
# yang saat `flutter test` menunjuk ke direktori artifacts engine Flutter -
# BUKAN ke folder proyek. Direktori itu ikut terhapus setiap `flutter upgrade`
# atau ganti versi FVM, jadi jalankan ulang skrip ini setelahnya.
#
# Tanpa pustaka ini `svc.load()` mengembalikan false dan SELURUH uji inferensi
# uang meloncat ke markTestSkipped - suite hijau yang tidak menguji apa pun.
# Guard di test/money_pipeline_test.dart sengaja membuat kondisi itu MERAH.
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)/blobs/libtensorflowlite_c-linux.so"
ENGINE_DIR="$(dirname "$(flutter --version --machine 2>/dev/null \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["flutterRoot"])')")"
ENGINE_DIR="$(flutter --version --machine \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["flutterRoot"])')/bin/cache/artifacts/engine/linux-x64"

if [[ ! -f "$SRC" ]]; then
  echo "ERROR: $SRC tidak ada."
  echo "Unduh dulu:"
  echo "  curl -L -o blobs/libtensorflowlite_c-linux.so \\"
  echo "    https://github.com/am15h/tflite_flutter_plugin/releases/download/v0.5.0/libtensorflowlite_c-linux.so"
  exit 1
fi

mkdir -p "$ENGINE_DIR/blobs"
cp "$SRC" "$ENGINE_DIR/blobs/"
chmod 644 "$ENGINE_DIR/blobs/libtensorflowlite_c-linux.so"
echo "Terpasang: $ENGINE_DIR/blobs/libtensorflowlite_c-linux.so"
echo "Verifikasi: flutter test test/money_pipeline_test.dart"
