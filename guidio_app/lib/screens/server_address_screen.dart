import 'package:flutter/material.dart';
import '../core/speech/tts_queue.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../providers/index.dart';
import '../services/server_service.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

/// PG-08a..PG-08e - Alamat server, halaman sendiri (PG-02: "halaman kontrol
/// sendiri, bukan sheet").
///
/// Dulu kontrol ini adalah satu baris di dalam daftar Pengaturan, dengan
/// tombol "Uji" menempel di samping kolom isian - di sepertiga atas layar,
/// zona merah thumb zone. Sekarang aksinya memakai `zone/page-action`.
///
/// **Tombolnya tidak pernah berpindah saat pesan hasil berganti.** Target yang
/// bergeser sesudah aksi adalah pola yang paling membingungkan untuk pengguna
/// yang tidak melihat: mereka menghafal posisi, menekan, lalu menemukan
/// tombolnya sudah pindah. Karena itu tinggi zona tetap di seluruh lima state,
/// dan hanya labelnya yang berubah.
class ServerAddressScreen extends StatefulWidget {
  const ServerAddressScreen({super.key});

  @override
  State<ServerAddressScreen> createState() => _ServerAddressScreenState();
}

/// PG-08a idle · PG-08b sedang diuji · PG-08c valid & terhubung ·
/// PG-08d format tidak valid · PG-08e gagal terhubung.
enum ServerFieldState { idle, testing, valid, invalid, failed }

class _ServerAddressScreenState extends State<ServerAddressScreen> {
  late final TextEditingController _ctrl;
  late final String _savedHost;
  late String _savedScheme;
  ServerFieldState _state = ServerFieldState.idle;
  int? _latencyMs;
  String _scheme = 'http';

  /// Ikon mata TIDAK lagi punya status sendiri di sini.
  ///
  /// Dulu `bool _obscured` milik layar ini saja, dan akibatnya alamat yang
  /// disembunyikan di halaman ini tetap terpampang di baris ringkasan
  /// Pengaturan. Satu saklar untuk satu rahasia - lihat
  /// `SettingsProvider.serverHostVisible`.

  // Port opsional: mendukung domain seperti `be-vinara.rima-app.com` (HTTPS
  // tanpa port) maupun IP lokal seperti `192.168.1.5:8000`.
  static final _hostPattern = RegExp(r'^[\w.-]+(:\d{2,5})?$');

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _savedHost = settings.serverHost;
    _savedScheme = settings.serverScheme;
    _scheme = _savedScheme;
    _ctrl = TextEditingController(text: _savedHost);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final host = _ctrl.text.trim();

    // PG-08d - sebutkan apa yang salah, bukan "tidak valid" saja.
    if (!_hostPattern.hasMatch(host)) {
      setState(() {
        _state = ServerFieldState.invalid;
        _latencyMs = null;
      });
      await TtsQueue.instance.speak(
        'Format alamat salah. Isi dengan alamat IP atau nama domain, '
        'boleh diikuti titik dua dan nomor port. '
        'Contoh: 192.168.1.5 titik dua 8000, atau be-vinara.rima-app.com.',
        source: SpeechSource.assistant,
      );
      return;
    }

    setState(() {
      _state = ServerFieldState.testing;
      _latencyMs = null;
    });

    // GET /health ke alamat KANDIDAT, tanpa mengubah alamat aktif. PG-08e
    // mensyaratkan alamat lama tetap dipakai kalau uji gagal, jadi alamat
    // aktif hanya berpindah lewat "Simpan alamat" sesudah uji berhasil.
    final result = await ServerService.instance.healthAt(host, scheme: _scheme);
    if (!mounted) return;

