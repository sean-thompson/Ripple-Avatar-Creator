"""Synthesise the HUD's swipe sounds (our own, no licence concerns).

Usage: python tools/build_swipes.py [out_dir]   (default assets/ui/sounds)

Soft filtered-noise sweeps with a faint sine glide, voiced to sit with the
ObsydianX style-3 tones: smooth attack, no harsh top end.
  worldIn.wav   World options slides on   (sweep up)
  worldOut.wav  World options slides off  (sweep down)
  switch.wav    switching Catalogue / Stores / Outfits (short, brighter)
Needs: pip install numpy scipy
"""

import os
import sys

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt

SR = 44100


def sweep(duration, f_start, f_end, tone_start, tone_end, tone_level, brightness=1.0, seed=1):
    n = int(SR * duration)
    t = np.arange(n) / SR
    rng = np.random.default_rng(seed)
    noise = rng.standard_normal(n)

    # Band-pass the noise in short blocks while its centre glides (log-spaced).
    centres = np.geomspace(f_start, f_end, 64)
    out = np.zeros(n)
    block = int(np.ceil(n / len(centres)))
    window = np.hanning(block * 2)
    for i, centre in enumerate(centres):
        lo, hi = centre / 1.6, min(centre * 1.6, SR / 2 - 100)
        sos = butter(2, [lo, hi], btype="band", fs=SR, output="sos")
        start = max(0, i * block - block // 2)
        stop = min(n, start + block * 2)
        filtered = sosfilt(sos, noise[start:stop])
        out[start:stop] += filtered * window[: stop - start]

    # Faint sine glide gives the sweep a pitch, like a synth "swish".
    phase = 2 * np.pi * np.cumsum(np.geomspace(tone_start, tone_end, n)) / SR
    tone = np.sin(phase) * tone_level

    signal = out / (np.max(np.abs(out)) or 1) * 0.8 + tone
    # Gentle top-end roll-off keeps it soft.
    sos = butter(2, 6500 * brightness, btype="low", fs=SR, output="sos")
    signal = sosfilt(sos, signal)

    # Envelope: soft rise, longer fall (reads as motion, not a hit).
    attack = int(n * 0.35)
    env = np.concatenate([np.sin(np.linspace(0, np.pi / 2, attack)) ** 2, np.cos(np.linspace(0, np.pi / 2, n - attack)) ** 2])
    signal = signal * env
    return signal / (np.max(np.abs(signal)) or 1) * 0.7


def write(path, signal):
    stereo = np.stack([signal, signal], axis=1)
    wavfile.write(path, SR, (stereo * 32767).astype(np.int16))
    print(f"Wrote {path} ({len(signal) / SR:.2f}s)")


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "assets/ui/sounds"
    os.makedirs(out_dir, exist_ok=True)
    write(os.path.join(out_dir, "worldIn.wav"), sweep(0.34, 700, 3600, 520, 1040, 0.12, seed=3))
    write(os.path.join(out_dir, "worldOut.wav"), sweep(0.30, 3600, 650, 1040, 520, 0.12, seed=4))
    write(os.path.join(out_dir, "switch.wav"), sweep(0.18, 1400, 4200, 1040, 1560, 0.10, brightness=1.2, seed=5))


if __name__ == "__main__":
    main()
