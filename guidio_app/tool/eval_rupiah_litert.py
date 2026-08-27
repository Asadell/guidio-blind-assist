#!/usr/bin/env python3
"""Evaluasi model rupiah atas foto di test/fixtures/rupiah_mobile/.

KENAPA SKRIP PYTHON, BUKAN `flutter test`
─────────────────────────────────────────
Runtime TFLite desktop yang dipakai `flutter test` di Linux berasal dari
tflite_flutter_plugin v0.5.0 (2021, lihat blobs/). Dia memuat model INT8
tanpa mengeluh lalu mengembalikan distribusi RATA 1/7 untuk masukan apa pun.
Android memakai LiteRT 1.4.0 lewat tflite_flutter 0.12.1 dan menjalankan
model yang sama dengan benar.

Skrip ini memakai LiteRT modern, jadi angkanya mewakili yang terjadi di
ponsel. `test/rupiah_kamera_e2e_test.dart` adalah versi Dart-nya, yang akan
jalan sendiri begitu runtime desktopnya diperbarui atau saat diuji on-device.

PRAPROSES DAN GERBANGNYA SENGAJA DISALIN PERSIS dari
lib/services/money_tflite_service.dart. Kalau salah satunya diubah, ubah
keduanya - kalau tidak, skrip ini mengukur pipeline yang tidak pernah
dijalankan siapa pun.

Pakai:
    python3 -m venv .venv && .venv/bin/pip install ai-edge-litert pillow numpy
    .venv/bin/python tool/eval_rupiah_litert.py [kamera|jpeg]

`kamera` (bawaan) meniru _prepareInput: YUV420 4:2:0 + nearest neighbour,
yaitu yang benar-benar berjalan di ponsel. `jpeg` meniru _prepareJpeg.
"""
import os
import sys

import numpy as np
from PIL import Image

try:
    from ai_edge_litert.interpreter import Interpreter
except ImportError:
    sys.exit('Butuh LiteRT modern. Pasang dengan: pip install ai-edge-litert pillow numpy')

SIZE = 224
CLASSES = [1000, 2000, 5000, 10000, 20000, 50000, 100000]

# Harus sama dengan konstanta di MoneyTFLiteService.
CONF_THRESHOLD = 0.85
MARGIN_THRESHOLD = 0.50
MARGIN_MIN_CONF = 0.80

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL = os.path.join(HERE, 'assets/models/rupiah_classifier_int8.tflite')
FIXTURES = os.path.join(HERE, 'test/fixtures/rupiah_mobile')


def letterbox_normalize_jpeg(path):
    """Tiru `_prepareJpeg` di Dart: decode, letterbox BILINEAR, x/127,5-1.

    Ini jalur tombol "paksa deteksi ulang", BUKAN jalur kamera langsung.
    """
    im = Image.open(path).convert('RGB')
    w, h = im.size
    scale = min(SIZE / w, SIZE / h)
    dw, dh = max(1, round(w * scale)), max(1, round(h * scale))
    im = im.resize((dw, dh), Image.BILINEAR)
    canvas = np.full((SIZE, SIZE, 3), -1.0, dtype=np.float32)
    px, py = (SIZE - dw) // 2, (SIZE - dh) // 2
    canvas[py:py + dh, px:px + dw] = np.asarray(im, dtype=np.float32) / 127.5 - 1.0
    return canvas[None, ...]


