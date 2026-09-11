//
//  ExerciseLibrary.swift
//  ChamaFit
//
//  Lo que la ficha de cada ejercicio del catálogo sabe además de la técnica:
//  qué material hace falta, qué significa el peso, músculos secundarios,
//  errores habituales, una variante más fácil y otra más difícil, y con qué
//  se puede cambiar. Los ejercicios propios con el mismo nombre lo heredan.
//

import Foundation

enum ExerciseLibrary {

    struct Details {
        /// Todo lo que hace falta (vacío = solo el cuerpo).
        let needs: Set<Equipment>
        var load: LoadKind = .total
        var secondary: [String] = []
        let mistakes: [String]
        var easier: String? = nil
        var harder: String? = nil
        let alternatives: [String]
    }

    static func details(for raw: String) -> Details? {
        let name = ExerciseCatalog.canonicalName(raw)
        let key = fold(name)
        if let d = byName[name] { return d }
        return byName.first { fold($0.key) == key }?.value
    }

    static func fold(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: AppLanguage.locale)
            .trimmingCharacters(in: .whitespaces)
    }

    /// ¿Se puede hacer con este material?
    static func fits(_ name: String, _ equipment: EquipmentProfile) -> Bool {
        guard let d = details(for: name) else { return true }
        return d.needs.isSubset(of: equipment.items)
    }

    // swiftlint:disable line_length
    static let byName: [String: Details] = [
        // MARK: Pecho
        "Press de banca": Details(needs: [.barbell, .bench], secondary: ["Tríceps", "Hombros"],
            mistakes: ["Rebotar la barra en el pecho para subirla.", "Despegar los glúteos del banco al empujar.", "Codos abiertos a 90°: carga de más el hombro."],
            easier: "Press de pecho en máquina", harder: "Press de banca con pausa de un segundo en el pecho",
            alternatives: ["Press de banca con mancuernas", "Press de pecho en máquina", "Flexiones"]),
        "Press inclinado mancuernas": Details(needs: [.dumbbell, .bench], load: .perDumbbell, secondary: ["Hombros", "Tríceps"],
            mistakes: ["Banco demasiado inclinado: se convierte en press de hombro.", "Bajar poco por miedo al peso.", "Chocar las mancuernas arriba perdiendo tensión."],
            easier: "Flexiones declinadas", harder: "Press inclinado con pausa abajo",
            alternatives: ["Press de banca con mancuernas", "Flexiones declinadas", "Cruce de poleas"]),
        "Aperturas": Details(needs: [.dumbbell, .bench], load: .perDumbbell, secondary: ["Hombros"],
            mistakes: ["Estirar del todo los codos: sufre el hombro.", "Bajar más allá de la línea del banco.", "Usar tanto peso que acaba siendo un press."],
            easier: "Cruce de poleas", harder: "Aperturas con pausa de dos segundos abajo",
            alternatives: ["Cruce de poleas", "Press de banca con mancuernas", "Flexiones"]),
        "Fondos": Details(needs: [.machine], load: .bodyweight, secondary: ["Tríceps", "Hombros"],
            mistakes: ["Hombros encogidos hacia las orejas.", "Bajar tanto que el hombro se va hacia delante.", "Balancear las piernas para subir."],
            easier: "Fondos en banco", harder: "Fondos con lastre",
            alternatives: ["Flexiones declinadas", "Press de banca agarre cerrado", "Fondos en banco"]),
        "Flexiones": Details(needs: [], load: .bodyweight, secondary: ["Tríceps", "Hombros", "Core"],
            mistakes: ["Cadera caída o en pico.", "Codos totalmente abiertos en cruz.", "Recorrido corto: el pecho no baja."],
            easier: "Flexiones inclinadas", harder: "Flexiones declinadas",
            alternatives: ["Press de banca con mancuernas", "Flexiones inclinadas", "Press de pecho en máquina"]),
        "Press de banca con mancuernas": Details(needs: [.dumbbell, .bench], load: .perDumbbell, secondary: ["Tríceps", "Hombros"],
            mistakes: ["Dejar caer las mancuernas al bajar.", "Muñecas dobladas hacia atrás.", "Arquear tanto la espalda que se despega el glúteo."],
            easier: "Press de pecho en máquina", harder: "Press de banca con mancuernas a un brazo",
            alternatives: ["Press de banca", "Flexiones", "Press de pecho en máquina"]),
        "Cruce de poleas": Details(needs: [.cable], secondary: ["Hombros"],
            mistakes: ["Tirar con los brazos rectos y los hombros adelantados.", "Mover el torso para ayudarte.", "Soltar rápido la vuelta."],
            easier: "Aperturas en máquina o con menos peso", harder: "Cruce de poleas a un brazo con pausa",
            alternatives: ["Aperturas", "Press de banca con mancuernas", "Flexiones"]),
        "Press de pecho en máquina": Details(needs: [.machine], secondary: ["Tríceps", "Hombros"],
            mistakes: ["Asiento mal ajustado: asas por encima del pecho.", "Despegar la espalda del respaldo.", "Bloquear los codos de golpe."],
            easier: "Flexiones inclinadas", harder: "Press de banca",
            alternatives: ["Press de banca", "Press de banca con mancuernas", "Flexiones"]),
        "Flexiones inclinadas": Details(needs: [.bench], load: .bodyweight, secondary: ["Tríceps", "Hombros"],
            mistakes: ["Cadera por detrás de la línea del cuerpo.", "Manos demasiado adelantadas.", "Bajar solo la cabeza."],
            easier: "Flexiones contra la pared", harder: "Flexiones",
            alternatives: ["Flexiones", "Press de pecho en máquina", "Press de banca con mancuernas"]),
        "Flexiones declinadas": Details(needs: [.bench], load: .bodyweight, secondary: ["Hombros", "Tríceps"],
            mistakes: ["Dejar caer la cadera por el peso de las piernas.", "Mirar hacia delante forzando el cuello.", "Codos muy abiertos."],
            easier: "Flexiones", harder: "Flexiones en pica",
            alternatives: ["Press inclinado mancuernas", "Flexiones", "Press de hombros con mancuernas"]),

        // MARK: Espalda
        "Dominadas": Details(needs: [.pullupBar], load: .bodyweight, secondary: ["Bíceps", "Core"],
            mistakes: ["Balancearse o dar patadas para subir.", "Quedarse a medio recorrido abajo.", "Hombros sueltos al colgar."],
            easier: "Dominadas asistidas", harder: "Dominadas con lastre",
            alternatives: ["Jalón al pecho", "Dominadas asistidas", "Remo invertido"]),
        "Remo con barra": Details(needs: [.barbell], secondary: ["Bíceps", "Core"],
            mistakes: ["Espalda redondeada.", "Incorporarse con cada repetición.", "Tirar hacia el pecho en vez de al ombligo."],
            easier: "Remo en máquina", harder: "Remo Pendlay desde el suelo",
            alternatives: ["Remo con mancuerna", "Remo en máquina", "Remo invertido"]),
        "Jalón al pecho": Details(needs: [.cable], secondary: ["Bíceps"],
            mistakes: ["Llevar la barra detrás de la nuca.", "Echarse muy atrás y hacer un remo.", "Subir de golpe dejando que el peso tire."],
            easier: "Jalón con menos peso y pausa abajo", harder: "Dominadas",
            alternatives: ["Dominadas", "Dominadas asistidas", "Pullover en polea"]),
        "Remo en máquina": Details(needs: [.machine], secondary: ["Bíceps"],
            mistakes: ["Balancear el torso para mover más peso.", "No estirar los brazos al volver.", "Encoger los hombros al tirar."],
            easier: "Remo con banda", harder: "Remo con barra",
            alternatives: ["Remo con mancuerna", "Remo con barra", "Remo invertido"]),
        "Peso muerto": Details(needs: [.barbell], secondary: ["Glúteos", "Piernas", "Core"],
            mistakes: ["Redondear la zona lumbar.", "Barra lejos de las piernas.", "Tirar con los brazos o subir la cadera antes que la barra."],
            easier: "Peso muerto rumano", harder: "Peso muerto con pausa bajo la rodilla",
            alternatives: ["Peso muerto rumano", "Swing con kettlebell", "Hip thrust"]),
        "Remo con mancuerna": Details(needs: [.dumbbell, .bench], load: .perSide, secondary: ["Bíceps"],
            mistakes: ["Girar el torso para subir la mancuerna.", "Tirar hacia el hombro en vez de hacia la cadera.", "Espalda redondeada."],
            easier: "Remo con banda", harder: "Remo con mancuerna con pausa arriba",
            alternatives: ["Remo en máquina", "Remo con barra", "Remo invertido"]),
        "Dominadas asistidas": Details(needs: [.machine], load: .assisted, secondary: ["Bíceps"],
            mistakes: ["Poner tanta ayuda que no cuesta.", "Rodillas empujando la plataforma para impulsarse.", "Recorrido corto arriba."],
            easier: "Jalón al pecho", harder: "Dominadas",
            alternatives: ["Jalón al pecho", "Dominadas", "Remo invertido"]),
        "Remo invertido": Details(needs: [.pullupBar], load: .bodyweight, secondary: ["Bíceps", "Core"],
            mistakes: ["Cadera caída.", "Tirar con el cuello hacia la barra.", "Bajar sin control."],
            easier: "Remo invertido con las rodillas dobladas", harder: "Remo invertido con los pies elevados",
            alternatives: ["Remo con mancuerna", "Remo en máquina", "Dominadas asistidas"]),
        "Pullover en polea": Details(needs: [.cable], secondary: ["Tríceps", "Core"],
            mistakes: ["Doblar los codos y convertirlo en un jalón.", "Arquear la espalda al bajar.", "Subir más allá de la cabeza sin control."],
            easier: "Pullover con menos peso", harder: "Pullover con pausa abajo",
            alternatives: ["Jalón al pecho", "Dominadas asistidas", "Remo en máquina"]),
        "Hiperextensiones": Details(needs: [.machine], load: .bodyweight, secondary: ["Glúteos", "Piernas"],
            mistakes: ["Subir de más arqueando el lumbar.", "Hacerlo rápido y a tirones.", "Apoyo muy alto que bloquea la cadera."],
            easier: "Bird dog", harder: "Hiperextensiones con disco al pecho",
            alternatives: ["Peso muerto rumano", "Puente de glúteo", "Bird dog"]),

        // MARK: Hombros
        "Press militar": Details(needs: [.barbell], secondary: ["Tríceps", "Core"],
            mistakes: ["Arquear la zona lumbar para empujar.", "Barra por delante de la cara al final.", "Usar las piernas sin querer."],
            easier: "Press de hombros con mancuernas", harder: "Press militar con pausa en la clavícula",
            alternatives: ["Press de hombros con mancuernas", "Press Arnold", "Flexiones en pica"]),
        "Elevaciones laterales": Details(needs: [.dumbbell], load: .perDumbbell,
            mistakes: ["Subir por encima del hombro encogiendo el trapecio.", "Balancear el cuerpo.", "Brazos totalmente rectos."],
            easier: "Elevaciones laterales sentado", harder: "Elevaciones laterales con pausa arriba",
            alternatives: ["Face pull", "Press Arnold", "Elevaciones frontales"]),
        "Elevaciones frontales": Details(needs: [.dumbbell], load: .perDumbbell, secondary: ["Pecho"],
            mistakes: ["Echar el cuerpo atrás para subir.", "Subir por encima de los ojos.", "Bajar de golpe."],
            easier: "Elevaciones frontales alternas", harder: "Elevaciones frontales con disco",
            alternatives: ["Press de hombros con mancuernas", "Elevaciones laterales", "Press Arnold"]),
        "Pájaros": Details(needs: [.dumbbell], load: .perDumbbell, secondary: ["Espalda"],
            mistakes: ["Torso demasiado erguido.", "Tirar con los trapecios.", "Demasiado peso y poco recorrido."],
            easier: "Pájaros con el pecho apoyado", harder: "Pájaros con pausa arriba",
            alternatives: ["Face pull", "Remo con mancuerna", "Elevaciones laterales"]),
        "Press de hombros con mancuernas": Details(needs: [.dumbbell, .bench], load: .perDumbbell, secondary: ["Tríceps"],
            mistakes: ["Arquear la espalda despegándola del respaldo.", "Bajar poco las mancuernas.", "Muñecas dobladas."],
            easier: "Press de hombros sentado con respaldo", harder: "Press de hombros de pie",
            alternatives: ["Press militar", "Press Arnold", "Flexiones en pica"]),
        "Face pull": Details(needs: [.cable], secondary: ["Espalda"],
            mistakes: ["Tirar hacia el cuello en vez de a la cara.", "Codos por debajo de las manos.", "Echarse atrás para mover más peso."],
            easier: "Face pull con banda", harder: "Face pull con pausa de dos segundos",
            alternatives: ["Pájaros", "Remo con mancuerna", "Elevaciones laterales"]),
        "Press Arnold": Details(needs: [.dumbbell], load: .perDumbbell, secondary: ["Tríceps"],
            mistakes: ["Girar tarde, con el brazo ya arriba.", "Arquear la espalda.", "Hacerlo rápido perdiendo el giro."],
            easier: "Press de hombros con mancuernas", harder: "Press Arnold de pie",
            alternatives: ["Press de hombros con mancuernas", "Press militar", "Elevaciones laterales"]),
        "Flexiones en pica": Details(needs: [], load: .bodyweight, secondary: ["Tríceps"],
            mistakes: ["Cadera baja: acaba siendo una flexión normal.", "Cabeza por delante de las manos.", "Codos muy abiertos."],
            easier: "Flexiones declinadas", harder: "Flexiones en pica con los pies elevados",
            alternatives: ["Press de hombros con mancuernas", "Press militar", "Flexiones declinadas"]),

        // MARK: Bíceps
        "Curl con barra": Details(needs: [.barbell],
            mistakes: ["Balancear el tronco.", "Adelantar los codos al subir.", "Medio recorrido abajo."],
            easier: "Curl con mancuernas", harder: "Curl con barra con pausa a mitad",
            alternatives: ["Curl con mancuernas", "Curl en polea", "Curl con banda"]),
        "Curl con mancuernas": Details(needs: [.dumbbell], load: .perDumbbell,
            mistakes: ["Impulso con la espalda.", "Codos que se separan del cuerpo.", "Bajar de golpe."],
            easier: "Curl con banda", harder: "Curl concentrado",
            alternatives: ["Curl con barra", "Curl en polea", "Curl martillo"]),
        "Curl martillo": Details(needs: [.dumbbell], load: .perDumbbell, secondary: ["Antebrazo"],
            mistakes: ["Girar la muñeca y perder el agarre neutro.", "Balancear.", "Subir el codo al final."],
            easier: "Curl martillo alterno", harder: "Curl martillo con pausa arriba",
            alternatives: ["Curl con mancuernas", "Curl en polea", "Curl con banda"]),
        "Curl en polea": Details(needs: [.cable],
            mistakes: ["Alejarse de la polea y tirar con la espalda.", "Codos que se adelantan.", "Soltar la vuelta."],
            easier: "Curl con banda", harder: "Curl en polea a un brazo",
            alternatives: ["Curl con barra", "Curl con mancuernas", "Curl con banda"]),
        "Curl con banda": Details(needs: [.band],
            mistakes: ["Banda demasiado floja: no cuesta arriba.", "Codos que se mueven.", "Dejar que la banda te devuelva de golpe."],
            easier: "Curl con banda más ligera", harder: "Curl con mancuernas",
            alternatives: ["Curl con mancuernas", "Curl en polea", "Curl martillo"]),
        "Curl concentrado": Details(needs: [.dumbbell, .bench], load: .perSide,
            mistakes: ["Apoyar el codo muy abajo del muslo.", "Subir con el hombro.", "Bajar sin control."],
            easier: "Curl con mancuernas", harder: "Curl concentrado con pausa arriba",
            alternatives: ["Curl con mancuernas", "Curl en polea", "Curl martillo"]),

        // MARK: Tríceps
        "Press francés": Details(needs: [.barbell, .bench],
            mistakes: ["Abrir los codos.", "Mover los hombros y convertirlo en un press.", "Bajar la barra a la nariz sin control."],
            easier: "Extensiones en polea", harder: "Press francés con pausa abajo",
            alternatives: ["Extensión de tríceps sobre la cabeza", "Extensiones en polea", "Flexiones diamante"]),
        "Extensiones en polea": Details(needs: [.cable],
            mistakes: ["Codos que se separan del cuerpo.", "Inclinarse encima para empujar con el peso.", "No estirar del todo."],
            easier: "Extensiones con menos peso", harder: "Extensiones en polea a un brazo",
            alternatives: ["Press francés", "Patada de tríceps", "Fondos en banco"]),
        "Fondos en banco": Details(needs: [.bench], load: .bodyweight, secondary: ["Pecho", "Hombros"],
            mistakes: ["Separarse del banco: el hombro va hacia delante.", "Bajar de más.", "Empujar con las piernas."],
            easier: "Fondos en banco con las rodillas dobladas", harder: "Fondos",
            alternatives: ["Flexiones diamante", "Extensiones en polea", "Patada de tríceps"]),
        "Extensión de tríceps sobre la cabeza": Details(needs: [.dumbbell],
            mistakes: ["Codos muy abiertos.", "Arquear la espalda.", "Bajar poco la mancuerna."],
            easier: "Extensiones en polea", harder: "Extensión sobre la cabeza con pausa abajo",
            alternatives: ["Press francés", "Extensiones en polea", "Patada de tríceps"]),
        "Patada de tríceps": Details(needs: [.dumbbell, .bench], load: .perSide,
            mistakes: ["Codo que baja al extender.", "Balancear la mancuerna.", "No estirar el brazo del todo."],
            easier: "Patada con menos peso", harder: "Patada de tríceps en polea",
            alternatives: ["Extensiones en polea", "Extensión de tríceps sobre la cabeza", "Fondos en banco"]),
        "Flexiones diamante": Details(needs: [], load: .bodyweight, secondary: ["Pecho"],
            mistakes: ["Codos abiertos hacia los lados.", "Cadera caída.", "Manos muy adelantadas."],
            easier: "Flexiones diamante con las rodillas apoyadas", harder: "Flexiones diamante con los pies elevados",
            alternatives: ["Fondos en banco", "Press de banca agarre cerrado", "Flexiones"]),
        "Press de banca agarre cerrado": Details(needs: [.barbell, .bench], secondary: ["Pecho", "Hombros"],
            mistakes: ["Agarre tan cerrado que se tuercen las muñecas.", "Codos abiertos.", "Rebotar en el pecho."],
            easier: "Flexiones diamante", harder: "Press cerrado con pausa en el pecho",
            alternatives: ["Fondos", "Flexiones diamante", "Press francés"]),

        // MARK: Piernas
        "Sentadilla": Details(needs: [.barbell], secondary: ["Glúteos", "Core"],
            mistakes: ["Rodillas que se van hacia dentro.", "Talones que se levantan.", "Recorrido corto por encima del paralelo."],
            easier: "Sentadilla goblet", harder: "Sentadilla con pausa abajo",
            alternatives: ["Sentadilla goblet", "Prensa", "Sentadilla búlgara"]),
        "Prensa": Details(needs: [.machine], secondary: ["Glúteos"],
            mistakes: ["Despegar la zona lumbar al bajar.", "Bloquear las rodillas arriba.", "Pies tan bajos que los talones se levantan."],
            easier: "Sentadilla sin peso", harder: "Prensa a una pierna",
            alternatives: ["Sentadilla", "Sentadilla goblet", "Sentadilla búlgara"]),
        "Extensión de cuádriceps": Details(needs: [.machine],
            mistakes: ["Rodilla fuera del eje de la máquina.", "Dar patadas y dejar caer el peso.", "Levantar la cadera del asiento."],
            easier: "Extensión a una pierna con menos peso", harder: "Extensión con pausa arriba",
            alternatives: ["Sentadilla goblet", "Subida al banco", "Zancadas"]),
        "Curl femoral": Details(needs: [.machine],
            mistakes: ["Levantar la cadera del banco.", "Recorrido corto.", "Bajar de golpe."],
            easier: "Curl femoral con menos peso", harder: "Curl femoral a una pierna",
            alternatives: ["Peso muerto rumano", "Puente de glúteo a una pierna", "Hiperextensiones"]),
        "Zancadas": Details(needs: [.dumbbell], load: .perDumbbell, secondary: ["Glúteos"],
            mistakes: ["Paso demasiado corto.", "Rodilla de delante hacia dentro.", "Torso muy inclinado."],
            easier: "Zancadas sin peso", harder: "Sentadilla búlgara",
            alternatives: ["Sentadilla búlgara", "Subida al banco", "Sentadilla goblet"]),
        "Gemelos de pie": Details(needs: [.machine],
            mistakes: ["Rebotar abajo.", "Doblar las rodillas para ayudarte.", "Recorrido corto arriba."],
            easier: "Gemelos sin peso en un escalón", harder: "Gemelos a una pierna",
            alternatives: ["Gemelos sentado", "Subida al banco", "Comba"]),
        "Sentadilla goblet": Details(needs: [.dumbbell], secondary: ["Glúteos", "Core"],
            mistakes: ["Mancuerna lejos del pecho.", "Rodillas hacia dentro.", "Espalda que se redondea abajo."],
            easier: "Sentadilla sin peso", harder: "Sentadilla",
            alternatives: ["Sentadilla", "Prensa", "Sentadilla búlgara"]),
        "Sentadilla búlgara": Details(needs: [.dumbbell, .bench], load: .perDumbbell, secondary: ["Glúteos"],
            mistakes: ["Pie de delante demasiado cerca del banco.", "Empujar con la pierna de atrás.", "Rodilla hacia dentro."],
            easier: "Zancadas", harder: "Sentadilla búlgara con pausa abajo",
            alternatives: ["Zancadas", "Subida al banco", "Sentadilla goblet"]),
        "Peso muerto rumano": Details(needs: [.barbell], secondary: ["Glúteos", "Espalda"],
            mistakes: ["Doblar las rodillas y hacer una sentadilla.", "Barra lejos de las piernas.", "Redondear la espalda al bajar."],
            easier: "Peso muerto rumano con mancuernas", harder: "Peso muerto rumano a una pierna",
            alternatives: ["Curl femoral", "Hiperextensiones", "Swing con kettlebell"]),
        "Sentadilla sin peso": Details(needs: [], load: .bodyweight, secondary: ["Glúteos"],
            mistakes: ["Talones que se levantan.", "Mirar al suelo y redondear.", "Bajar poco."],
            easier: "Sentadilla a un banco", harder: "Sentadilla goblet",
            alternatives: ["Sentadilla goblet", "Zancadas", "Subida al banco"]),
        "Subida al banco": Details(needs: [.bench], load: .perDumbbell, secondary: ["Glúteos"],
            mistakes: ["Impulsarse con la pierna de abajo.", "Banco demasiado alto.", "Rodilla hacia dentro al subir."],
            easier: "Subida a un escalón más bajo", harder: "Sentadilla búlgara",
            alternatives: ["Zancadas", "Sentadilla búlgara", "Sentadilla goblet"]),
        "Gemelos sentado": Details(needs: [.machine],
            mistakes: ["Rebotar abajo.", "Recorrido corto.", "Demasiado peso y movimiento a tirones."],
            easier: "Gemelos sentado con menos peso", harder: "Gemelos sentado con pausa arriba",
            alternatives: ["Gemelos de pie", "Comba", "Subida al banco"]),

        // MARK: Glúteos
        "Hip thrust": Details(needs: [.barbell, .bench], secondary: ["Piernas"],
            mistakes: ["Arquear el lumbar arriba en vez de extender la cadera.", "Pies muy lejos: trabaja el femoral.", "Bajar sin control."],
            easier: "Puente de glúteo", harder: "Hip thrust a una pierna",
            alternatives: ["Puente de glúteo", "Puente de glúteo a una pierna", "Swing con kettlebell"]),
        "Patada de glúteo": Details(needs: [.cable], load: .perSide,
            mistakes: ["Arquear la espalda al subir la pierna.", "Balancear.", "Girar la cadera."],
            easier: "Patada de glúteo sin peso a cuatro patas", harder: "Patada de glúteo con pausa arriba",
            alternatives: ["Puente de glúteo a una pierna", "Hip thrust", "Paso lateral con banda"]),
        "Abducción de cadera": Details(needs: [.machine],
            mistakes: ["Despegar la espalda del respaldo.", "Cerrar de golpe.", "Recorrido corto."],
            easier: "Abducción con menos peso", harder: "Abducción con el torso inclinado adelante",
            alternatives: ["Paso lateral con banda", "Puente de glúteo", "Patada de glúteo"]),
        "Puente de glúteo": Details(needs: [], load: .bodyweight, secondary: ["Piernas"],
            mistakes: ["Empujar con la espalda en vez de con el glúteo.", "Pies demasiado lejos.", "Rodillas que se abren o se cierran."],
            easier: "Puente de glúteo con recorrido corto", harder: "Puente de glúteo a una pierna",
            alternatives: ["Hip thrust", "Puente de glúteo a una pierna", "Swing con kettlebell"]),
        "Swing con kettlebell": Details(needs: [.kettlebell], secondary: ["Piernas", "Core", "Espalda"],
            mistakes: ["Hacer una sentadilla en vez de llevar la cadera atrás.", "Subir la pesa con los brazos.", "Arquear la espalda arriba."],
            easier: "Peso muerto rumano con kettlebell", harder: "Swing a una mano",
            alternatives: ["Peso muerto rumano", "Hip thrust", "Puente de glúteo"]),
        "Puente de glúteo a una pierna": Details(needs: [], load: .bodyweight, secondary: ["Piernas"],
            mistakes: ["Cadera que se inclina hacia un lado.", "Empujar con la punta del pie.", "Subir con el lumbar."],
            easier: "Puente de glúteo", harder: "Hip thrust a una pierna",
            alternatives: ["Puente de glúteo", "Hip thrust", "Subida al banco"]),
        "Paso lateral con banda": Details(needs: [.band], load: .bodyweight,
            mistakes: ["Juntar los pies del todo y perder tensión.", "Balancear el tronco.", "Rodillas hacia dentro."],
            easier: "Paso lateral con banda más ligera", harder: "Paso lateral en media sentadilla",
            alternatives: ["Abducción de cadera", "Puente de glúteo", "Patada de glúteo"]),

        // MARK: Core
        "Plancha": Details(needs: [], load: .bodyweight,
            mistakes: ["Cadera caída.", "Cadera demasiado alta.", "Aguantar la respiración."],
            easier: "Plancha con las rodillas apoyadas", harder: "Plancha con un pie en el aire",
            alternatives: ["Dead bug", "Plancha lateral", "Rueda abdominal"]),
        "Crunch": Details(needs: [], load: .bodyweight,
            mistakes: ["Tirar del cuello.", "Subir con impulso.", "Despegar el lumbar."],
            easier: "Crunch con recorrido corto", harder: "Crunch en polea",
            alternatives: ["Dead bug", "Elevación de piernas", "Rueda abdominal"]),
        "Elevación de piernas": Details(needs: [], load: .bodyweight,
            mistakes: ["Arquear el lumbar al bajar.", "Balancear las piernas.", "Soltar abajo de golpe."],
            easier: "Elevación de piernas con rodillas dobladas", harder: "Elevación de piernas colgado",
            alternatives: ["Dead bug", "Crunch", "Rueda abdominal"]),
        "Russian twist": Details(needs: [], load: .total,
            mistakes: ["Mover solo los brazos.", "Espalda redondeada.", "Ir a toda velocidad."],
            easier: "Russian twist sin peso y pies apoyados", harder: "Russian twist con pies elevados",
            alternatives: ["Pallof press", "Plancha lateral", "Dead bug"]),
        "Plancha lateral": Details(needs: [], load: .bodyweight,
            mistakes: ["Cadera que cae.", "Hombro lejos del codo.", "Girar el torso hacia el suelo."],
            easier: "Plancha lateral con rodillas apoyadas", harder: "Plancha lateral con la pierna de arriba elevada",
            alternatives: ["Pallof press", "Plancha", "Russian twist"]),
        "Dead bug": Details(needs: [], load: .bodyweight,
            mistakes: ["Despegar el lumbar del suelo.", "Hacerlo rápido.", "Aguantar la respiración."],
            easier: "Dead bug solo con las piernas", harder: "Dead bug con peso en las manos",
            alternatives: ["Plancha", "Bird dog", "Elevación de piernas"]),
        "Rueda abdominal": Details(needs: [], load: .bodyweight, secondary: ["Hombros"],
            mistakes: ["Hundir la cadera y arquear el lumbar.", "Ir más lejos de lo que controlas.", "Volver tirando con la cadera."],
            easier: "Rueda abdominal hasta media distancia", harder: "Rueda abdominal de pie",
            alternatives: ["Plancha", "Dead bug", "Elevación de piernas"]),
        "Pallof press": Details(needs: [.cable], secondary: ["Hombros"],
            mistakes: ["Dejar que la polea te gire.", "Estar demasiado cerca de la polea.", "Arquear la espalda."],
            easier: "Pallof press con banda ligera", harder: "Pallof press de rodillas con pausa",
            alternatives: ["Plancha lateral", "Russian twist", "Dead bug"]),
        "Escaladores": Details(needs: [], load: .bodyweight, secondary: ["Cardio", "Hombros"],
            mistakes: ["Cadera en pico.", "Manos por delante de los hombros.", "Rodillas que no llegan al pecho."],
            easier: "Escaladores lentos", harder: "Escaladores cruzados",
            alternatives: ["Burpees", "Plancha", "Jumping jacks"]),
        "Bird dog": Details(needs: [], load: .bodyweight, secondary: ["Espalda", "Glúteos"],
            mistakes: ["Girar la cadera al levantar la pierna.", "Arquear la espalda.", "Hacerlo con prisa."],
            easier: "Bird dog solo con brazos o solo con piernas", harder: "Bird dog con pausa de tres segundos",
            alternatives: ["Dead bug", "Plancha", "Hiperextensiones"]),

        // MARK: Cardio
        "Cinta de correr": Details(needs: [.cardio],
            mistakes: ["Agarrarse a las barras.", "Zancada larga aterrizando con el talón por delante.", "Mirar los pies."],
            easier: "Caminar con inclinación", harder: "Intervalos en cuesta",
            alternatives: ["Elíptica", "Bicicleta estática", "Comba"]),
        "Bicicleta estática": Details(needs: [.cardio],
            mistakes: ["Sillín muy bajo.", "Resistencia tan baja que solo das vueltas.", "Hombros encogidos."],
            easier: "Pedaleo suave", harder: "Intervalos de 30 s fuertes",
            alternatives: ["Elíptica", "Cinta de correr", "Remo"]),
        "Elíptica": Details(needs: [.cardio],
            mistakes: ["Apoyarse del todo en las asas.", "Ir de puntillas.", "Resistencia al mínimo."],
            easier: "Elíptica sin brazos", harder: "Elíptica con intervalos de resistencia",
            alternatives: ["Bicicleta estática", "Cinta de correr", "Remo"]),
        "Remo": Details(needs: [.cardio], secondary: ["Espalda", "Piernas"],
            mistakes: ["Tirar primero con los brazos.", "Redondear la espalda.", "Volver de golpe."],
            easier: "Remo suave a 20 paladas por minuto", harder: "Intervalos de 500 m",
            alternatives: ["Bicicleta estática", "Elíptica", "Burpees"]),
        "Burpees": Details(needs: [], load: .bodyweight, secondary: ["Pecho", "Piernas", "Core"],
            mistakes: ["Dejarse caer al suelo sin control.", "Cadera hundida en la plancha.", "Aterrizar con las rodillas bloqueadas."],
            easier: "Burpees sin salto ni flexión", harder: "Burpees con salto al pecho",
            alternatives: ["Escaladores", "Jumping jacks", "Comba"]),
        "Comba": Details(needs: [], load: .bodyweight, secondary: ["Piernas"],
            mistakes: ["Saltar demasiado alto.", "Girar con los brazos en vez de con las muñecas.", "Aterrizar con los talones."],
            easier: "Comba con pausas", harder: "Dobles saltos",
            alternatives: ["Jumping jacks", "Escaladores", "Cinta de correr"]),
        "Jumping jacks": Details(needs: [], load: .bodyweight,
            mistakes: ["Aterrizar con las piernas rígidas.", "Brazos a medias.", "Ir tan rápido que se pierde el ritmo."],
            easier: "Jumping jacks sin salto", harder: "Jumping jacks con sentadilla",
            alternatives: ["Comba", "Escaladores", "Burpees"]),

        // MARK: Movilidad
        "Gato-camello": Details(needs: [], load: .bodyweight,
            mistakes: ["Moverse solo en el cuello.", "Ir rápido.", "Aguantar la respiración."],
            easier: "Gato-camello sentado", harder: "Gato-camello con pausa en cada extremo",
            alternatives: ["Rotaciones torácicas", "Bird dog", "Dead bug"]),
        "Movilidad de cadera 90/90": Details(needs: [], load: .bodyweight,
            mistakes: ["Redondear la espalda.", "Forzar la rodilla en vez de la cadera.", "Rebotar para llegar más lejos."],
            easier: "90/90 con las manos apoyadas detrás", harder: "90/90 sin manos y cambiando de lado",
            alternatives: ["Estiramiento de isquiotibiales", "Movilidad de tobillo", "Gato-camello"]),
        "Rotaciones torácicas": Details(needs: [], load: .bodyweight,
            mistakes: ["Girar desde la cadera.", "Forzar el cuello.", "Hacerlo con prisa."],
            easier: "Rotaciones sentado", harder: "Rotaciones con pausa y respiración",
            alternatives: ["Gato-camello", "Dislocaciones de hombro con banda", "Bird dog"]),
        "Dislocaciones de hombro con banda": Details(needs: [.band], load: .bodyweight,
            mistakes: ["Agarre demasiado cerrado.", "Doblar los codos para pasar.", "Arquear la espalda al pasar por detrás."],
            easier: "Agarre más abierto", harder: "Agarre más cerrado, poco a poco",
            alternatives: ["Rotaciones torácicas", "Face pull", "Gato-camello"]),
        "Estiramiento de isquiotibiales": Details(needs: [], load: .bodyweight,
            mistakes: ["Redondear la espalda para llegar más abajo.", "Rebotar.", "Bloquear la rodilla con fuerza."],
            easier: "Con la rodilla un poco doblada", harder: "Con una banda y la pierna estirada tumbado",
            alternatives: ["Movilidad de cadera 90/90", "Peso muerto rumano", "Movilidad de tobillo"]),
        "Movilidad de tobillo": Details(needs: [], load: .bodyweight,
            mistakes: ["Levantar el talón.", "Rodilla que se va hacia dentro.", "Hacerlo con prisa."],
            easier: "Menos distancia a la pared", harder: "Más distancia a la pared o con peso en la rodilla",
            alternatives: ["Sentadilla sin peso", "Movilidad de cadera 90/90", "Estiramiento de isquiotibiales"]),
    ]
    // swiftlint:enable line_length
}

