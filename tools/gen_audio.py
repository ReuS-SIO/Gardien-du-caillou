"""
Générateur de sons de substitution (style 8-bit) pour Gardiens du Caillou.
Usage :  python tools/gen_audio.py
Produit des WAV 16 bits mono 22050 Hz dans assets/audio/sfx/ et assets/audio/music/.
Ce sont des « mock data » : remplace n'importe quel fichier par le tien (même nom),
ou change les chemins dans scripts/audio_manager.gd.
"""
import os
import wave
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
SFX_DIR = os.path.join(HERE, "..", "assets", "audio", "sfx")
MUSIC_DIR = os.path.join(HERE, "..", "assets", "audio", "music")
os.makedirs(SFX_DIR, exist_ok=True)
os.makedirs(MUSIC_DIR, exist_ok=True)

SR = 22050
rng = np.random.default_rng(7)


# ---------------------------------------------------------------- synthèse de base
def t(dur):
    return np.arange(int(SR * dur)) / SR


def osc(freq, dur, kind="square", sweep_to=None, duty=0.5):
    """Oscillateur simple. freq peut glisser linéairement vers sweep_to."""
    tt = t(dur)
    if sweep_to is None:
        f = np.full_like(tt, float(freq))
    else:
        f = np.linspace(float(freq), float(sweep_to), tt.size)
    phase = np.cumsum(f) / SR
    if kind == "sine":
        return np.sin(2 * np.pi * phase)
    if kind == "square":
        return np.where((phase % 1.0) < duty, 1.0, -1.0)
    if kind == "tri":
        return 2.0 * np.abs(2.0 * (phase % 1.0) - 1.0) - 1.0
    if kind == "saw":
        return 2.0 * (phase % 1.0) - 1.0
    if kind == "noise":
        return rng.uniform(-1.0, 1.0, tt.size)
    raise ValueError(kind)


def env(dur, attack=0.005, decay=None, sustain=1.0, release=0.05):
    """Enveloppe ADSR minimaliste."""
    n = int(SR * dur)
    a = min(n, max(1, int(SR * attack)))
    r = min(n, max(1, int(SR * release)))
    d = min(n - a, int(SR * decay)) if decay else 0
    e = np.ones(n)
    e[:a] = np.linspace(0, 1, a)
    if d:
        end = min(n, a + d)
        e[a:end] = np.linspace(1, sustain, end - a)
        e[end:] = sustain
    e[-r:] *= np.linspace(1, 0, r)
    return e


def lowpass(x, alpha):
    """Filtre passe-bas 1 pôle (alpha proche de 1 = très filtré)."""
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = alpha * acc + (1 - alpha) * v
        y[i] = acc
    return y


def vibrato(freq, dur, depth=0.03, rate=6.0):
    tt = t(dur)
    return freq * (1.0 + depth * np.sin(2 * np.pi * rate * tt))


def osc_curve(freq_curve, kind="saw"):
    phase = np.cumsum(freq_curve) / SR
    if kind == "sine":
        return np.sin(2 * np.pi * phase)
    if kind == "saw":
        return 2.0 * (phase % 1.0) - 1.0
    if kind == "square":
        return np.where((phase % 1.0) < 0.5, 1.0, -1.0)
    return 2.0 * np.abs(2.0 * (phase % 1.0) - 1.0) - 1.0


def normalize(x, peak=0.85):
    m = np.max(np.abs(x)) or 1.0
    return x / m * peak