def letterbox_normalize_kamera(path):
    """Tiru `_prepareInput` di Dart: JALUR KAMERA yang sesungguhnya.

    Bedanya dengan jalur JPEG BUKAN kosmetik, dan inilah yang benar-benar
    berjalan di ponsel:

    1. Frame datang sebagai YUV420 dengan kroma 4:2:0 - warna disubsample
       setengah di kedua sumbu, jadi detail warna sudah hilang SEBELUM model
       melihatnya. Uang rupiah dibedakan terutama oleh warna.
    2. Penskalaannya NEAREST NEIGHBOUR (`(ty / scale).floor()`), bukan
       bilinear. Foto 3000x4000 yang diperkecil ke 224 lewat nearest membuang
       hampir seluruh pikselnya tanpa dirata-rata dulu, jadi hasilnya beraliasing
       berat dan berubah-ubah mengikuti getaran tangan.

    Mengukur lewat jalur JPEG memberi angka yang terlalu optimistis.
    """
    im = Image.open(path).convert('RGB')
    a = np.asarray(im, dtype=np.float64)
    h, w = a.shape[:2]
    # Konverter kamera membuang baris/kolom ganjil, sama seperti helper Dart.
    w -= w % 2
    h -= h % 2
    a = a[:h, :w]
    r, g, b = a[..., 0], a[..., 1], a[..., 2]

    # RGB -> YUV420, koefisien BT.601 full-range yang sama dengan helper test.
    y = np.clip(np.round(0.299 * r + 0.587 * g + 0.114 * b), 0, 255)
    u = np.clip(np.round(-0.168736 * r - 0.331264 * g + 0.5 * b + 128), 0, 255)
    v = np.clip(np.round(0.5 * r - 0.418688 * g - 0.081312 * b + 128), 0, 255)

    # Subsampling 4:2:0 - kroma cuma ada di piksel genap, lalu direplikasi 2x2
    # persis seperti pengindeksan `(sy>>1)*uvRowStride + (sx>>1)*uvPixelStride`.
    u = u[0::2, 0::2].repeat(2, axis=0).repeat(2, axis=1)[:h, :w]
    v = v[0::2, 0::2].repeat(2, axis=0).repeat(2, axis=1)[:h, :w]

    scale = min(SIZE / w, SIZE / h)
    dw, dh = max(1, round(w * scale)), max(1, round(h * scale))
    px, py = (SIZE - dw) // 2, (SIZE - dh) // 2

    # Nearest neighbour, sama dengan `.floor()` di Dart.
    sy = np.clip(np.floor(np.arange(dh) / scale).astype(int), 0, h - 1)
    sx = np.clip(np.floor(np.arange(dw) / scale).astype(int), 0, w - 1)
    yy = y[np.ix_(sy, sx)]
    uu = u[np.ix_(sy, sx)] - 128.0
    vv = v[np.ix_(sy, sx)] - 128.0

    canvas = np.full((SIZE, SIZE, 3), -1.0, dtype=np.float32)
    canvas[py:py + dh, px:px + dw, 0] = np.clip(yy + 1.402 * vv, 0, 255) / 127.5 - 1.0
    canvas[py:py + dh, px:px + dw, 1] = np.clip(
        yy - 0.344136 * uu - 0.714136 * vv, 0, 255) / 127.5 - 1.0
    canvas[py:py + dh, px:px + dw, 2] = np.clip(yy + 1.772 * uu, 0, 255) / 127.5 - 1.0
    return canvas[None, ...]


def ground_truth(folder, name):
    """None berarti HARUS DITOLAK, bukan 'tidak diketahui'."""
    if folder == 'non_rupiah':
        return None
    if folder == '20_ribuan':
        return 20000
    for prefix, value in [('100_ribu', 100000), ('50_ribu', 50000),
                          ('20_ribu', 20000), ('10_ribu', 10000),
                          ('5_ribu', 5000), ('2_ribu', 2000), ('1_ribu', 1000)]:
        if name.lower().startswith(prefix):
            return value
    return None


def yakin(conf, margin):
    """Gerbang yang sama dengan MoneyTFLiteService.

    Sejak gerbang berhenti menahan jawaban, fungsi ini TIDAK lagi menentukan
    diumumkan atau tidak - nominal selalu diumumkan. Yang ditentukannya adalah
    NADA: lolos berarti dibacakan lugas, gagal berarti dibacakan berpagar
    ("Sepertinya ..."). Lihat MoneyResult.certain.
    """
    return conf >= CONF_THRESHOLD or (margin >= MARGIN_THRESHOLD
                                      and conf >= MARGIN_MIN_CONF)


def rp(v):
    return 'Rp' + f'{v:,}'.replace(',', '.')