    if (result != null) {
      final ms = (result['round_trip_ms'] as num?)?.round() ?? 0;
      setState(() {
        _state = ServerFieldState.valid;
        _latencyMs = ms;
      });
      await TtsQueue.instance.speak(
        'Terhubung. Waktu tempuh $ms milidetik. Tekan Simpan alamat untuk memakainya.',
        source: SpeechSource.assistant,
      );
    } else {
      // PG-08e - kegagalan uji tidak boleh diam-diam mencabut server yang
      // sebenarnya masih bekerja.
      setState(() {
        _state = ServerFieldState.failed;
        _latencyMs = null;
      });
      await TtsQueue.instance.speak(
        'Gagal terhubung. Alamat lama, $_savedHost, tetap dipakai. Periksa alamatnya lalu uji lagi.',
        source: SpeechSource.assistant,
      );
    }
  }

  Future<void> _save() async {
    final host = _ctrl.text.trim();

    // Provider diambil SEBELUM `await` pertama. Sesudah await, layar ini bisa
    // saja sudah dilepas dan `context`-nya tidak lagi sah.
    final globals = context.read<GlobalConditionsProvider>();
    final caps = context.read<CapabilitiesProvider>();
    final settings = context.read<SettingsProvider>();

    await settings.setServerHost(host);
    await settings.setServerScheme(_scheme);
    if (!mounted) return;

    // ── Mode yang butuh server harus hidup SEKARANG, bukan nanti ──
    //
    // Tombol ini hanya bisa ditekan dari state `valid`, dan state itu hanya
    // dicapai lewat `/health` yang benar-benar menjawab dari alamat ini.
    // Jadi di baris ini kita memegang bukti terbaru yang ada di seluruh
    // aplikasi, sementara dua tempat yang menentukan hidup-matinya Cari Objek
    // dan Deskripsi Sekitar masih memegang jawaban lama:
    //
    //   * `GlobalConditionsProvider` baru memeriksa ulang tiap 15 detik;
    //   * `CapabilitiesProvider` menahan jawabannya 45 detik, dan bahkan
    //     menolak bertanya sama sekali selama server dianggap mati.
    //
    // Akibatnya pengguna mendengar "Terhubung", menyimpan alamatnya, membuka
    // Pilih Mode, dan menemukan dua mode itu masih ditandai tidak tersedia -
    // aplikasi yang membantah kalimatnya sendiri beberapa detik sebelumnya.
    //
    // `setServerHost` di atas sudah memindahkan alamat aktif, jadi pertanyaan
    // berikutnya berangkat ke server yang benar.
    globals.markServerReachable(true);

    // Dijalankan berbarengan dengan konfirmasi suara, bukan sebelumnya.
    // "Alamat server tersimpan." memakan sekitar dua detik di antrean; satu
    // permintaan `/api/capabilities` ke server yang barusan menjawab dalam
    // puluhan milidetik selesai jauh di dalam jendela itu. Pengguna tidak
    // menunggu apa pun, dan layar tidak pernah ditutup sebelum jawabannya
    // sampai.
    final kemampuanSegar = caps.refresh();

    // Konfirmasi diucapkan SESUDAH tersimpan - bagian 4.1 berlaku untuk semua
    // konfirmasi, bukan hanya ganti mode.
    await TtsQueue.instance.speak('Alamat server tersimpan.', source: SpeechSource.assistant);
    await kemampuanSegar;

    if (mounted) Navigator.of(context).pop();
  }

  /// Label tombol utama berubah, posisinya tidak. PG-08c satu-satunya state
  /// yang aksinya "Simpan alamat" - alamat baru hanya dipakai sesudah terbukti
  /// bisa dihubungi.
  String get _primaryLabel => switch (_state) {
        ServerFieldState.testing => 'Menguji koneksi…',
        ServerFieldState.valid => 'Simpan alamat',
        ServerFieldState.failed => 'Uji lagi',
        _ => 'Uji koneksi',
      };

  ({String text, Color color, IconData icon})? get _result => switch (_state) {
        ServerFieldState.valid => (
            text: 'Terhubung. Waktu tempuh ${_latencyMs ?? 0} ms.',
            color: AppColors.positiveLabel,
            icon: Icons.check_circle_outline_rounded,
          ),
        ServerFieldState.invalid => (
            text: 'Format salah - isi dengan alamat IP atau nama domain, '
                'boleh diikuti titik dua dan nomor port. '
                'Contoh: 192.168.1.5:8000 atau be-vinara.rima-app.com',
            color: AppColors.criticalLabel,
            icon: Icons.error_outline_rounded,
          ),
        ServerFieldState.failed => (
            // Alamat lama ikut disamarkan kalau matanya sedang tertutup.
            text: 'Gagal terhubung. Alamat lama '
                '(${_visible ? "$_savedScheme://$_savedHost" : "tersembunyi"}) tetap dipakai.',
            color: AppColors.criticalLabel,
            icon: Icons.cloud_off_rounded,
          ),
        _ => null,
      };

  /// Dibaca ulang tiap build supaya perubahan dari layar Pengaturan langsung
  /// terlihat di sini, dan sebaliknya.
  bool get _visible => context.watch<SettingsProvider>().serverHostVisible;

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return PageActionScaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(title: const Text('Alamat server')),
      primaryLabel: _primaryLabel,
      primaryDisabled: _state == ServerFieldState.testing,
      primaryDisabledReason: _state == ServerFieldState.testing ? 'Menunggu jawaban server' : null,
      onPrimary: _state == ServerFieldState.valid ? _save : _test,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          AppSpacing.s4,
          AppSpacing.screenMargin,
          AppSpacing.s4,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s4),
            decoration: const BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: AppRadius.cardInner,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  headingLevel: 2,
                  child: Text('Alamat server', style: AppTypography.bodyStrong()),
                ),
                const SizedBox(height: AppSpacing.s1),
                // PG-08a - penjelasan server bawaan.
                Text(
                  'Vinara memakai server bawaan untuk Baca Teks, Deskripsi Sekitar, Cari Objek, dan segmentasi jalur. '
                  'Ganti alamat ini hanya kalau kamu menjalankan server sendiri.',
                  style: AppTypography.body(color: AppColors.ink2),
                ),
                const SizedBox(height: AppSpacing.s4),
                // ── Toggle HTTP / HTTPS ──────────────────────────────────
                Semantics(
                  label: 'Protokol koneksi server',
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'http',
                        label: Text('HTTP'),
                        icon: Icon(Icons.lock_open_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: 'https',
                        label: Text('HTTPS'),
                        icon: Icon(Icons.lock_rounded, size: 16),
                      ),
                    ],
                    selected: {_scheme},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() {
                        _scheme = selection.first;
                        // Isian berubah → hasil uji lama tidak berlaku lagi.
                        if (_state != ServerFieldState.idle) {
                          _state = ServerFieldState.idle;
                          _latencyMs = null;
                        }
                      });
                    },
                    style: ButtonStyle(
                      textStyle: WidgetStatePropertyAll(
                        AppTypography.bodyStrong(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                Semantics(
                  sortKey: const OrdinalSortKey(8),
                  textField: true,
                  label: 'Alamat server, isi dengan host atau host:port',
                  child: TextField(
                    controller: _ctrl,
                    autocorrect: false,
                    keyboardType: TextInputType.url,
                    // Mata tertutup -> teks diganti karakter titik sehingga
                    // alamatnya tidak terbaca saat demo atau tangkapan layar.
                    obscureText: !_visible,
                    obscuringCharacter: '•',
                    decoration: InputDecoration(
                      hintText: _scheme == 'https'
                          ? 'domain, mis. be-vinara.rima-app.com'
                          : 'host:port, mis. 192.168.1.5:8000',
                      isDense: true,
                      suffixIcon: Semantics(
                        label: _visible
                            ? 'Sembunyikan alamat server'
                            : 'Tampilkan alamat server',
                        button: true,
                        excludeSemantics: false,
                        child: IconButton(
                          icon: Icon(
                            _visible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          tooltip: _visible ? 'Sembunyikan' : 'Tampilkan',
                          onPressed: () => context
                              .read<SettingsProvider>()
                              .toggleServerHostVisible(),
                        ),
                      ),
                    ),
                    style: AppTypography.metricMono(),
                    onChanged: (_) {
                      // Isian berubah → hasil lama tidak berlaku lagi. Tanpa
                      // ini, "Simpan alamat" bisa menyimpan alamat yang belum
                      // pernah diuji.
                      if (_state != ServerFieldState.idle) {
                        setState(() {
                          _state = ServerFieldState.idle;
                          _latencyMs = null;
                        });
                      }
                    },
                  ),
                ),
                if (result != null) ...[
                  const SizedBox(height: AppSpacing.s3),
                  Semantics(
                    liveRegion: true,
                    label: result.text,
                    child: ExcludeSemantics(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(result.icon, size: 18, color: result.color),
                          const SizedBox(width: AppSpacing.s2),
                          Expanded(
                            child: Text(result.text, style: AppTypography.caption(color: result.color)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