def save(folder, name, data):
    data = np.clip(data, -1.0, 1.0)
    pcm = (data * 32767).astype("<i2")
    path = os.path.join(folder, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(f"-> {os.path.relpath(path, os.path.join(HERE, '..'))}  ({len(data) / SR:.2f} s)")


def concat(*parts):
    return np.concatenate(parts)


def mix(*parts):
    n = max(p.size for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:p.size] += p
    return out


# ---------------------------------------------------------------- effets sonores
def sfx_jump():
    return normalize(osc(300, 0.14, "square", 720) * env(0.14, decay=0.1, sustain=0.3))


def sfx_double_jump():
    return normalize(osc(500, 0.12, "square", 1000) * env(0.12, decay=0.08, sustain=0.3))


def sfx_attack():
    whoosh = lowpass(osc(0, 0.1, "noise"), 0.7) * env(0.1, attack=0.01, decay=0.08, sustain=0.0)
    tone = osc(900, 0.06, "square", 300) * env(0.06, decay=0.05, sustain=0.0) * 0.5
    return normalize(mix(whoosh, tone))


def sfx_throw():
    whoosh = lowpass(osc(0, 0.25, "noise"), 0.85) * env(0.25, attack=0.02, decay=0.2, sustain=0.0)
    tone = osc(400, 0.25, "tri", 1400) * env(0.25, decay=0.2, sustain=0.0) * 0.4
    return normalize(mix(whoosh, tone))


def sfx_hit_enemy():
    crunch = osc(180, 0.08, "square", 90) * env(0.08, decay=0.06, sustain=0.0)
    noise = osc(0, 0.05, "noise") * env(0.05, decay=0.04, sustain=0.0) * 0.5
    return normalize(mix(crunch, noise))


def sfx_enemy_die():
    fall = osc(700, 0.3, "saw", 90) * env(0.3, decay=0.25, sustain=0.0)
    splat = lowpass(osc(0, 0.2, "noise"), 0.6) * env(0.2, decay=0.18, sustain=0.0) * 0.6
    return normalize(mix(fall, splat))


def sfx_player_hurt():
    return normalize(osc(220, 0.22, "saw", 70) * env(0.22, decay=0.2, sustain=0.0))


def sfx_player_die():
    a = osc(400, 0.9, "square", 50) * env(0.9, decay=0.85, sustain=0.0)
    b = osc(0, 0.5, "noise") * env(0.5, decay=0.45, sustain=0.0) * 0.3
    return normalize(mix(a, b))


def sfx_heal():
    notes = [523, 659, 784]
    parts = [osc(f, 0.12, "sine") * env(0.12, decay=0.1, sustain=0.2) for f in notes]
    return normalize(concat(*parts))


def sfx_respawn():
    notes = [392, 523, 659, 784]
    parts = [osc(f, 0.1, "tri") * env(0.1, decay=0.08, sustain=0.3) for f in notes]
    tail = osc(1046, 0.3, "tri") * env(0.3, decay=0.28, sustain=0.0)
    return normalize(concat(*parts, tail))


def sfx_wave_start():
    a = osc(330, 0.15, "square") * env(0.15, decay=0.1, sustain=0.4)
    b = osc(440, 0.25, "square") * env(0.25, decay=0.2, sustain=0.0)
    return normalize(concat(a, b))


def sfx_wave_clear():
    notes = [523, 659, 784, 1046]
    parts = [osc(f, 0.11, "square", duty=0.3) * env(0.11, decay=0.09, sustain=0.3) for f in notes]
    tail = osc(1046, 0.35, "square", duty=0.3) * env(0.35, decay=0.3, sustain=0.0)
    return normalize(concat(*parts, tail) * 0.9)


def sfx_boss_appear():
    growl = osc_curve(vibrato(55, 1.0, 0.08, 9), "saw") * env(1.0, attack=0.05, decay=0.9, sustain=0.0)
    sub = osc(40, 1.0, "sine", 30) * env(1.0, attack=0.05, decay=0.9, sustain=0.0)
    hiss = lowpass(osc(0, 0.6, "noise"), 0.5) * env(0.6, attack=0.1, decay=0.5, sustain=0.0) * 0.3
    return normalize(mix(growl, sub, hiss))


def sfx_boss_enraged():
    roar = osc_curve(vibrato(110, 0.7, 0.1, 12), "saw") * env(0.7, attack=0.03, decay=0.6, sustain=0.0)
    high = osc(880, 0.3, "square", 440) * env(0.3, decay=0.25, sustain=0.0) * 0.3
    return normalize(mix(roar, high))


def sfx_boss_die():
    fall = osc_curve(np.linspace(300, 30, int(SR * 1.4)), "saw") * env(1.4, decay=1.3, sustain=0.0)
    boom = lowpass(osc(0, 1.0, "noise"), 0.8) * env(1.0, attack=0.02, decay=0.9, sustain=0.0) * 0.7
    return normalize(mix(fall, boom))


def sfx_spit():
    return normalize(osc(600, 0.15, "tri", 200) * env(0.15, decay=0.12, sustain=0.0))


def sfx_splash():
    return normalize(lowpass(osc(0, 0.15, "noise"), 0.5) * env(0.15, decay=0.12, sustain=0.0))


def sfx_javelin_stick():
    thud = osc(120, 0.12, "sine", 60) * env(0.12, decay=0.1, sustain=0.0)
    click = osc(0, 0.03, "noise") * env(0.03, decay=0.02, sustain=0.0) * 0.5
    return normalize(mix(thud, click))


def sfx_upgrade():
    notes = [392, 494, 587, 784, 988]
    parts = [osc(f, 0.13, "tri") * env(0.13, decay=0.1, sustain=0.4) for f in notes]
    chord = mix(osc(784, 0.6, "tri"), osc(988, 0.6, "tri"), osc(1175, 0.6, "tri")) * env(0.6, decay=0.55, sustain=0.0) / 3
    return normalize(concat(*parts, chord))


def sfx_victory():
    notes = [523, 523, 523, 659, 784, 1046]
    durs = [0.12, 0.12, 0.12, 0.25, 0.25, 0.6]
    parts = [osc(f, d, "square", duty=0.4) * env(d, decay=d * 0.9, sustain=0.2) for f, d in zip(notes, durs)]
    return normalize(concat(*parts) * 0.9)


def sfx_ui_click():
    return normalize(osc(880, 0.05, "square", 660) * env(0.05, decay=0.04, sustain=0.0))


def sfx_ui_hover():
    return normalize(osc(1200, 0.03, "tri") * env(0.03, decay=0.02, sustain=0.0) * 0.5)


def sfx_charge_windup():
    return normalize(osc(150, 0.4, "square", 450) * env(0.4, decay=0.35, sustain=0.2) * 0.7)


def sfx_slam():
    boom = osc(90, 0.5, "sine", 30) * env(0.5, attack=0.01, decay=0.45, sustain=0.0)
    noise = lowpass(osc(0, 0.3, "noise"), 0.7) * env(0.3, decay=0.25, sustain=0.0) * 0.6
    return normalize(mix(boom, noise))


SFX = {
    "jump": sfx_jump, "double_jump": sfx_double_jump, "attack": sfx_attack, "throw": sfx_throw,
    "hit_enemy": sfx_hit_enemy, "enemy_die": sfx_enemy_die, "player_hurt": sfx_player_hurt,
    "player_die": sfx_player_die, "heal": sfx_heal, "respawn": sfx_respawn,
    "wave_start": sfx_wave_start, "wave_clear": sfx_wave_clear, "boss_appear": sfx_boss_appear,
    "boss_enraged": sfx_boss_enraged, "boss_die": sfx_boss_die, "spit": sfx_spit, "splash": sfx_splash,
    "javelin_stick": sfx_javelin_stick, "upgrade": sfx_upgrade, "victory": sfx_victory,
    "ui_click": sfx_ui_click, "ui_hover": sfx_ui_hover, "charge_windup": sfx_charge_windup, "slam": sfx_slam,
}

for name, fn in SFX.items():
    save(SFX_DIR, name, fn())


# ---------------------------------------------------------------- musiques (boucles chiptune)
def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12.0)


