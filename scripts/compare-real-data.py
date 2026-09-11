#!/usr/bin/env python3
"""Compara dos copias de las preferencias de ChamaFit por contenido.

Los diccionarios de Swift se guardan como listas [clave, valor, …] en un
orden que cambia en cada guardado, y los campos nuevos con su valor por
defecto (p. ej. "loadKind": "total") no son un cambio de datos.
"""
import json, plistlib, sys

DEFAULTS = {"loadKind": "total", "videoURL": None, "targetSets": None}

def todict(l):
    return {json.dumps(l[i], sort_keys=True): l[i + 1] for i in range(0, len(l), 2)} if isinstance(l, list) and len(l) % 2 == 0 else l

def norm(x):
    if isinstance(x, dict):
        return {k: norm(v) for k, v in x.items() if not (k in DEFAULTS and v == DEFAULTS[k])}
    if isinstance(x, list):
        return [norm(v) for v in x]
    return x

def load(path):
    d = plistlib.load(open(path, "rb"))
    out = {}
    for k, v in d.items():
        if isinstance(v, (bytes, str)):
            try:
                j = json.loads(v)
                if k in ("BodyWeightHistory", "DailyWorkoutRecords", "SessionNotes", "DayLabels"):
                    j = todict(j)
                if k == "WorkoutHistory":
                    j = {d: todict(byday) for d, byday in todict(j).items()}
                v = j
            except Exception:
                pass
        out[k] = norm(v)
    return out

a, b = load(sys.argv[1]), load(sys.argv[2])
important = ["AvailableExercises", "DailyWorkoutRecords", "WorkoutHistory", "BodyWeightHistory", "Routines", "SessionNotes"]
changed = [k for k in important if a.get(k) != b.get(k)]
other = sorted(k for k in set(a) | set(b) if k not in important and a.get(k) != b.get(k))
if changed:
    print("⚠️ CAMBIAN los datos: " + ", ".join(changed))
    sys.exit(1)
print("intactos por contenido (solo se reguardó)" + (f"; cambian ajustes: {', '.join(other)}" if other else ""))
