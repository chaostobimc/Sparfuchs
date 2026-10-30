#!/usr/bin/env python3
"""Generates all .wav sound assets for The Diplomat Peak.
Pure-Python (wave + struct + math), no external deps.
Run:  python3 scripts/audio_gen.py
Output: assets/audio/*.wav  (16-bit PCM mono, 44100 Hz)
"""
import wave, struct, math, random, os

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
os.makedirs(OUT, exist_ok=True)
random.seed(1234)

def write_wav(name, samples):
    path = os.path.join(OUT, name + ".wav")
    w = wave.open(path, "w")
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    frames = bytearray()
    for s in samples:
        v = max(-1.0, min(1.0, s))
        frames += struct.pack("<h", int(v * 32767))
    w.writeframes(bytes(frames))
    w.close()
    print("wrote", path, len(samples), "samples")

def noise(n):
    return [random.uniform(-1.0, 1.0) for _ in range(n)]

def lowpass(xs, f=0.5):
    # simple one-pole low-pass
    out = []
    y = 0.0
    for x in xs:
        y = y * f + x * (1.0 - f)
        out.append(y)
    return out

def highpass(xs, f=0.5):
    # subtract lowpass
    lp = lowpass(xs, f)
    return [xs[i] - lp[i] for i in range(len(xs))]

def env_attack_decay(n, attack=0.02, decay=0.3):
    a = int(SR * attack)
    d = int(SR * decay)
    e = []
    for i in range(n):
        if i < a:
            e.append(i / a)
        elif i < a + d:
            e.append(1.0 - (i - a) / d)
        else:
            e.append(0.0)
    return e