PENTA_MAJ = [0, 2, 4, 7, 9]
PENTA_MIN = [0, 3, 5, 7, 10]
DORIAN = [0, 2, 3, 5, 7, 9, 10]


def drum_kick(dur=0.18):
    return osc(150, dur, "sine", 40) * env(dur, attack=0.002, decay=dur * 0.9, sustain=0.0)


def drum_snare(dur=0.14):
    return mix(lowpass(osc(0, dur, "noise"), 0.3) * 0.8, osc(200, dur, "tri", 120) * 0.4) * env(dur, decay=dur * 0.9, sustain=0.0)


def drum_hat(dur=0.05):
    return osc(0, dur, "noise") * env(dur, decay=dur * 0.8, sustain=0.0) * 0.35


def make_track(seed, root, bpm, scale, bars=8, toxic=0.0, lead_kind="square", calm=False):
    """Boucle : basse + accords + mélodie pentatonique aléatoire + batterie. toxic ajoute un lead désaccordé."""
    r = np.random.default_rng(seed)
    beat = 60.0 / bpm
    step = beat / 2  # croches
    total = int(SR * beat * 4 * bars)
    out = np.zeros(total + SR)

    def add(sig, start_s, gain=1.0):
        s = int(start_s * SR)
        n = min(sig.size, out.size - s)
        if n > 0:
            out[s:s + n] += sig[:n] * gain

    progression = [0, 0, -4, -2] if not calm else [0, -2, -4, -5]  # degrés de basse (demi-tons)
    for bar in range(bars):
        bar_t = bar * beat * 4
        bass_root = root + progression[bar % 4]
        # basse : deux notes par temps
        for b in range(8):
            f = midi(bass_root - 12 + (0 if b % 4 != 3 else 7))
            note = osc(f, step * 0.9, "tri" if calm else "square", duty=0.25) * env(step * 0.9, decay=step * 0.8, sustain=0.3)
            add(note, bar_t + b * step, 0.35)
        # nappe d'accord
        chord = [bass_root, bass_root + 3 if scale is PENTA_MIN else bass_root + 4, bass_root + 7]
        pad = sum(osc(midi(n), beat * 4, "tri") for n in chord) / 3 * env(beat * 4, attack=0.2, release=0.3)
        add(pad, bar_t, 0.18)
        # mélodie : marche aléatoire sur la gamme
        degree = r.integers(0, len(scale))
        octave = 1
        for s in range(16):
            if r.random() < (0.55 if calm else 0.75):
                degree = int(np.clip(degree + r.integers(-2, 3), 0, len(scale) - 1))
                if r.random() < 0.15:
                    octave = 2 if octave == 1 else 1
                f = midi(root + scale[degree] + 12 * octave)
                dur = step * (2 if r.random() < 0.3 else 1) * 0.9
                lead = osc(f, dur, lead_kind, duty=0.5) * env(dur, decay=dur * 0.7, sustain=0.5)
                add(lead, bar_t + s * step / 2 * 1.0 if False else bar_t + s * step * 0.5, 0.22)
                if toxic > 0:
                    det = osc(f * (1 + 0.012 * toxic), dur, "saw") * env(dur, decay=dur * 0.7, sustain=0.4)
                    add(det, bar_t + s * step * 0.5, 0.12 * toxic)
        # batterie
        if not calm:
            for b in range(4):
                add(drum_kick(), bar_t + b * beat, 0.9 if b in (0, 2) else 0.5)
                if b in (1, 3):
                    add(drum_snare(), bar_t + b * beat, 0.6)
            for b in range(8):
                add(drum_hat(), bar_t + b * step, 0.5 if b % 2 == 0 else 0.3)
        else:
            for b in range(4):
                add(drum_hat(0.08), bar_t + b * beat, 0.25)
    loop = out[:total]
    # léger passe-bas pour adoucir les carrés
    loop = lowpass(loop, 0.35)
    return normalize(loop, 0.8)


MUSIC = {
    "menu":   dict(seed=1, root=57, bpm=84, scale=PENTA_MAJ, toxic=0.0, lead_kind="tri", calm=True),
    "zone_0": dict(seed=11, root=60, bpm=112, scale=PENTA_MAJ, toxic=0.0, lead_kind="square"),
    "zone_1": dict(seed=12, root=58, bpm=118, scale=PENTA_MIN, toxic=0.3, lead_kind="square"),
    "zone_2": dict(seed=13, root=62, bpm=124, scale=PENTA_MIN, toxic=0.6, lead_kind="square"),
    "zone_3": dict(seed=14, root=55, bpm=130, scale=DORIAN, toxic=0.9, lead_kind="saw"),
    "zone_4": dict(seed=15, root=53, bpm=138, scale=DORIAN, toxic=1.2, lead_kind="saw"),
    "boss":   dict(seed=21, root=50, bpm=150, scale=PENTA_MIN, toxic=1.0, lead_kind="saw"),
}

for name, params in MUSIC.items():
    save(MUSIC_DIR, name, make_track(**params))

print("Terminé.")