def main():
    jalur = sys.argv[1] if len(sys.argv) > 1 else 'kamera'
    if jalur not in ('kamera', 'jpeg'):
        sys.exit("Jalur harus 'kamera' (bawaan, seperti di ponsel) atau 'jpeg'.")
    prep = letterbox_normalize_kamera if jalur == 'kamera' else letterbox_normalize_jpeg
    if not os.path.isdir(FIXTURES):
        sys.exit(f'Folder {FIXTURES} tidak ada (di-gitignore).\n'
                 f'Salin dengan: cp -r ../../test/rupiah/. test/fixtures/rupiah_mobile/')

    interp = Interpreter(model_path=MODEL)
    interp.allocate_tensors()
    inp = interp.get_input_details()[0]
    out = interp.get_output_details()[0]

    cases = []
    for folder in sorted(os.listdir(FIXTURES)):
        d = os.path.join(FIXTURES, folder)
        if not os.path.isdir(d):
            continue
        for name in sorted(os.listdir(d)):
            if name.lower().endswith(('.png', '.jpg', '.jpeg')):
                cases.append((folder, name, os.path.join(d, name)))

    rows = []
    for folder, name, path in cases:
        interp.set_tensor(inp['index'], prep(path))
        interp.invoke()
        p = interp.get_tensor(out['index'])[0].astype(np.float64)
        order = np.argsort(-p)
        conf = float(p[order[0]])
        margin = conf - float(p[order[1]])
        rows.append(dict(label=f'{folder}/{name}', gt=ground_truth(folder, name),
                         top=CLASSES[order[0]], conf=conf, margin=margin,
                         yakin=yakin(conf, margin)))

    rows.sort(key=lambda r: -r['conf'])
    bar = '═' * 92
    print(f'\n{bar}')
    print(f'  EVALUASI FOTO PONSEL - jalur {jalur.upper()} - gerbang NADA '
          f'conf>={CONF_THRESHOLD} / margin>={MARGIN_THRESHOLD} / '
          f'minConf={MARGIN_MIN_CONF}')
    print('  Semua baris DIUMUMKAN. Gerbang cuma memilih lugas vs berpagar.')
    print(bar)

    benar_yakin = benar_pagar = 0
    salah_yakin = salah_pagar = 0
    bocor_yakin = bocor_pagar = 0
    n_uang = sum(1 for r in rows if r['gt'] is not None)
    for r in rows:
        gt = 'BUKAN UANG' if r['gt'] is None else rp(r['gt'])
        nada = 'yakin   ' if r['yakin'] else 'berpagar'
        if r['gt'] is None:
            vonis = 'BOCOR - bukan uang disebut nominal'
            if r['yakin']:
                bocor_yakin += 1
            else:
                bocor_pagar += 1
        elif r['top'] == r['gt']:
            vonis = 'benar'
            if r['yakin']:
                benar_yakin += 1
            else:
                benar_pagar += 1
        else:
            vonis = 'SALAH'
            if r['yakin']:
                salah_yakin += 1
            else:
                salah_pagar += 1
        print(f"  {r['label']:<28} {gt:>10}  top={rp(r['top']):>10}  "
              f"conf={r['conf']*100:5.1f}%  margin={r['margin']*100:5.1f}  "
              f"{nada}  {vonis}")

    print('─' * 92)
    print(f'  benar, nada yakin      : {benar_yakin}/{n_uang} gambar uang')
    print(f'  benar, berpagar        : {benar_pagar}/{n_uang}')
    print(f'  SALAH dengan nada yakin: {salah_yakin}   (harus 0 - ini satu-satunya'
          f' angka yang boleh memerahkan skrip ini)')
    print(f'  salah tapi berpagar    : {salah_pagar}   (risiko yang sengaja'
          f' diterima saat gerbang berhenti menahan jawaban)')
    print(f'  bukan uang, nada yakin : {bocor_yakin}')
    print(f'  bukan uang, berpagar   : {bocor_pagar}')
    print(bar + '\n')
    return 1 if salah_yakin else 0


if __name__ == '__main__':
    sys.exit(main())
