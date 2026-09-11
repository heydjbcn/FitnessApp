//
//  ExerciseVideos.swift
//  ChamaFit
//
//  Vídeo de técnica de cada ejercicio del catálogo. Los enlaces se eligieron
//  a mano y se comprueban con `scripts/check-videos.py` (oEmbed de YouTube);
//  si uno desaparece, la ficha cae a una búsqueda en YouTube.
//

import Foundation

enum ExerciseVideos {

    /// Generado por scripts/check-videos.py a partir de scripts/videos.json.
    static let byName: [String: String] = [
        "Abducción de cadera": "https://www.youtube.com/watch?v=2vCRMi-lgJ4",
        "Aperturas": "https://www.youtube.com/watch?v=OrlXQdNwNwM",
        "Bicicleta estática": "https://www.youtube.com/watch?v=UBCvUqrdz4o",
        "Bird dog": "https://www.youtube.com/watch?v=hUIrLbMnglY",
        "Burpees": "https://www.youtube.com/watch?v=Uy2nUNX38xE",
        "Cinta de correr": "https://www.youtube.com/watch?v=q8XOVDH60ss",
        "Comba": "https://www.youtube.com/watch?v=1J1v6wdIVqY",
        "Cruce de poleas": "https://www.youtube.com/watch?v=WNtBIde3Qks",
        "Crunch": "https://www.youtube.com/watch?v=oRIi-jKzCro",
        "Curl con banda": "https://www.youtube.com/watch?v=8fvk54V--CU",
        "Curl con barra": "https://www.youtube.com/watch?v=PY9QylAMtyE",
        "Curl con mancuernas": "https://www.youtube.com/watch?v=qERAhN-qpaU",
        "Curl concentrado": "https://www.youtube.com/watch?v=r8BYM4kNrHg",
        "Curl en polea": "https://www.youtube.com/watch?v=7Jc4jHxax60",
        "Curl femoral": "https://www.youtube.com/watch?v=-jeW_ToaRB8",
        "Curl martillo": "https://www.youtube.com/watch?v=8w3_KHigrh0",
        "Dead bug": "https://www.youtube.com/watch?v=0JFVLaTLzHg",
        "Dislocaciones de hombro con banda": "https://www.youtube.com/watch?v=D2KB1hMK4Ms",
        "Dominadas": "https://www.youtube.com/watch?v=A2thchjoWkI",
        "Dominadas asistidas": "https://www.youtube.com/watch?v=lgE47t3dr2Q",
        "Elevaciones frontales": "https://www.youtube.com/watch?v=joO2vLGujcA",
        "Elevaciones laterales": "https://www.youtube.com/watch?v=yUJN62SBW08",
        "Elevación de piernas": "https://www.youtube.com/watch?v=oxJj5FoBycQ",
        "Elíptica": "https://www.youtube.com/watch?v=wsG65DPE6uk",
        "Escaladores": "https://www.youtube.com/watch?v=mHg0OEUnLhw",
        "Estiramiento de isquiotibiales": "https://www.youtube.com/watch?v=qR6B2q5kmsY",
        "Extensiones en polea": "https://www.youtube.com/watch?v=dRkTreltpnc",
        "Extensión de cuádriceps": "https://www.youtube.com/watch?v=GMFFZnDz6wE",
        "Extensión de tríceps sobre la cabeza": "https://www.youtube.com/watch?v=fQ-KB40W3d8",
        "Face pull": "https://www.youtube.com/watch?v=X-xCQ1gh-kA",
        "Flexiones": "https://www.youtube.com/watch?v=25ORES59OmM",
        "Flexiones declinadas": "https://www.youtube.com/watch?v=WPX_mT4o278",
        "Flexiones diamante": "https://www.youtube.com/watch?v=PUgv7Fm2XW0",
        "Flexiones en pica": "https://www.youtube.com/watch?v=xMvv9gFxCBM",
        "Flexiones inclinadas": "https://www.youtube.com/watch?v=tdplefUYz2I",
        "Fondos": "https://www.youtube.com/watch?v=DcS44T6Y5GQ",
        "Fondos en banco": "https://www.youtube.com/watch?v=EZSjDiiTi2o",
        "Gato-camello": "https://www.youtube.com/watch?v=8DN9X_KDrrY",
        "Gemelos de pie": "https://www.youtube.com/watch?v=XvHhG4E4tDo",
        "Gemelos sentado": "https://www.youtube.com/watch?v=haZRssrNG_M",
        "Hip thrust": "https://www.youtube.com/watch?v=zIIl1CINi84",
        "Hiperextensiones": "https://www.youtube.com/watch?v=nMiVlx_gUzQ",
        "Jalón al pecho": "https://www.youtube.com/watch?v=72q0tKij5uU",
        "Jumping jacks": "https://www.youtube.com/watch?v=EjYFRsiWlWI",
        "Movilidad de cadera 90/90": "https://www.youtube.com/watch?v=adRzu0Vz37s",
        "Movilidad de tobillo": "https://www.youtube.com/watch?v=y4GDtIfjqlM",
        "Pallof press": "https://www.youtube.com/watch?v=c-byXbLkWzY",
        "Paso lateral con banda": "https://www.youtube.com/watch?v=lrjsiOo0c5I",
        "Patada de glúteo": "https://www.youtube.com/watch?v=cZ_PxaP6MKY",
        "Patada de tríceps": "https://www.youtube.com/watch?v=eO0vfxnCcLk",
        "Peso muerto": "https://www.youtube.com/watch?v=qO87pkO3E2E",
        "Peso muerto rumano": "https://www.youtube.com/watch?v=rjvlSfZ-PQw",
        "Plancha": "https://www.youtube.com/watch?v=zfY5XXa26ug",
        "Plancha lateral": "https://www.youtube.com/watch?v=euvthEjjuio",
        "Prensa": "https://www.youtube.com/watch?v=xvCynwyNoP4",
        "Press Arnold": "https://www.youtube.com/watch?v=l5tNUbpusCA",
        "Press de banca": "https://www.youtube.com/watch?v=fqsTgdTPRQU",
        "Press de banca agarre cerrado": "https://www.youtube.com/watch?v=gDSJb6mwJg4",
        "Press de banca con mancuernas": "https://www.youtube.com/watch?v=VbsK3Mmkguc",
        "Press de hombros con mancuernas": "https://www.youtube.com/watch?v=o5M9RZ-vWrc",
        "Press de pecho en máquina": "https://www.youtube.com/watch?v=N7DjfGB8-xY",
        "Press francés": "https://www.youtube.com/watch?v=rSFXvdNnxms",
        "Press inclinado mancuernas": "https://www.youtube.com/watch?v=MkMf308jXww",
        "Press militar": "https://www.youtube.com/watch?v=xM2FGQuhZAY",
        "Puente de glúteo": "https://www.youtube.com/watch?v=oDXM-a-gBt8",
        "Puente de glúteo a una pierna": "https://www.youtube.com/watch?v=pBM5Mwk6KL0",
        "Pullover en polea": "https://www.youtube.com/watch?v=9YQ1YXKko8s",
        "Pájaros": "https://www.youtube.com/watch?v=RG_41P2hP0s",
        "Remo": "https://www.youtube.com/watch?v=ln9-nno3mMU",
        "Remo con barra": "https://www.youtube.com/watch?v=3uiWjik2yEQ",
        "Remo con mancuerna": "https://www.youtube.com/watch?v=Pkr1WW3p05A",
        "Remo en máquina": "https://www.youtube.com/watch?v=VWyhefUKTp4",
        "Remo invertido": "https://www.youtube.com/watch?v=AIM_qZjSFUU",
        "Rotaciones torácicas": "https://www.youtube.com/watch?v=5kwx1UU5exI",
        "Rueda abdominal": "https://www.youtube.com/watch?v=76uV2p-733k",
        "Russian twist": "https://www.youtube.com/watch?v=zxeb00EIRg8",
        "Sentadilla": "https://www.youtube.com/watch?v=qsAkuNORgmk",
        "Sentadilla búlgara": "https://www.youtube.com/watch?v=Yia9exzp7Vg",
        "Sentadilla goblet": "https://www.youtube.com/watch?v=FgnAl9Yx4c4",
        "Sentadilla sin peso": "https://www.youtube.com/watch?v=BjixzWEw4EY",
        "Subida al banco": "https://www.youtube.com/watch?v=CpKJ1B4iNwc",
        "Swing con kettlebell": "https://www.youtube.com/watch?v=3YDtpRWJISI",
        "Zancadas": "https://www.youtube.com/watch?v=uqvt79Uh4o4",
    ]

    /// El vídeo propio, el del catálogo o una búsqueda.
    static func url(for exercise: Exercise) -> URL {
        if let own = exercise.videoURL.flatMap(URL.init(string:)), own.scheme?.hasPrefix("http") == true { return own }
        return url(forName: exercise.name)
    }

    static func url(forName name: String) -> URL {
        if let link = catalogLink(for: name), let u = URL(string: link) { return u }
        return searchURL(name)
    }

    static func catalogLink(for raw: String) -> String? {
        let name = ExerciseCatalog.canonicalName(raw)
        if let l = byName[name] { return l }
        let key = ExerciseLibrary.fold(name)
        return byName.first { ExerciseLibrary.fold($0.key) == key }?.value
    }

    static func searchURL(_ name: String) -> URL {
        let q = "\(name) técnica".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        return URL(string: "https://www.youtube.com/results?search_query=\(q)")!
    }

    /// Lo que pega el usuario: con o sin https, recortado. nil si no parece un enlace.
    static func normalized(_ text: String) -> String? {
        var t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !t.contains(" ") else { return nil }
        if !t.lowercased().hasPrefix("http") { t = "https://" + t }
        guard let u = URL(string: t), u.host?.contains(".") == true else { return nil }
        return u.absoluteString
    }
}
