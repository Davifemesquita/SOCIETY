#!/usr/bin/env python3
"""Gera assets/audio/sfx/cannon_1.wav e cannon_2.wav: o tiro de canhão do combate naval (Fase 11).

Som próprio, sem arquivo de terceiros: um estalo de ruído branco que decai rápido, passado por um
filtro passa-baixa de um polo, mais um ronco grave (seno de 55 a 35 Hz) que some devagar. Só stdlib.
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
SECONDS = 1.6


def cannon(seed: int) -> list[float]:
    rng = random.Random(seed)
    samples = []
    low = 0.0
    for i in range(int(RATE * SECONDS)):
        t = i / RATE
        crack = rng.uniform(-1.0, 1.0) * math.exp(-t * 18.0)
        # passa-baixa que vai fechando: o estalo vira estrondo
        alpha = 0.35 * math.exp(-t * 3.0) + 0.04
        low += alpha * (crack - low)
        freq = 35.0 + 20.0 * math.exp(-t * 4.0)
        rumble = math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 2.6) * 0.55
        tail = rng.uniform(-1.0, 1.0) * math.exp(-t * 2.2) * 0.06
        samples.append(low * 1.8 + rumble + tail)
    peak = max(abs(s) for s in samples) or 1.0
    return [s / peak * 0.9 for s in samples]


def main() -> None:
    out = Path(__file__).resolve().parent.parent / "assets" / "audio" / "sfx"
    for index, seed in enumerate((1803, 1840), start=1):
        path = out / f"cannon_{index}.wav"
        with wave.open(str(path), "wb") as file:
            file.setnchannels(1)
            file.setsampwidth(2)
            file.setframerate(RATE)
            file.writeframes(b"".join(struct.pack("<h", int(s * 32767)) for s in cannon(seed)))
        print(path)


if __name__ == "__main__":
    main()
