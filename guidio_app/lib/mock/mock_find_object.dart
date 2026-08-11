import 'dart:math';

/// Kosakata mock untuk Mode Cari Objek (bagian 12 IMPLEMENTASI.md).
///
/// Server pencarian objek sungguhan belum ada — seluruh "pengenalan barang"
/// di mode ini adalah tiruan lokal. [knownCatalog] berperan sebagai daftar
/// barang yang "dikenali" server tiruan (dipakai untuk memutuskan CO-12,
/// "objek tak dikenali"); [scanMessages]/[notFoundMessages] adalah kalimat
/// instruksi fisik yang berganti tiap ~2 detik selama pemindaian (CO-05/CO-10).
abstract final class FindObjectMockData {
  static const knownCatalog = <String>[
    'dompet', 'kunci', 'kunci motor', 'kunci rumah', 'ponsel', 'hp', 'handphone',
    'kacamata', 'botol minum', 'botol air', 'tas', 'tas ransel', 'remote',
    'remote tv', 'payung', 'sepatu', 'sandal', 'charger', 'kabel charger',
    'headset', 'earphone', 'buku', 'jaket', 'topi', 'gelas', 'obat', 'masker',
    'jam tangan', 'dompet uang', 'laptop', 'power bank',
  ];

  /// CO-05 — kalimat pemindaian awal, berganti tiap ~2 detik.
  static const scanMessages = <String>[
    'Memindai ruangan…',
    'Coba putar badan pelan ke kiri.',
    'Coba putar badan pelan ke kanan.',
    'Periksa area meja atau rak di dekatmu.',
  ];

  /// CO-10 — arahan lanjutan setelah beberapa putaran belum ketemu.
  static const notFoundMessages = <String>[
    'Belum terlihat, coba putar badan ke arah lain.',
    'Masih belum ketemu, coba melangkah beberapa langkah.',
    'Belum terlihat dari sini, coba tengok ke belakangmu.',
  ];

  /// CO-12 — barang tak dikenali menyebut barang yang dikenal sebagai ganti.
  static bool isKnown(String target) {
    final t = target.toLowerCase().trim();
    if (t.isEmpty) return false;
    return knownCatalog.any((k) => t.contains(k));
  }

  static String randomFallback(Random rng) => knownCatalog[rng.nextInt(knownCatalog.length)];
}
