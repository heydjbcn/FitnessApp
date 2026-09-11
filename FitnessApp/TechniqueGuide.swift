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
        "Press de banca con mancuernas": ["Escápulas juntas, pies firmes.", "Baja las mancuernas a los lados del pecho.", "Codos a unos 45°, muñecas sobre los codos.", "Sube juntándolas un poco arriba."],
        "Cruce de poleas": ["Un pie adelantado y el torso algo inclinado.", "Codos ligeramente flexionados y fijos.", "Junta las manos delante del pecho.", "Vuelve despacio hasta notar el estiramiento."],
        "Press de pecho en máquina": ["Asiento con las asas a la altura del pecho medio.", "Espalda pegada al respaldo.", "Empuja sin bloquear los codos.", "Vuelve lento hasta notar el pecho estirado."],
        "Flexiones inclinadas": ["Manos en un banco o una mesa firme.", "Cuerpo recto de cabeza a talones.", "Pecho hacia el borde del banco.", "Cuanto más alto el apoyo, más fácil."],
        "Flexiones declinadas": ["Pies en un banco, manos en el suelo.", "Aprieta glúteo y abdomen para no hundir la cadera.", "Baja el pecho hacia el suelo.", "Carga más la parte alta del pecho y el hombro."],
        "Remo con mancuerna": ["Rodilla y mano del mismo lado en el banco.", "Espalda plana, paralela al suelo.", "Tira de la mancuerna hacia la cadera.", "Baja estirando del todo el brazo."],
        "Dominadas asistidas": ["Elige la ayuda justa para acabar las repeticiones con esfuerzo.", "Rodillas o pies firmes en la plataforma.", "Tira con los codos hacia las costillas.", "Baja lento hasta estirar los brazos."],
        "Remo invertido": ["Barra a la altura de la cadera, cuerpo recto debajo.", "Tira del pecho hacia la barra.", "Junta las escápulas arriba.", "Pies más adelante = más difícil."],
        "Pullover en polea": ["De pie frente a la polea alta, brazos casi rectos.", "Baja la barra en arco hasta los muslos.", "Nota el dorsal, no el tríceps.", "Vuelve despacio a la altura de los ojos."],
        "Hiperextensiones": ["Apoyo en la cadera, no en el abdomen.", "Baja con la espalda neutra.", "Sube apretando el glúteo hasta alinear el cuerpo.", "No subas más allá de la línea recta."],
        "Press de hombros con mancuernas": ["Sentado con respaldo casi vertical.", "Mancuernas a la altura de las orejas, codos algo adelante.", "Empuja hacia arriba y un poco hacia dentro.", "Baja controlando hasta la altura inicial."],
        "Face pull": ["Polea a la altura de la cara, cuerda con agarre neutro.", "Tira hacia la frente separando las manos.", "Codos altos, a la altura de los hombros.", "Pausa un segundo y vuelve lento."],
        "Press Arnold": ["Empieza con las palmas hacia ti a la altura del pecho.", "Gira las muñecas mientras subes.", "Termina con las palmas hacia delante arriba.", "Deshaz el giro al bajar."],
        "Flexiones en pica": ["Cadera alta, cuerpo en V invertida.", "Baja la cabeza hacia el suelo entre las manos.", "Codos hacia atrás, no abiertos.", "Empuja hasta estirar los brazos."],
        "Curl en polea": ["Cerca de la polea, codos pegados.", "Sube sin mover los hombros.", "Aprieta arriba.", "La polea mantiene la tensión abajo: aprovéchala."],
        "Curl con banda": ["Pisa la banda con los pies al ancho de cadera.", "Codos pegados al cuerpo.", "Sube hasta el hombro y aprieta.", "Baja despacio, que la banda no te devuelva."],
        "Curl concentrado": ["Sentado, codo apoyado en la cara interna del muslo.", "Sube la mancuerna hacia el hombro.", "Aprieta arriba un segundo.", "Baja del todo, sin mover el codo."],
        "Extensión de tríceps sobre la cabeza": ["Mancuerna con las dos manos detrás de la cabeza.", "Codos apuntando al techo y cerrados.", "Estira los brazos hacia arriba.", "Core firme para no arquear la espalda."],
        "Patada de tríceps": ["Torso inclinado, codo pegado al costado y alto.", "Estira el brazo hacia atrás del todo.", "Solo se mueve el antebrazo.", "Vuelve despacio a 90°."],
        "Flexiones diamante": ["Manos juntas bajo el pecho formando un rombo.", "Codos pegados al cuerpo al bajar.", "Cuerpo recto.", "Si cuesta, apoya las rodillas."],
        "Press de banca agarre cerrado": ["Manos al ancho de los hombros, no más juntas.", "Codos pegados al cuerpo.", "Baja la barra a la parte baja del pecho.", "Empuja con el tríceps hasta estirar."],
        "Sentadilla goblet": ["Mancuerna vertical pegada al pecho.", "Pies al ancho de hombros, puntas algo abiertas.", "Baja entre las piernas con el pecho arriba.", "Codos por dentro de las rodillas abajo."],
        "Sentadilla búlgara": ["Empeine de la pierna de atrás en el banco.", "Pie de delante lejos, a un paso largo.", "Baja en vertical hasta que la rodilla de atrás casi toque.", "Empuja con el talón de delante."],
        "Peso muerto rumano": ["De pie con la barra, rodillas algo flexionadas y fijas.", "Lleva la cadera atrás deslizando la barra por los muslos.", "Baja hasta notar el femoral, espalda recta.", "Sube apretando el glúteo."],
        "Sentadilla sin peso": ["Brazos al frente para equilibrarte.", "Cadera atrás y abajo.", "Rodillas en la línea de los pies.", "Sube empujando el suelo con todo el pie."],
        "Subida al banco": ["Pie entero sobre el banco.", "Sube empujando con la pierna de arriba.", "La de abajo solo acompaña.", "Baja despacio, controlando."],
        "Gemelos sentado": ["Almohadilla sobre la parte baja del muslo.", "Baja el talón hasta estirar.", "Sube lo más alto posible.", "Pausa arriba un segundo."],
        "Swing con kettlebell": ["Pies algo más abiertos que la cadera.", "Lleva la pesa atrás entre las piernas con la cadera.", "Extiende la cadera de golpe: la pesa sube sola.", "Arriba, cuerpo recto y glúteo apretado."],
        "Puente de glúteo a una pierna": ["Una pierna apoyada, la otra estirada o doblada arriba.", "Sube la cadera empujando con el talón.", "Cadera recta, sin inclinarse.", "Baja despacio."],
        "Paso lateral con banda": ["Banda por encima de las rodillas o en los tobillos.", "Media sentadilla, pecho arriba.", "Paso al lado sin juntar del todo los pies.", "Rodillas empujando hacia fuera."],
        "Plancha lateral": ["Codo bajo el hombro.", "Cuerpo recto de cabeza a pies.", "Cadera arriba, sin caer.", "Respira normal; cambia de lado."],
        "Dead bug": ["Tumbado, brazos al techo y rodillas a 90°.", "Lumbar pegado al suelo.", "Estira brazo y pierna contrarios despacio.", "Vuelve y cambia de lado."],
        "Rueda abdominal": ["De rodillas, manos en la rueda bajo los hombros.", "Abdomen y glúteo apretados.", "Rueda hacia delante hasta donde mantengas la espalda recta.", "Vuelve tirando con el abdomen."],
        "Pallof press": ["De lado a la polea, a la altura del pecho.", "Manos en el pecho, empuja al frente.", "Aguanta sin dejar que la polea te gire.", "Vuelve despacio; cambia de lado."],
        "Escaladores": ["Posición de flexión, manos bajo los hombros.", "Lleva una rodilla al pecho y cambia.", "Cadera baja y estable.", "Ritmo constante que puedas mantener."],
        "Bird dog": ["A cuatro patas, espalda plana.", "Estira brazo y pierna contrarios.", "Cadera quieta, sin girar.", "Pausa arriba y cambia."],
        "Burpees": ["Agáchate y apoya las manos.", "Salta atrás a plancha.", "Vuelve los pies a las manos.", "Salta con los brazos arriba."],
        "Comba": ["Codos pegados, gira con las muñecas.", "Saltos bajos sobre las puntas.", "Rodillas algo flexionadas.", "Mirada al frente."],
        "Jumping jacks": ["Salta abriendo piernas y subiendo brazos.", "Vuelve cerrando.", "Aterriza suave sobre las puntas.", "Mantén un ritmo constante."],
        "Gato-camello": ["A cuatro patas, manos bajo los hombros.", "Redondea la espalda llevando la mirada al ombligo.", "Luego arquéala mirando al frente.", "Muévete con la respiración."],
        "Movilidad de cadera 90/90": ["Sentado, piernas a 90° delante y detrás.", "Espalda recta, inclínate sobre la pierna de delante.", "Respira y aguanta.", "Cambia de lado girando las rodillas."],
        "Rotaciones torácicas": ["A cuatro patas, una mano en la nuca.", "Gira el codo hacia el techo.", "Sigue el codo con la mirada.", "La cadera no se mueve."],
        "Dislocaciones de hombro con banda": ["Banda con agarre muy abierto.", "Brazos rectos, pásala por encima de la cabeza hasta atrás.", "Vuelve al frente.", "Cierra el agarre poco a poco con las semanas."],
        "Estiramiento de isquiotibiales": ["Pierna estirada en un banco o en el suelo.", "Inclínate desde la cadera con la espalda recta.", "Para al notar tensión, sin dolor.", "Respira y aguanta."],
        "Movilidad de tobillo": ["Pie a un palmo de la pared.", "Lleva la rodilla a tocar la pared sin levantar el talón.", "Rodilla en la línea del dedo gordo.", "Aléjate un poco cuando sea fácil."],
    ]

    /// Técnica para un ejercicio (por nombre, sin mirar mayúsculas ni tildes).
    static func entry(for raw: String) -> (cues: [String], photo: TechniquePhotos.Photo?)? {
        let name = ExerciseCatalog.canonicalName(raw)
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
                        .accessibilityLabel(String(localized: "Ilustración de \(name)"))
                }
                ForEach(Array(t.cues.enumerated()), id: \.offset) { i, cue in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(i + 1)").font(.bri(12)).foregroundColor(p.onacc)
                            .frame(width: 22, height: 22).background(Circle().fill(p.grad))
                        Text((cue).loc).font(.fig(13, .medium)).foregroundColor(p.ink)
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
