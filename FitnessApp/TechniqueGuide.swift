//
//  TechniqueGuide.swift
//  ChamaFit
//
//  Técnica de cada ejercicio del catálogo: 3-4 claves en español y, si la
//  hay, la ilustración de wger.de con su autor y licencia. Los ejercicios
//  propios con el mismo nombre que uno del catálogo también la enseñan.
//

import SwiftUI

enum TechniqueGuide {
    static let cues: [String: [String]] = [
        "Press de banca": ["Escápulas juntas y hacia abajo, pies firmes en el suelo.", "Baja la barra controlada a la parte baja del pecho.", "Codos a unos 45° del cuerpo, no abiertos del todo.", "Empuja hasta estirar sin despegar los glúteos del banco."],
        "Press inclinado mancuernas": ["Banco a 30-45°: más inclinado carga más el hombro.", "Baja las mancuernas a la altura del pecho alto.", "Muñecas rectas encima de los codos.", "Sube juntándolas un poco sin chocarlas."],
        "Aperturas": ["Codos ligeramente flexionados y fijos todo el recorrido.", "Abre hasta notar estiramiento en el pecho, sin pasarte.", "Cierra como si abrazaras un árbol.", "Peso moderado: es un ejercicio de control."],
        "Fondos": ["Hombros abajo, lejos de las orejas.", "Inclínate un poco adelante para cargar el pecho.", "Baja hasta que el brazo quede paralelo al suelo.", "Sube sin bloquear los codos de golpe."],
        "Flexiones": ["Cuerpo recto de cabeza a talones: aprieta glúteo y abdomen.", "Manos algo más abiertas que los hombros.", "Pecho cerca del suelo en cada repetición.", "Si cuesta, apoya las rodillas antes que perder la postura."],
        "Dominadas": ["Empieza colgado con los hombros activos, no sueltos.", "Tira llevando los codos hacia las costillas.", "Barbilla por encima de la barra sin balancearte.", "Baja lento hasta estirar los brazos."],
        "Remo con barra": ["Espalda neutra, torso inclinado unos 45°.", "Tira la barra hacia el ombligo.", "Junta las escápulas arriba un segundo.", "Rodillas algo flexionadas y core firme."],
        "Jalón al pecho": ["Pecho arriba y ligera inclinación atrás.", "Baja la barra a la parte alta del pecho, no detrás de la nuca.", "Piensa en llevar los codos al bolsillo trasero.", "Sube controlando, sin que el peso te tire."],
        "Remo en máquina": ["Pecho apoyado o erguido, sin balancearte.", "Tira con los codos pegados al cuerpo.", "Aprieta las escápulas al final.", "Estira los brazos del todo al volver."],
        "Peso muerto": ["Barra pegada a las espinillas, espalda neutra.", "Empuja el suelo con las piernas y extiende la cadera.", "La barra sube rozando las piernas.", "Arriba, de pie sin echarte atrás; baja con la cadera primero."],
        "Press militar": ["Glúteo y abdomen apretados para no arquear la espalda.", "Barra desde la clavícula en línea recta hacia arriba.", "Mete la cabeza bajo la barra al final.", "Baja controlado hasta la barbilla."],
        "Elevaciones laterales": ["Codos ligeramente flexionados.", "Sube hasta la altura de los hombros, no más.", "Guía con los codos, no con las manos.", "Sin impulso: si balanceas, baja el peso."],
        "Elevaciones frontales": ["De pie, core firme, sin echarte atrás.", "Sube el peso al frente hasta la altura de los ojos.", "Baja lento en 2-3 segundos.", "Alterna brazos si te cuesta mantener la postura."],
        "Pájaros": ["Torso inclinado casi paralelo al suelo.", "Abre los brazos hacia los lados con codos algo flexionados.", "Piensa en separar las manos, no en subirlas.", "Peso ligero: trabaja el hombro posterior."],
        "Curl con barra": ["Codos pegados al cuerpo y quietos.", "Sube sin mover los hombros ni balancear.", "Aprieta arriba un segundo.", "Baja del todo, controlando."],
        "Curl con mancuernas": ["Palmas hacia delante, codos fijos.", "Puedes girar la muñeca al subir (supinación).", "Sin impulso de la espalda.", "Alterna si quieres más concentración."],
        "Curl martillo": ["Palmas mirándose, como si sujetaras un martillo.", "Codos pegados al costado.", "Sube hasta el hombro sin balancear.", "Trabaja también el antebrazo."],
        "Press francés": ["Tumbado, brazos verticales y codos quietos.", "Baja la barra hacia la frente doblando solo el codo.", "Codos cerrados, que no se abran.", "Sube extendiendo sin bloquear de golpe."],
        "Extensiones en polea": ["Codos pegados al cuerpo y fijos.", "Extiende hasta estirar del todo el brazo.", "Aprieta el tríceps abajo un segundo.", "Sube despacio hasta los 90°."],
        "Fondos en banco": ["Manos en el borde del banco, dedos hacia delante.", "Espalda cerca del banco al bajar.", "Baja hasta que el codo haga 90°.", "Piernas estiradas lo hacen más difícil."],
        "Sentadilla": ["Pies al ancho de hombros, puntas algo abiertas.", "Rodillas en la línea de las puntas de los pies.", "Baja con la cadera atrás hasta al menos paralelo.", "Pecho arriba y talones apoyados todo el rato."],
        "Prensa": ["Espalda y cadera pegadas al respaldo.", "Pies al ancho de hombros en el centro de la plataforma.", "Baja hasta 90° sin despegar el lumbar.", "No bloquees las rodillas arriba."],
        "Extensión de cuádriceps": ["Ajusta el respaldo para que la rodilla quede en el eje.", "Extiende del todo y aprieta arriba.", "Baja lento, sin dejar caer el peso.", "Agárrate a las asas para no moverte."],
        "Curl femoral": ["Rodilla alineada con el eje de la máquina.", "Flexiona llevando el talón al glúteo.", "Cadera pegada al banco, sin levantarla.", "Baja controlado en 2-3 segundos."],
        "Zancadas": ["Paso largo, torso erguido.", "Baja hasta que ambas rodillas hagan 90°.", "La rodilla de delante no pasa mucho de la punta.", "Empuja con el talón de delante para subir."],
        "Gemelos de pie": ["Rodillas estiradas pero sin bloquear.", "Sube lo más alto que puedas sobre las puntas.", "Pausa arriba un segundo.", "Baja hasta estirar bien el gemelo."],
        "Hip thrust": ["Parte alta de la espalda apoyada en el banco.", "Barra o mancuerna sobre la cadera, con almohadilla.", "Sube la cadera hasta alinear rodillas, cadera y hombros.", "Aprieta el glúteo arriba; mirada al frente."],
        "Patada de glúteo": ["Espalda neutra, sin arquear el lumbar.", "Empuja el talón hacia atrás y arriba.", "Aprieta el glúteo al final.", "Controla la vuelta, sin balanceo."],
        "Abducción de cadera": ["Espalda pegada al respaldo.", "Abre las piernas empujando con la cadera.", "Pausa un segundo abierto.", "Cierra lento sin que choquen las placas."],
        "Puente de glúteo": ["Tumbado, pies apoyados cerca del glúteo.", "Sube la cadera apretando el glúteo.", "Hombros, cadera y rodillas en línea arriba.", "Baja sin tocar del todo el suelo."],
        "Plancha": ["Codos bajo los hombros.", "Cuerpo recto: ni cadera arriba ni caída.", "Aprieta glúteo y abdomen, respira normal.", "Mejor 30 s perfectos que 60 s mal."],
        "Crunch": ["Lumbar apoyado en el suelo.", "Sube despegando solo los hombros.", "No tires del cuello con las manos.", "Exhala al subir y baja lento."],
        "Elevación de piernas": ["Lumbar pegado al suelo todo el tiempo.", "Sube las piernas juntas hasta la vertical.", "Baja despacio sin tocar el suelo.", "Si arqueas la espalda, dobla un poco las rodillas."],
        "Russian twist": ["Sentado, torso inclinado atrás y espalda recta.", "Gira el tronco, no solo los brazos.", "Pies en el suelo o elevados para más dificultad.", "Movimiento controlado, sin prisas."],
        "Cinta de correr": ["Postura erguida, mirada al frente.", "Pisa bajo tu cadera, pasos cortos.", "Brazos relajados acompañando.", "Una ligera inclinación (1 %) imita correr fuera."],
        "Bicicleta estática": ["Sillín a la altura de la cadera de pie.", "Rodilla casi estirada abajo, sin bloquear.", "Espalda recta y hombros relajados.", "Ajusta resistencia para mantener buena cadencia."],
        "Elíptica": ["Erguido, sin apoyarte del todo en las asas.", "Empuja con todo el pie, no solo con la punta.", "Brazos y piernas coordinados.", "Sube resistencia antes que velocidad."],
        "Remo": ["Secuencia: piernas, cadera, brazos; vuelta al revés.", "Espalda recta todo el recorrido.", "Tira hacia la parte baja del pecho.", "La fuerza sale de las piernas, no de los brazos."],
    ]

