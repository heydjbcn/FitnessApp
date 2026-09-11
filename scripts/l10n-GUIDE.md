# Traducción de ChamaFit (app de gimnasio para iPhone): español → inglés y catalán

Cada clave es un texto en español de la interfaz (botones, títulos, avisos, frases de Siri, técnica de ejercicios, errores habituales, notas de programas). Tradúcelo a **inglés (en)** y **catalán (ca)**.

## Salida
Un JSON: `{ "clave española exacta": { "en": "…", "ca": "…" }, … }` con TODAS las claves del lote, en el fichero que se te indique. Sin comentarios ni texto fuera del JSON. JSON válido (escapa comillas y barras).

## Reglas
- **Marcadores**: conserva exactamente `%@`, `%lld`, `%lf`, `%d`, `%1$@`, `%2$lld`… (mismo número y tipo). Si el orden cambia en la frase, usa posicionales (`%2$@ … %1$lld`). `%%` es un `%` literal: mantenlo.
- Conserva emojis, `·`, `→`, `×`, `…`, saltos de línea `\n`, y unidades `kg`, `lb`, `min`, `s`, `ml`, `kcal`, `g`.
- Comillas «» españolas: en inglés usa “ ”; en catalán mantén «».
- Tono: cercano, de tú, frases cortas de app. Inglés británico neutro está bien (o americano, pero coherente). Catalán estándar, de tu (no de vostè).
- Siglas y términos que NO se traducen: RPE, RIR, 1RM, HIIT, AMRAP, EMOM, Tabata, PR (en inglés "PR"; en español ponía "Récord"), Face pull, Pallof press, Dead bug, Bird dog, Hip thrust, Burpees, Jumping jacks, Russian twist, Swing (kettlebell), Full body, ChamaFit, Dieta (nombre de otra app), Apple Intelligence, Claude, Anthropic, iCloud, Salud (en inglés "Health", en catalán "Salut" — es la app Salud de Apple), Spotify, YouTube, Siri, Tailscale, Open Food Facts.
- Nombres de ejercicios: el nombre habitual en gimnasios. Inglés: Press de banca → Bench press; Press inclinado mancuernas → Incline dumbbell press; Aperturas → Dumbbell fly; Fondos → Dips; Flexiones → Push-ups; Dominadas → Pull-ups; Remo con barra → Barbell row; Jalón al pecho → Lat pulldown; Peso muerto → Deadlift; Peso muerto rumano → Romanian deadlift; Press militar → Overhead press; Elevaciones laterales → Lateral raises; Pájaros → Rear delt fly; Sentadilla → Squat; Sentadilla goblet → Goblet squat; Sentadilla búlgara → Bulgarian split squat; Prensa → Leg press; Zancadas → Lunges; Gemelos de pie → Standing calf raise; Plancha → Plank; Crunch → Crunch; Cinta de correr → Treadmill; Elíptica → Elliptical; Remo (cardio) → Rowing machine; Subida al banco → Step-up; Rueda abdominal → Ab wheel; Escaladores → Mountain climbers; Comba → Jump rope; Gato-camello → Cat-cow; Movilidad de cadera 90/90 → 90/90 hip mobility… Catalán: Press de banca, Premsa, Esquat (Sentadilla → Esquat), Pes mort, Rem amb barra, Dominades, Flexions, Fons, Planxa, Gambades (Zancadas), Bessons (Gemelos), Corda (Comba), etc.
- Glosario de la app (en / ca):
  - serie(s) → set(s) / sèrie(s); repeticiones / reps → reps / repeticions (reps); descanso → rest / descans
  - rutina → routine / rutina; sesión → session / sessió; entreno / entrenamiento → workout / entrenament
  - récord → PR (personal record) / rècord; tonelaje → volume / volum; racha → streak / ratxa
  - Inicio → Home / Inici; Calendario → Calendar / Calendari; Ejercicios → Exercises / Exercicis; Historial → History / Historial; Ajustes / Configuración → Settings / Configuració
  - modo entreno → workout mode / mode entrenament; superserie → superset / supersèrie; circuito → circuit / circuit; calentamiento → warm-up / escalfament
  - semana fija → fixed week / setmana fixa; semana flexible → flexible week / setmana flexible; secuencia A/B/C → A/B/C sequence / seqüència A/B/C
  - descarga (semana de) → deload / descàrrega; programa → program / programa
  - «Hoy me cuesta» → “Tough day” / «Avui em costa»; «Está ocupada» (máquina) → “It’s taken” / «Està ocupada»; «Hoy no puedo» → “Can’t make it today” / «Avui no puc»
  - hora límite → time limit / hora límit; «Tengo hasta…» → “I have until…” / «Tinc fins a…»
  - peso corporal → bodyweight / pes corporal; por mancuerna → per dumbbell / per manuella; por lado → per side / per costat; asistido → assisted / assistit; lastre → added weight / llast
  - material (equipamiento) → equipment / material; mancuernas → dumbbells / manuelles; poleas → cables / politges; barra de dominadas → pull-up bar / barra de dominades; bandas elásticas → resistance bands / gomes elàstiques
  - recuperación → recovery / recuperació; sueño → sleep / son; pulso en reposo → resting heart rate / pols en repòs
  - «Ahora no» → “Not now” / «Ara no»
- Días de la semana: Lunes → Monday / Dilluns… (sesiones «Sesión A» → “Session A” / «Sessió A»).
- Si una clave es solo un símbolo, número, nombre propio o no tiene nada que traducir, devuélvela igual en ambos idiomas.
- Revisa longitud: textos de botones cortos.