extension WorkoutViewModel {

    /// Alternativas que puedes hacer con el material activo, sin las que el
    /// perfil dice que prefieres evitar. Si no hay ninguna, las que haya.
    func alternatives(for name: String) -> [CatalogExercise] {
        guard let d = ExerciseLibrary.details(for: name) else { return [] }
        let avoid = Set(trainingProfile.avoidExercises.map(ExerciseLibrary.fold))
        let all = d.alternatives.compactMap(ExerciseCatalog.entry(named:)).filter { !avoid.contains(ExerciseLibrary.fold($0.name)) }
        let fitting = all.filter { ExerciseLibrary.fits($0.name, activeEquipment) }
        return fitting.isEmpty ? all : fitting
    }

    /// Un ejercicio de la biblioteca listo para usar: el tuyo si ya existe con
    /// ese nombre, si no uno nuevo con los valores de partida del catálogo.
    func exerciseFromCatalog(_ c: CatalogExercise) -> Exercise {
        if let mine = availableExercises.first(where: { ExerciseLibrary.fold($0.name) == ExerciseLibrary.fold(c.name)
                                                        || ExerciseLibrary.fold($0.name) == ExerciseLibrary.fold(c.name.loc) }) {
            return mine
        }
        let d = c.details
        let ex = Exercise(name: c.name.loc, repetitions: c.reps, weight: c.weight, totalSets: c.sets,
                          restDuration: defaultRestDuration, sfSymbolIcon: c.icon, iconColor: "accent",
                          segundos: c.reps == 0 ? max(5, c.seconds) : 0, muscleGroup: c.muscleGroup,
                          loadKind: d?.load ?? .total)
        availableExercises.append(ex)
        return ex
    }
}
