"""Detekce dob v písni (BPM, offset, úseky mimo mřížku).

Použití:
    python tools/analyze_beats.py songs/incienso.mp3 [--bpm 130]

Potřebuje jen numpy a soundfile (librosa na tomto PC blokuje Smart App Control):
    python -m venv C:/claude/tools/py-audio
    C:/claude/tools/py-audio/Scripts/python -m pip install numpy soundfile

Postup: spektrální flux -> tempo z autokorelace -> DP beat tracker (Ellis 2007)
-> robustní proložení pevnou mřížkou. Která doba je „1“, se pozná jen odhadem
(profil energie po dobách), je potřeba ji ověřit poslechem v editoru písně.
"""

import argparse
import sys

import numpy as np
import soundfile as sf

HOP = 128
N_FFT = 1024
OUTLIER_S = 0.035


def load_mono(path):
    y, sr = sf.read(path, always_2d=True)
    y = y.mean(axis=1)
    if sr == 44100:  # na 22050 kvůli rychlosti
        y = y[: len(y) // 2 * 2].reshape(-1, 2).mean(axis=1)
        sr = 22050
    return y, sr


def onset_envelope(y, sr):
    frames = np.lib.stride_tricks.sliding_window_view(y, N_FFT)[::HOP] * np.hanning(N_FFT)
    log_spec = np.log1p(100 * np.abs(np.fft.rfft(frames, axis=1)))
    flux = np.concatenate([[0], np.maximum(0, np.diff(log_spec, axis=0)).mean(axis=1)])
    fps = sr / HOP
    k = int(fps * 0.5)
    oenv = np.maximum(0, flux - np.convolve(flux, np.ones(k) / k, mode="same"))
    times = (np.arange(len(oenv)) * HOP + N_FFT / 2) / sr
    return oenv / oenv.std(), fps, times


def tempo_period(oenv, fps, bpm_hint):
    """Perioda doby ve snímcích z autokorelace, s vahou kolem bpm_hint."""
    ac = np.correlate(oenv, oenv, mode="full")[len(oenv) - 1:]
    lags = np.arange(len(ac))
    bpm = 60 * fps / np.maximum(lags, 1)
    cand = np.where((bpm > 60) & (bpm < 200))[0]
    weight = np.exp(-0.5 * (np.log2(bpm[cand] / bpm_hint) / 0.5) ** 2)
    best = cand[np.argmax(ac[cand] * weight)]
    y0, y1, y2 = ac[best - 1: best + 2]
    return best + 0.5 * (y0 - y2) / (y0 - 2 * y1 + y2)


def track_beats(oenv, period, times, fps, alpha=400.0):
    score = oenv.copy()
    back = np.full(len(oenv), -1)
    lo, hi = int(round(period / 2)), int(round(2 * period))
    for i in range(hi, len(oenv)):
        prev = np.arange(i - hi, i - lo)
        c = score[prev] - alpha * np.log((i - prev) / period) ** 2
        j = np.argmax(c)
        score[i] = oenv[i] + c[j]
        back[i] = prev[j]
    i = len(oenv) - hi + np.argmax(score[-hi:])
    beats = []
    while i >= 0:
        beats.append(i)
        i = back[i]
    out = []
    for b in beats[::-1]:  # zpřesnění parabolou
        shift = 0.0
        if 0 < b < len(oenv) - 1:
            a0, a1, a2 = oenv[b - 1: b + 2]
            d = a0 - 2 * a1 + a2
            if d < 0:
                shift = 0.5 * (a0 - a2) / d
        out.append(times[b] + shift / fps)
    return np.array(out)


def fit_grid(beats):
    """Pevná mřížka t = a + b·n, doby dál než OUTLIER_S se vyřadí."""
    n = np.arange(len(beats))
    keep = np.ones(len(beats), bool)
    for _ in range(5):
        b, a = np.polyfit(n[keep], beats[keep], 1)
        res = beats - (a + b * n)
        keep = np.abs(res) < OUTLIER_S
    return a, b, res, keep


def outlier_ranges(beats, keep):
    """Souvislé úseky vyřazených dob jako (od, do, počet)."""
    ranges = []
    for t, k in zip(beats, keep):
        if k:
            continue
        if ranges and t - ranges[-1][1] < 1.5:
            ranges[-1] = (ranges[-1][0], t, ranges[-1][2] + 1)
        else:
            ranges.append((t, t, 1))
    return ranges


def band_profile(y, sr, grid, lo, hi):
    """Medián energie pásma v okně za dobou, po pozicích 0–7 v cyklu."""
    w = int(0.08 * sr)
    energies = []
    for t in grid:
        i = int(t * sr)
        seg = y[max(0, i - w // 4): i + w]
        spec = np.abs(np.fft.rfft(seg * np.hanning(len(seg)))) ** 2
        f = np.fft.rfftfreq(len(seg), 1 / sr)
        energies.append(spec[(f >= lo) & (f < hi)].sum())
    e = np.array(energies)
    prof = np.array([np.median(e[k::8]) for k in range(8)])
    return prof / prof.max()


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("mp3")
    p.add_argument("--bpm", type=float, default=130, help="přibližné tempo (nápověda pro detekci)")
    args = p.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")

    y, sr = load_mono(args.mp3)
    oenv, fps, times = onset_envelope(y, sr)
    period = tempo_period(oenv, fps, args.bpm)
    beats = track_beats(oenv, period, times, fps)
    a, b, res, keep = fit_grid(beats)
    spb = b
    print("délka %.1f s, detekováno %d dob, tempo z autokorelace %.2f BPM" % (len(y) / sr, len(beats), 60 * fps / period))
    print("mřížka: %.3f BPM, první doba %.1f ms, sedí %d/%d dob, odchylka ±%.1f ms"
          % (60 / spb, a * 1000, keep.sum(), len(beats), res[keep].std() * 1000))

    print("\nlokální tempo po 16 dobách:")
    row = []
    for i in range(0, len(beats) - 16, 16):
        seg = beats[i:i + 17]
        row.append("%6.1f s %6.2f" % (seg[0], 60 / np.polyfit(np.arange(len(seg)), seg, 1)[0]))
    for i in range(0, len(row), 4):
        print("  " + " | ".join(row[i:i + 4]))

    print("\núseky mimo mřížku (kandidáti na break / stop, doba od první doby):")
    for t0, t1, cnt in outlier_ranges(beats, keep):
        if cnt >= 3:
            print("  %6.1f–%6.1f s  doby %d–%d" % (t0, t1, round((t0 - a) / spb), round((t1 - a) / spb)))

    print("\nprofil energie po pozicích v cyklu (0 = první doba, vyšší = výraznější):")
    grid = a + spb * np.arange(0, int((len(y) / sr - a) / spb))
    for name, lo, hi in [("basy 30–120 Hz", 30, 120), ("středy 200–2k", 200, 2000), ("výšky 4k–12k", 4000, 12000)]:
        prof = band_profile(y, sr, grid, lo, hi)
        print("  %-15s %s" % (name, " ".join("%d:%.2f" % (k, v) for k, v in enumerate(prof))))

    print("\ndo JSON písně: \"bpm\": %s, \"offset_ms\": %d + k × %.1f (k = posun na „1“)"
          % (round(60 / spb, 2), round(a * 1000), spb * 1000))


if __name__ == "__main__":
    main()