def fade(xs, ms=50):
    n = len(xs)
    k = int(SR * ms / 1000.0)
    k = min(k, n // 2)
    for i in range(k):
        xs[i] *= i / k
        xs[n - 1 - i] *= i / k
    return xs

# --- ambient drone (loopable, 8s) ---
def gen_ambient():
    n = SR * 8
    xs = [0.0] * n
    for i in range(n):
        t = i / SR
        v = (math.sin(2 * math.pi * 50 * t) * 0.5
             + math.sin(2 * math.pi * 55 * t) * 0.4
             + math.sin(2 * math.pi * 75 * t) * 0.2
             + math.sin(2 * math.pi * 30 * t) * 0.3)
        # slow amplitude modulation
        v *= 0.6 + 0.4 * math.sin(2 * math.pi * 0.1 * t)
        # faint hiss
        v += random.uniform(-1, 1) * 0.015
        xs[i] = v * 0.25
    return fade(xs, 80)

# --- rain (loopable, 6s) ---
def gen_rain():
    n = SR * 6
    xs = noise(n)
    xs = lowpass(xs, 0.55)
    xs = highpass(xs, 0.25)
    # random droplet pops
    for _ in range(400):
        i = random.randint(0, n - 1)
        xs[i] += random.uniform(0.3, 0.6)
    for i in range(n):
        xs[i] *= 0.5
    return fade(xs, 60)

# --- thunder (3s) ---
def gen_thunder():
    n = SR * 3
    xs = noise(n)
    xs = lowpass(xs, 0.4)
    e = env_attack_decay(n, attack=0.01, decay=2.8)
    for i in range(n):
        xs[i] = xs[i] * e[i] * 0.9 + math.sin(2 * math.pi * 45 * i / SR) * e[i] * 0.3
    return xs

# --- scream (jumpscare, 1.4s) ---
def gen_scream():
    n = int(SR * 1.4)
    xs = [0.0] * n
    for i in range(n):
        t = i / SR
        # downward pitch sweep
        f = 900 * math.exp(-3.5 * t) + 80
        v = math.sin(2 * math.pi * f * t) * 0.8
        # noise component
        v += random.uniform(-1, 1) * 0.5
        # distortion (hard clip)
        v = math.tanh(v * 3.0)
        e = 1.0 if t < 0.02 else math.exp(-2.0 * t)
        xs[i] = v * e * 0.9
    return xs

# --- short SFX helpers ---
def click_snd(dur=0.05, freq=1800, amp=0.6):
    n = int(SR * dur)
    xs = [0.0] * n
    e = env_attack_decay(n, attack=0.001, decay=dur)
    for i in range(n):
        xs[i] = math.sin(2 * math.pi * freq * i / SR) * e[i] * amp
    return xs

def metallic(dur=0.12, amp=0.6):
    n = int(SR * dur)
    xs = noise(n)
    xs = highpass(xs, 0.4)
    e = env_attack_decay(n, attack=0.002, decay=dur)
    for i in range(n):
        xs[i] = xs[i] * e[i] * amp + math.sin(2 * math.pi * 2400 * i / SR) * e[i] * amp * 0.4
    return xs

def thud(dur=0.2, freq=80, amp=0.8):
    n = int(SR * dur)
    xs = [0.0] * n
    e = env_attack_decay(n, attack=0.003, decay=dur)
    for i in range(n):
        xs[i] = math.sin(2 * math.pi * freq * i / SR) * e[i] * amp
        xs[i] += random.uniform(-1, 1) * e[i] * amp * 0.3
    return xs

def generator_start(dur=1.0):
    n = int(SR * dur)
    xs = [0.0] * n
    for i in range(n):
        t = i / SR
        e = min(1.0, t / 0.5)  # rise
        v = (math.sin(2 * math.pi * 42 * t) * 0.7
             + math.sin(2 * math.pi * 84 * t) * 0.3
             + random.uniform(-1, 1) * 0.2)
        xs[i] = v * e * 0.5
    return xs

def heartbeat(dur=0.8):
    n = int(SR * dur)
    xs = [0.0] * n
    def beat(start, amp):
        for i in range(int(SR * 0.15)):
            idx = start + i
            if idx < n:
                e = math.exp(-i / (SR * 0.05))
                xs[idx] += math.sin(2 * math.pi * 60 * i / SR) * e * amp
    beat(int(SR * 0.0), 0.9)
    beat(int(SR * 0.28), 0.7)
    return xs

def wind(dur=5.0):
    n = int(SR * dur)
    xs = noise(n)
    xs = lowpass(xs, 0.5)
    # gusts
    for i in range(n):
        t = i / SR
        g = 0.4 + 0.6 * math.sin(2 * math.pi * 0.15 * t) * math.sin(2 * math.pi * 0.07 * t)
        xs[i] *= g * 0.5
    return fade(xs, 80)

def elevator(dur=1.0):
    n = int(SR * dur)
    xs = [0.0] * n
    e = env_attack_decay(n, attack=0.05, decay=0.8)
    for i in range(n):
        t = i / SR
        f = 60 + 30 * math.sin(2 * math.pi * 0.8 * t)
        xs[i] = (math.sin(2 * math.pi * f * t) * 0.6
                 + random.uniform(-1, 1) * 0.4) * e[i] * 0.5
    return xs

def clock_tick(dur=0.04):
    return click_snd(dur, 2600, 0.5)

def door(dur=0.4):
    n = int(SR * dur)
    xs = [0.0] * n
    e = env_attack_decay(n, attack=0.05, decay=0.35)
    for i in range(n):
        t = i / SR
        xs[i] = (math.sin(2 * math.pi * 70 * t) * 0.6
                 + random.uniform(-1, 1) * 0.4) * e[i] * 0.7
    return xs

def gate(dur=0.5):
    n = int(SR * dur)
    xs = [0.0] * n
    e = env_attack_decay(n, attack=0.01, decay=0.45)
    for i in range(n):
        t = i / SR
        xs[i] = (math.sin(2 * math.pi * 55 * t) * 0.7
                 + random.uniform(-1, 1) * 0.5) * e[i] * 0.8
    return xs

def step(dur=0.08):
    return thud(dur, 90, 0.35)

# --- generate all ---
write_wav("ambient", gen_ambient())
write_wav("rain", gen_rain())
write_wav("wind", wind())
write_wav("thunder", gen_thunder())
write_wav("scream", gen_scream())
write_wav("click", click_snd())
write_wav("lock", metallic(0.15, 0.7))
write_wav("lever", metallic(0.18, 0.6))
write_wav("generator", generator_start())
write_wav("elevator", elevator())
write_wav("clock", clock_tick())
write_wav("door", door())
write_wav("gate", gate())
write_wav("heartbeat", heartbeat())
write_wav("step", step())
print("DONE")
