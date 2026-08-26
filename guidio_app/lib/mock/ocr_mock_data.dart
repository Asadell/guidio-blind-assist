/// Data & katalog mock khusus Mode Baca Teks (OCR) - dipakai HANYA oleh
/// `ocr_screen.dart` dan `ocr_debug_sheet.dart` untuk mendemonstrasikan
/// 22 state BT-01..BT-22 (bagian 8 dokumen spesifikasi).
///
/// ServerService.readText saat ini hanya mengembalikan `{'text': ...}` -
/// tidak ada info bahasa, blok, atau status per-bagian. State yang butuh
/// info itu (dua bahasa, sebagian gagal, sangat panjang) TIDAK BISA dipicu
/// dari server sungguhan, jadi datanya dipalsukan di sini secara eksplisit.
library;

/// Satu blok hasil baca. Hasil server nyata selalu 1 blok tanpa [language]
/// dan `ok: true`. Blok dengan `ok: false` dipakai untuk mensimulasikan
/// BT-10 (sebagian gagal terbaca).
class OcrBlock {
  final String heading;
  final String text;
  final String? language;
  final bool ok;

  const OcrBlock({
    required this.heading,
    required this.text,
    this.language,
    this.ok = true,
  });
}

/// Satu entri katalog debug - dipakai OcrDebugSheet untuk daftar 22 state.
class OcrDebugEntry {
  final String id;
  final String title;
  final String hint;
  const OcrDebugEntry(this.id, this.title, this.hint);
}

/// Katalog lengkap 22 state, urut sesuai bagian 8 dokumen.
// BT-02 (idle offline) dan BT-14 (gagal server) dihapus dari katalog.
//
// Keduanya memodelkan kondisi yang tidak mungkin lagi terjadi: pengenalan teks
// berjalan sepenuhnya di perangkat lewat ML Kit, jadi tidak ada jaringan yang
// bisa memutus dan tidak ada server yang bisa gagal. Menyimpan tombol debug
// yang memaksa state mustahil hanya membuat penguji melaporkan "bug" yang
// sebenarnya adalah simulasinya sendiri.
const List<OcrDebugEntry> ocrDebugCatalog = [
  OcrDebugEntry('BT-01', 'Idle', 'Busur panduan; aksi ada di tombol kiri bar bawah'),
  OcrDebugEntry('BT-03', 'Menjepret', 'Kilat + getar + pill "Gambar diambil"'),
  OcrDebugEntry('BT-04', 'Memproses', 'Panel loading, tinggi dipesan penuh'),
  OcrDebugEntry('BT-05', 'Mendekati timeout', 'Banner + hitungan mono + Batalkan'),
  OcrDebugEntry('BT-06', 'Hasil pendek', 'Panel singkat tanpa progress'),
  OcrDebugEntry('BT-07', 'Hasil panjang', 'Blok berheading, gulung 280dp, progress'),
  OcrDebugEntry('BT-08', 'Hasil sangat panjang', 'Peringatan durasi, pilihan ringkasan/penuh'),
  OcrDebugEntry('BT-09', 'Dua bahasa', 'Pill bahasa per blok'),
  OcrDebugEntry('BT-10', 'Terbaca sebagian', 'Banner warning + jumlah blok gagal'),
  OcrDebugEntry('BT-11', 'Nol teks', 'Panel gagal + instruksi jarak'),
  OcrDebugEntry('BT-12a', 'Dijeda', 'Kalimat aktif ditandai, tombol jadi Lanjut'),
  OcrDebugEntry('BT-12b', 'Selesai dibacakan', 'Eyebrow Aman, disimpan 15 menit'),
  OcrDebugEntry('BT-13', 'Gagal offline', 'Panel warning, gambar masuk antrean'),
  OcrDebugEntry('BT-15', 'Gagal timeout', 'Panel gagal, foto tetap tersimpan'),
  OcrDebugEntry('BT-16', 'Lanjut ke Asisten', 'Pindah mode dengan pill konteks'),
  OcrDebugEntry('BT-17', 'Izin kamera belum ada', 'PermissionCard'),
  OcrDebugEntry('BT-18', 'Font scale 200%', 'Panel vertikal, kontrol 56dp'),
  OcrDebugEntry('BT-19', 'Senyap / TTS mati', 'Teks penuh 18sp, kontrol jadi gulung'),
  OcrDebugEntry('BT-20', 'Hasil kedaluwarsa', 'Panel kosong + alasan + retry'),
  OcrDebugEntry('BT-21', 'Penyimpanan penuh', 'Banner warning, antrean offline mati'),
  OcrDebugEntry('BT-22', 'Camera health buram', 'Toast, tombol utama tetap aktif'),
];

String mockShortText() => 'Buka Senin–Sabtu, 08.00–17.00.';

List<OcrBlock> mockLongBlocks() => const [
      OcrBlock(
        heading: 'Bagian 1 - Judul menu',
        text: 'Daftar Menu Warung Bu Sari. Semua harga sudah termasuk nasi putih '
            'dan segelas air teh tawar.',
      ),
      OcrBlock(
        heading: 'Bagian 2 - Menu utama',
        text: 'Ayam goreng lima belas ribu rupiah. Ikan bakar dua puluh ribu rupiah. '
            'Tahu tempe penyet delapan ribu rupiah. Sayur asem lima ribu rupiah.',
      ),
      OcrBlock(
        heading: 'Bagian 3 - Minuman',
        text: 'Es teh manis lima ribu rupiah. Es jeruk tujuh ribu rupiah. '
            'Kopi hitam enam ribu rupiah.',
      ),
      OcrBlock(
        heading: 'Bagian 4 - Catatan',
        text: 'Buka Senin sampai Sabtu, jam delapan pagi sampai lima sore. '
            'Tutup setiap hari Minggu dan hari besar.',
      ),
    ];

List<OcrBlock> mockVeryLongBlocks() => [
      for (var i = 1; i <= 10; i++)
        OcrBlock(
          heading: 'Bagian $i',
          text: 'Ini adalah contoh paragraf panjang ke-$i yang dipakai untuk '
              'mensimulasikan dokumen dengan perkiraan waktu baca lebih dari '
              'sembilan puluh detik, misalnya brosur, surat resmi, atau '
              'lembar informasi obat dengan banyak baris teks berurutan.',
        ),
    ];

List<OcrBlock> mockBilingualBlocks() => const [
      OcrBlock(
        heading: 'Sambutan',
        language: 'Bahasa Indonesia',
        text: 'Selamat datang di Bandara Internasional. Silakan siapkan dokumen '
            'perjalanan Anda.',
      ),
      OcrBlock(
        heading: 'Greeting',
        language: 'English',
        text: 'Welcome to the International Airport. Please prepare your travel '
            'documents.',
      ),
    ];

List<OcrBlock> mockPartialBlocks() => const [
      OcrBlock(heading: 'Bagian 1', text: 'Jadwal keberangkatan pukul sembilan pagi.'),
      OcrBlock(heading: 'Bagian 2', text: '', ok: false),
      OcrBlock(heading: 'Bagian 3', text: 'Gerbang keberangkatan nomor lima.'),
      OcrBlock(heading: 'Bagian 4', text: '', ok: false),
    ];
