# ── ONNX Runtime ─────────────────────────────────────────────────────────────
# Dipanggil lewat JNI, jadi R8 tidak bisa melihat penggunaannya.
-keep class ai.onnxruntime.** { *; }

# ── TensorFlow Lite ──────────────────────────────────────────────────────────
# Interpreter dan delegate juga dijangkau lewat JNI.
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# ── Google ML Kit Text Recognition ───────────────────────────────────────────
# Plugin `google_mlkit_text_recognition` merujuk SEMUA pengenal aksara
# (Cina, Devanagari, Jepang, Korea) di `TextRecognizer.initialize()`, tapi
# hanya artefak Latin yang ikut sebagai dependensi. R8 melihat referensi ke
# kelas yang tidak ada lalu menggagalkan seluruh build release.
#
# Vinara hanya memakai aksara Latin (`TextRecognitionScript.latin`), jadi
# yang benar adalah membisukan peringatannya — bukan menarik empat artefak
# aksara tambahan yang masing-masing menambah beberapa megabyte ke APK untuk
# bahasa yang tidak pernah dibaca aplikasi ini.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