    /// Técnica para un ejercicio (por nombre, sin mirar mayúsculas ni tildes).
    static func entry(for name: String) -> (cues: [String], photo: TechniquePhotos.Photo?)? {
        let key = fold(name)
        guard let match = cues.keys.first(where: { fold($0) == key }) else { return nil }
        return (cues[match] ?? [], TechniquePhotos.byName[match])
    }

    private static func fold(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).trimmingCharacters(in: .whitespaces)
    }
}

struct TechniqueCard: View {
    let name: String
    let p: Palette

    var body: some View {
        if let t = TechniqueGuide.entry(for: name) {
            VStack(alignment: .leading, spacing: 10) {
                UpperLabel(text: "Técnica", p: p)
                if let photo = t.photo {
                    Image(photo.asset)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 190)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white))
                        .accessibilityLabel("Ilustración de \(name)")
                }
                ForEach(Array(t.cues.enumerated()), id: \.offset) { i, cue in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(i + 1)").font(.bri(12)).foregroundColor(p.onacc)
                            .frame(width: 22, height: 22).background(Circle().fill(p.grad))
                        Text(cue).font(.fig(13, .medium)).foregroundColor(p.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if let photo = t.photo {
                    Text("Ilustración: \(photo.author) · \(photo.license) · wger.de")
                        .font(.fig(10, .medium)).foregroundColor(p.mute)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.soft))
            .accessibilityIdentifier("detail.technique")
        }
    }
}
