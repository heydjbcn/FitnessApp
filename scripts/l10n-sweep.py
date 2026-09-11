#!/usr/bin/env python3
"""Literales que parecen texto de pantalla y no están en el catálogo de la app."""
import json, re, pathlib, sys
exec(open(pathlib.Path(__file__).with_name("l10n-wrap.py")).read().replace("\nmain()\n", "\n"))
cat = json.loads(pathlib.Path("FitnessApp/Localizable.xcstrings").read_text())["strings"]
have = {k for k, v in cat.items() if v.get("localizations")}
SKIPF = ("AICoachManager", "OnDeviceCoach", "CoachToolStream", "AppDefaults", "Keychain", "TechniquePhotos",
         "ExerciseVideos", "VoiceCommandParser", "AppLanguage", "Testing.swift", "ChamaFitShortcuts")
IDENT = re.compile(r"^([a-z][A-Za-z0-9]*(\.[A-Za-z0-9\\()]+)+|#[0-9A-F]{6}|[A-Z][a-z]+[A-Z]\w*|[a-z]+_[a-z_0-9]+|[a-z]{2}-[A-Z]{2}|%\S*|[\W\d_]+)$")
out = set()
for f in sorted(pathlib.Path("FitnessApp").glob("*.swift")):
    if any(x in f.name for x in SKIPF): continue
    s = f.read_text()
    for st, en, content, interp in scan_strings(s):
        if interp or content in have or IDENT.match(content) or not re.search(r"[A-Za-zÁÉÍÓÚáéíóúñÑ]{2,}", content):
            continue
        ls = s.rfind("\n", 0, st) + 1
        before = s[ls:st]
        if SKIP_BEFORE.search(before) or s[en:en + 2].lstrip().startswith(":"): continue
        if re.fullmatch(r"\s*case\s+(\.?\w+\s*=\s*)?", before) or re.search(r"\bcase\s+\w+\s*=\s*$", before): continue
        out.add(content)
print(len(out))
json.dump(sorted(out), open(sys.argv[1] if len(sys.argv) > 1 else "/tmp/l10n-left.json", "w"), ensure_ascii=False, indent=1)
