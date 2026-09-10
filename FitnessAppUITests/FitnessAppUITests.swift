//
//  FitnessAppUITests.swift
//  ChamaFit
//
//  Batería de UI que recorre cada función de la app en el iPhone real como
//  lo haría un dedo. La app arranca con `--ui-tests`: dominio de datos
//  aparte (los datos reales no se tocan) y sin avisos del sistema.
//  Si la app se cae en cualquier punto, el test falla con el crash adjunto.
//
//  `LightModeUITests` repite toda la batería en modo claro y deja capturas.
//

import XCTest

class ChamaFitUITests: XCTestCase {

    var app: XCUIApplication!

    /// Argumentos extra de la subclase (modo claro).
    class var extra: [String] { [] }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        if let app { snap("final"); app.terminate() }
    }

    // MARK: - Arranque y utilidades

    @discardableResult
    func launch(_ args: [String] = ["--named", "--seed-sample"]) -> XCUIApplication {
        let a = XCUIApplication()
        a.launchArguments = ["--ui-tests"] + args + Self.extra
        a.launch()
        app = a
        XCTAssertTrue(a.tabBars.firstMatch.waitForExistence(timeout: 15) || a.textFields.firstMatch.waitForExistence(timeout: 5),
                      "la app no ha arrancado")
        return a
    }

    func relaunch() {
        let args = app.launchArguments.filter { $0 != "--keep" } + ["--keep"]
        app.terminate()
        let a = XCUIApplication()
        a.launchArguments = args
        a.launch()
        app = a
        XCTAssertTrue(a.tabBars.firstMatch.waitForExistence(timeout: 15))
    }

    func tab(_ name: String) {
        let b = app.tabBars.buttons[name]
        XCTAssertTrue(b.waitForExistence(timeout: 5), "pestaña \(name)")
        b.tap()
    }

    func snap(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "\(Self.extra.contains("--light") ? "claro" : "oscuro")-\(self.name)-\(name)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// Espera y toca. Si el elemento está fuera de pantalla, hace scroll hasta encontrarlo.
    func tap(_ element: XCUIElement, timeout: TimeInterval = 8, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "no existe \(element)", file: file, line: line)
        scrollTo(element)
        element.tap()
    }

    func scrollTo(_ element: XCUIElement, maxSwipes: Int = 8) {
        var tries = 0
        while !element.isHittable && tries < maxSwipes {
            app.swipeUp(velocity: .slow)
            tries += 1
        }
        if !element.isHittable {
            tries = 0
            while !element.isHittable && tries < maxSwipes * 2 {
                app.swipeDown(velocity: .slow)
                tries += 1
            }
        }
    }

    func exists(_ element: XCUIElement, _ timeout: TimeInterval = 5) -> Bool {
        element.waitForExistence(timeout: timeout)
    }

    func assertGone(_ element: XCUIElement, _ timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [gone], timeout: timeout), .completed, "sigue en pantalla: \(element)", file: file, line: line)
    }

    func type(_ text: String, into field: XCUIElement) {
        tap(field)
        field.typeText(text)
    }

    func clearAndType(_ text: String, into field: XCUIElement) {
        tap(field)
        if let current = field.value as? String, !current.isEmpty {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count + 2))
        }
        field.typeText(text)
    }

    func dismissKeyboard() {
        if app.keyboards.firstMatch.exists {
            let done = app.keyboards.buttons["Listo"].exists ? app.keyboards.buttons["Listo"]
                : app.keyboards.buttons["Done"].exists ? app.keyboards.buttons["Done"]
                : app.keyboards.buttons["Return"]
            if done.exists { done.tap() } else { app.swipeDown() }
        }
    }

    func closeSheet() {
        let close = app.buttons["sheet.close"]
        if close.waitForExistence(timeout: 3) {
            close.firstMatch.tap()
        } else {
            app.swipeDown(velocity: .fast)
        }
    }

    /// Cierra la hoja de compartir del sistema (CSV / copia) si ha aparecido.
    func dismissShareSheet() {
        let closers = [app.buttons["Close"], app.buttons["Cerrar"], app.navigationBars.buttons.firstMatch]
        sleep(2)
        for c in closers where c.exists && c.isHittable { c.tap(); return }
        app.swipeDown(velocity: .fast)
    }

    var today: Date { Calendar.current.startOfDay(for: Date()) }
    func stamp(_ date: Date) -> String {
        let f = DateFormatter(); f.calendar = Calendar(identifier: .gregorian); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
    func daysAgo(_ n: Int) -> Date { Calendar.current.date(byAdding: .day, value: -n, to: today)! }
    /// Primer día (hacia atrás) que tenga rutina de ejemplo (lunes, miércoles o viernes).
    func lastRoutineDay() -> Date {
        for back in 1...7 {
            let d = daysAgo(back)
            if [2, 4, 6].contains(Calendar.current.component(.weekday, from: d)) { return d }
        }
        return daysAgo(1)
    }
    /// Un día reciente sin rutina (martes, jueves, sábado o domingo).
    func lastRestDay() -> Date {
        for back in 1...7 {
            let d = daysAgo(back)
            if ![2, 4, 6].contains(Calendar.current.component(.weekday, from: d)) { return d }
        }
        return daysAgo(1)
    }

    // MARK: - 1. Primer arranque: bienvenida y tutorial

    func test01_FirstLaunchWelcomeAndTutorial() {
        launch(["--reset"])
        let name = app.textFields.firstMatch
        XCTAssertTrue(name.waitForExistence(timeout: 10), "pantalla de bienvenida")
        XCTAssertFalse(app.buttons["Continuar"].isEnabled, "sin nombre no se puede continuar")
        type("Tester", into: name)
        tap(app.buttons["Continuar"])

        XCTAssertTrue(exists(app.staticTexts["¡Bienvenido!"], 8), "el tutorial arranca solo")
        tap(app.buttons["Atajo: cargar rutina de ejemplo"])
        tap(app.buttons["Siguiente"])                          // create
        XCTAssertTrue(exists(app.staticTexts["Crear ejercicio"]))
        tap(app.buttons["Crear ejercicio ahora"])
        XCTAssertTrue(exists(app.buttons["Siguiente"].firstMatch))
        closeSheet()                                           // vuelve al tutorial en "Ejercicio creado"
        XCTAssertTrue(exists(app.staticTexts["Ejercicio creado"], 8))
        tap(app.buttons["Anterior"])
        XCTAssertTrue(exists(app.staticTexts["Seleccionar días"]))
        tap(app.buttons["Siguiente"])
        tap(app.buttons["Siguiente"])                          // calendar
        XCTAssertTrue(exists(app.staticTexts["En el calendario"]))
        tap(app.buttons["Siguiente"])                          // sets
        tap(app.buttons["Siguiente"])                          // done
        XCTAssertTrue(exists(app.staticTexts["¡Listo!"]))
        tap(app.buttons["¡A entrenar!"])
        assertGone(app.staticTexts["¡Listo!"])
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Tester'")).firstMatch.waitForExistence(timeout: 5),
                      "el saludo lleva el nombre")

        // Relanzar: el nombre se recuerda, no vuelve la bienvenida.
        relaunch()
        XCTAssertFalse(app.buttons["Continuar"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Tester'")).firstMatch.exists)

        // "Saltar" desde Ajustes.
        tab("Ajustes")
        tap(app.buttons["Ver tutorial y empezar"])
        XCTAssertTrue(exists(app.staticTexts["¡Bienvenido!"]))
        tap(app.buttons["Saltar"])
        assertGone(app.staticTexts["¡Bienvenido!"])
    }

    // MARK: - 2. Inicio: series, deshacer, editor rápido, descanso

    func test02_HomeSetsUndoQuickEditorAndTimer() {
        launch()
        tap(app.buttons["day.Lunes"])
        let s1 = app.buttons["set.Press de banca.1"]
        let s2 = app.buttons["set.Press de banca.2"]
        tap(s1)
        XCTAssertEqual(s1.value as? String, "hecha")
        let timer = app.otherElements["timer.card"]
        XCTAssertTrue(exists(timer), "el descanso arranca al marcar")
        let clock = app.staticTexts["timer.clock"]
        let before = clock.label
        tap(app.buttons["timer.extend"])
        sleep(1)
        XCTAssertNotEqual(clock.label, "", "reloj visible")
        _ = before
        tap(app.buttons["timer.stop"])
        assertGone(timer)

        // Marcar la 2 y deshacerla tocándola otra vez.
        tap(s2)
        XCTAssertEqual(s2.value as? String, "hecha")
        if exists(app.buttons["timer.stop"], 3) { app.buttons["timer.stop"].tap() }
        tap(s2)
        XCTAssertEqual(s2.value as? String, "pendiente")
        XCTAssertEqual(s1.value as? String, "hecha")

        // Pulsación larga en la 2: editor rápido para marcar con otros datos.
        scrollTo(s2)
        s2.press(forDuration: 0.8)
        XCTAssertTrue(exists(app.staticTexts["Serie 2 · marcar"]), "editor rápido")
        tap(app.buttons["quick.Peso.plus"])
        tap(app.buttons["+1"])
        tap(app.buttons["quick.Repeticiones.minus"])
        tap(app.buttons["−5"])
        tap(app.buttons["Al fallo"])
        tap(app.buttons["9"])
        tap(app.buttons["9"])                                  // quitar el RPE
        tap(app.buttons["8"])
        tap(app.buttons["Marcar serie"])
        XCTAssertEqual(s2.value as? String, "hecha")
        if exists(app.buttons["timer.stop"], 3) { app.buttons["timer.stop"].tap() }

        // Editar la serie 1 ya hecha.
        scrollTo(s1)
        s1.press(forDuration: 0.8)
        XCTAssertTrue(exists(app.staticTexts["Serie 1 · editar"]))
        tap(app.buttons["Calentamiento"])
        tap(app.buttons["Guardar"])
        assertGone(app.staticTexts["Serie 1 · editar"])

        // Descanso manual desde la tarjeta y volver a hoy.
        tap(app.buttons["rest.Press de banca"])
        XCTAssertTrue(exists(timer))
        tap(app.buttons["timer.stop"])
        tap(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Volver a hoy'")).firstMatch)
        XCTAssertEqual(app.buttons["day.Lunes"].value as? String, "2", "Lunes deja de estar seleccionado")
        snap("inicio")

        // La cabecera de sesión enseña progreso.
        tap(app.buttons["day.Lunes"])
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '2/'")).firstMatch.exists
                      || app.staticTexts["2"].exists)
    }

    // MARK: - 3. Inicio vacío y rutina de ejemplo

    func test03_EmptyHomeLoadsSample() {
        launch(["--named"])
        XCTAssertTrue(exists(app.buttons["Cargar rutina de ejemplo"], 8), "estado vacío")
        tap(app.buttons["Cargar rutina de ejemplo"])
        XCTAssertTrue(exists(app.buttons["day.Lunes"]))
        tap(app.buttons["day.Viernes"])
        XCTAssertTrue(exists(app.buttons["set.Sentadilla.1"]))
        tab("Ejercicios")
        XCTAssertTrue(exists(app.staticTexts["15 en tu biblioteca"]))
        snap("ejercicios")
    }

    // MARK: - 4. Superserie

    func test04_Superset() {
        launch()
        tap(app.buttons["day.Lunes"])
        tap(app.buttons["info.Press de banca"])
        tap(app.buttons["+ Superserie"])
        tap(app.buttons["Superserie A"])
        XCTAssertTrue(exists(app.buttons["Superserie A"]))
        closeSheet()
        tap(app.buttons["info.Aperturas"])
        tap(app.buttons["+ Superserie"])
        tap(app.buttons["Superserie A"])
        closeSheet()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Superserie A'")).firstMatch.waitForExistence(timeout: 5),
                      "cabecera del grupo en Inicio")
        tap(app.buttons["set.Press de banca.1"])
        XCTAssertFalse(app.otherElements["timer.card"].waitForExistence(timeout: 2), "sin descanso: falta la pareja")
        tap(app.buttons["set.Aperturas.1"])
        XCTAssertTrue(exists(app.otherElements["timer.card"]), "vuelta cerrada: descanso")
        tap(app.buttons["timer.stop"])
        snap("superserie")
        // Quitar la superserie.
        tap(app.buttons["info.Press de banca"])
        tap(app.buttons["Superserie A"].firstMatch)
        tap(app.buttons["Sin superserie"])
        closeSheet()
    }

    // MARK: - 5. Alta, edición y borrado de ejercicio

    func test05_ExerciseFormCreateEditDelete() {
        launch()
        tab("Ejercicios")
        tap(app.buttons["Nuevo"])
        XCTAssertFalse(app.buttons["Siguiente"].isEnabled, "sin nombre no avanza")

        // Catálogo: buscar, sin resultados, limpiar, filtrar y elegir.
        tap(app.buttons["Elegir del catálogo"])
        let search = app.textFields.firstMatch
        type("zzzz", into: search)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Nada con'")).firstMatch.waitForExistence(timeout: 3))
        dismissKeyboard()
        clearAndType("", into: search)
        dismissKeyboard()
        tap(app.buttons["Pecho"])
        tap(app.buttons["Fondos"].firstMatch)
        XCTAssertEqual(app.textFields.firstMatch.value as? String, "Fondos")
        tap(app.buttons["Siguiente"])

        // Días: ninguno → no avanza; uno → avanza.
        XCTAssertFalse(app.buttons["Siguiente"].isEnabled)
        tap(app.buttons["Lun"])
        tap(app.buttons["Siguiente"])
        // Icono.
        tap(app.buttons["Siguiente"])
        // Parámetros: extremos de los steppers.
        let plus = app.buttons["+"].firstMatch
        let minus = app.buttons["−"].firstMatch
        for _ in 0..<3 { tap(plus) }
        for _ in 0..<40 { minus.tap() }
        for _ in 0..<40 { plus.tap() }
        tap(app.buttons["Siguiente"])
        // Descanso: a cero y de vuelta.
        XCTAssertTrue(exists(app.staticTexts["Descanso entre series"]))
        let minDown = app.buttons["rest.min.down"], minUp = app.buttons["rest.min.up"]
        let secDown = app.buttons["rest.sec.down"], secUp = app.buttons["rest.sec.up"]
        for _ in 0..<12 { minDown.tap() }
        for _ in 0..<5 { secDown.tap() }
        XCTAssertTrue(app.staticTexts["Sin descanso"].exists || app.staticTexts["0:45"].exists)
        for _ in 0..<12 { minUp.tap() }
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '10:'")).firstMatch.exists, "tope de 10 min")
        for _ in 0..<9 { minDown.tap() }
        for _ in 0..<5 { secUp.tap() }
        tap(app.buttons["Guardar ejercicio"])
        XCTAssertTrue(exists(app.staticTexts["Fondos"].firstMatch), "aparece en la biblioteca")
        XCTAssertTrue(exists(app.staticTexts["16 en tu biblioteca"]))

        // Editar desde el detalle y borrar.
        tap(app.staticTexts["Fondos"].firstMatch)
        tap(app.buttons["Editar ejercicio"])
        let field = app.textFields.firstMatch
        clearAndType("Fondos en paralelas", into: field)
        dismissKeyboard()
        for _ in 0..<4 { tap(app.buttons["Siguiente"]) }
        tap(app.buttons["Guardar ejercicio"])
        XCTAssertTrue(exists(app.staticTexts["Fondos en paralelas"].firstMatch, 8))
        closeSheet()
        XCTAssertTrue(exists(app.staticTexts["Fondos en paralelas"].firstMatch, 8))

        tap(app.staticTexts["Fondos en paralelas"].firstMatch)
        tap(app.buttons["Editar ejercicio"])
        for _ in 0..<4 { tap(app.buttons["Siguiente"]) }
        tap(app.buttons["Eliminar ejercicio"].firstMatch)
        tap(app.sheets.buttons["Eliminar ejercicio"].firstMatch)
        XCTAssertTrue(exists(app.staticTexts["Ejercicio no disponible"], 8) || exists(app.staticTexts["15 en tu biblioteca"], 8))
        if app.buttons["sheet.close"].exists { closeSheet() }
        XCTAssertTrue(exists(app.staticTexts["15 en tu biblioteca"], 8))
        snap("biblioteca")

        // Nuevo desde cero con nombre escrito a mano y cerrar sin guardar.
        tap(app.buttons["Nuevo"])
        type("Prueba", into: app.textFields.firstMatch)
        dismissKeyboard()
        tap(app.buttons["Atrás"])
        XCTAssertTrue(exists(app.staticTexts["15 en tu biblioteca"]))
    }

    // MARK: - 6. Calendario: semana, nombres, reordenar, duplicar, rutinas, mes

    func test06_CalendarRoutinesAndMonth() {
        launch()
        tab("Calendario")
        tap(app.staticTexts["Lunes"].firstMatch)
        tap(app.buttons["Renombrar"])
        let field = app.textFields.firstMatch
        clearAndType("Pecho fuerte", into: field)
        tap(app.buttons["Guardar"])
        XCTAssertTrue(exists(app.staticTexts["Pecho fuerte"]))

        tap(app.buttons["Reordenar"])
        tap(app.buttons["reorder.down.0"])
        tap(app.buttons["reorder.up.4"])
        tap(app.buttons["Listo"])

        tap(app.buttons["Duplicar este día en otro"])
        tap(app.buttons["Copiar al jueves"])
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '5 ejercicios'")).count >= 2)

        tap(app.buttons["Entrenar este día"])
        XCTAssertTrue(exists(app.buttons["set.Press de banca.1"]), "Inicio en el lunes")
        tab("Calendario")

        // Rutinas: nueva vacía, volver a la primera, renombrar, borrar.
        tap(app.staticTexts["Mi rutina"])
        tap(app.buttons["Nueva rutina…"])
        let alertField = app.alerts.textFields.firstMatch
        XCTAssertTrue(alertField.waitForExistence(timeout: 5))
        alertField.tap()
        alertField.typeText("Fuerza")
        tap(app.alerts.buttons["Vacía"])
        XCTAssertTrue(exists(app.staticTexts["Fuerza"]))
        XCTAssertTrue(app.staticTexts["Día libre · sin ejercicios"].firstMatch.exists)

        tap(app.staticTexts["Fuerza"])
        tap(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Mi rutina'")).firstMatch)
        XCTAssertTrue(exists(app.staticTexts["Mi rutina"]))
        XCTAssertTrue(exists(app.staticTexts["Pecho fuerte"]))

        tap(app.staticTexts["Mi rutina"])
        tap(app.buttons["Renombrar la actual…"])
        let rename = app.alerts.textFields.firstMatch
        XCTAssertTrue(rename.waitForExistence(timeout: 5))
        rename.tap()
        rename.typeText(" base")
        tap(app.alerts.buttons["Guardar"])
        XCTAssertTrue(exists(app.staticTexts["Mi rutina base"]))

        tap(app.staticTexts["Mi rutina base"])
        tap(app.buttons["Fuerza"].firstMatch)                  // sección Eliminar
        tap(app.sheets.buttons["Eliminar rutina"])
        tap(app.staticTexts["Mi rutina base"])
        XCTAssertFalse(app.buttons["Fuerza"].waitForExistence(timeout: 2))
        app.tap()                                              // cerrar el menú
        snap("calendario-semana")

        // Mes.
        tap(app.buttons["Mes"])
        for _ in 0..<4 { tap(app.buttons["month.prev"]) }
        for _ in 0..<8 { tap(app.buttons["month.next"]) }
        for _ in 0..<4 { tap(app.buttons["month.prev"]) }
        tap(app.buttons["cal.\(stamp(today))"])
        XCTAssertTrue(exists(app.staticTexts["Día libre · sin ejercicios"].firstMatch) ||
                      app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Rutina del'")).firstMatch.exists)
        tap(app.buttons["cal.\(stamp(lastRestDay()))"])
        snap("calendario-mes")
        tap(app.buttons["Semana"])
    }

    // MARK: - 7. Historial

    func test07_History() {
        launch(["--named", "--seed-history"])
        tab("Historial")
        XCTAssertTrue(exists(app.staticTexts["Esta semana"], 8))

        // Peso corporal.
        tap(app.buttons["Editar"].firstMatch)
        let field = app.textFields.firstMatch
        clearAndType("70,5", into: field)
        tap(app.buttons["Guardar"].firstMatch)
        XCTAssertTrue(exists(app.staticTexts["70,5 kg"]))
        tap(app.buttons["Editar"].firstMatch)
        clearAndType("abc", into: app.textFields.firstMatch)
        tap(app.buttons["Guardar"].firstMatch)
        XCTAssertTrue(exists(app.staticTexts["70,5 kg"]), "un valor inválido no pisa el peso")

        // Nota.
        let noteButton = app.buttons["Añadir nota"].exists ? app.buttons["Añadir nota"] : app.buttons.matching(identifier: "Editar").element(boundBy: 1)
        tap(noteButton)
        let editor = app.textViews.firstMatch
        tap(editor)
        editor.typeText("Sesión de prueba")
        dismissKeyboard()
        tap(app.buttons["Guardar"].firstMatch)
        XCTAssertTrue(exists(app.staticTexts["Sesión de prueba"]))
        tap(app.buttons.matching(identifier: "Editar").element(boundBy: 1))
        tap(app.buttons["✕"])
        XCTAssertTrue(app.staticTexts["Sesión de prueba"].exists, "cancelar no borra")

        // Un día entrenado: filas, detalle y borrar.
        let trained = lastRoutineDay()
        tap(app.buttons["cal.\(stamp(trained))"])
        XCTAssertEqual(app.buttons["cal.\(stamp(trained))"].value as? String, "entrenado")
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS 'series'")).firstMatch
        tap(row)
        XCTAssertTrue(exists(app.buttons["Calculadora de discos"]))
        closeSheet()
        tap(app.buttons["Borrar historial del día"])
        tap(app.sheets.buttons["Borrar historial del día"])
        XCTAssertTrue(exists(app.staticTexts["No hay ejercicios completados"]))
        XCTAssertEqual(app.buttons["cal.\(stamp(trained))"].value as? String, "")

        // Un día sin rutina.
        tap(app.buttons["cal.\(stamp(lastRestDay()))"])
        XCTAssertTrue(exists(app.staticTexts["No hay ejercicios completados"]))
        XCTAssertFalse(app.buttons["Borrar historial del día"].exists)

        // Récords → detalle.
        let record = app.buttons.matching(NSPredicate(format: "label CONTAINS 'kg'")).allElementsBoundByIndex.last
        if let record { tap(record); XCTAssertTrue(exists(app.buttons["Calculadora de discos"])); closeSheet() }
        snap("historial")
    }

    // MARK: - 8. Detalle: series de hoy, calculadora, gráfica

    func test08_DetailPlatesAndChart() {
        launch(["--named", "--seed-history"])
        tap(app.buttons["day.Lunes"])
        tap(app.buttons["set.Press de banca.1"])
        if exists(app.buttons["timer.stop"], 3) { app.buttons["timer.stop"].tap() }
        tap(app.buttons["info.Press de banca"])
        XCTAssertTrue(exists(app.staticTexts["Series de hoy"]))
        // Editar la serie de hoy desde la fila.
        let kg = app.textFields.firstMatch
        clearAndType("52,5", into: kg)
        dismissKeyboard()
        tap(app.buttons["1"].firstMatch)                       // menú de tipo
        tap(app.buttons["Drop set"])
        XCTAssertTrue(exists(app.staticTexts["D"]))

        // Gráfica.
        tap(app.buttons["Volumen"])
        tap(app.buttons["1RM"])
        tap(app.buttons["Peso máx"])

        // Calculadora de discos.
        tap(app.buttons["Calculadora de discos"])
        for _ in 0..<30 { app.buttons["−5"].tap() }
        XCTAssertTrue(exists(app.staticTexts["Sube el peso objetivo."]))
        for _ in 0..<3 { tap(app.buttons["+5"]) }
        XCTAssertTrue(exists(app.staticTexts["El objetivo es igual o menor que la barra."]))
        for _ in 0..<20 { app.buttons["+5"].tap() }
        tap(app.buttons["20 kg"])
        tap(app.buttons["15 kg"])
        tap(app.buttons["10 kg"])
        snap("discos")
        closeSheet()
        XCTAssertTrue(exists(app.buttons["Editar ejercicio"]))
        closeSheet()
    }

    // MARK: - 9. Ajustes

    func test09_Settings() {
        launch()
        tab("Ajustes")
        for title in ["Timer de descanso", "Mantener pantalla encendida", "Modo de enfoque automático", "Vibración"] {
            let t = app.buttons["toggle.\(title)"]
            tap(t)
            let v1 = t.value as? String
            tap(t)
            XCTAssertNotEqual(v1, t.value as? String, "\(title) cambia")
        }
        tap(app.buttons["toggle.Timer de descanso"])           // apagado
        tap(app.buttons["3:00"])
        tap(app.buttons["30 s"])
        tap(app.buttons["Claro"])
        tap(app.buttons["Oscuro"])
        tap(app.buttons["Claro"])
        for accent in ["Coral", "Lima", "Rosa", "Ámbar", "Azul", "Violeta"] { tap(app.buttons[accent]) }
        snap("ajustes-claro")
        tap(app.buttons["Oscuro"])

        // Perfil: nombre vacío bloquea, IMC.
        tap(app.staticTexts["Tester"])
        let name = app.textFields.firstMatch
        clearAndType("", into: name)
        XCTAssertFalse(app.buttons["Guardar"].isEnabled)
        name.typeText("Tester")
        dismissKeyboard()
        clearAndType("180", into: app.textFields.element(boundBy: 2))
        dismissKeyboard()
        clearAndType("80", into: app.textFields.element(boundBy: 3))
        dismissKeyboard()
        XCTAssertTrue(exists(app.staticTexts["Índice de masa corporal"]))
        XCTAssertTrue(exists(app.staticTexts["Peso normal"]))
        tap(app.buttons["Guardar"])
        XCTAssertTrue(exists(app.staticTexts["180 cm · 80 kg"]))

        // Notificaciones.
        tap(app.staticTexts["Notificaciones"])
        XCTAssertTrue(exists(app.staticTexts["No hay notificaciones"]))
        closeSheet()

        // Coach IA sin key: guardar y quitar.
        tap(app.staticTexts["Coach IA"])
        XCTAssertTrue(exists(app.staticTexts["Activa el Coach IA"]))
        XCTAssertFalse(app.buttons["Guardar y activar"].isEnabled)
        let key = app.secureTextFields.firstMatch
        type("sk-ant-prueba", into: key)
        dismissKeyboard()
        tap(app.buttons["Guardar y activar"])
        XCTAssertTrue(exists(app.textViews.firstMatch) || exists(app.textFields.firstMatch))
        closeSheet()
        tap(app.staticTexts["Coach IA"])
        // Con key el chat sale directo; el botón de la llave vuelve a la pantalla de la key.
        if !app.staticTexts["Activa el Coach IA"].exists {
            let keyButton = app.buttons.matching(NSPredicate(format: "label == 'key' OR label == 'key.fill' OR label == 'Key'")).firstMatch
            if keyButton.exists { keyButton.tap() }
        }
        if exists(app.buttons["Quitar la key"], 3) { tap(app.buttons["Quitar la key"]) }
        closeSheet()

        // Compartir CSV y copia: se abre la hoja del sistema y se cierra.
        tap(app.staticTexts["Exportar entrenamientos"])
        dismissShareSheet()
        tap(app.staticTexts["Copia de seguridad"])
        dismissShareSheet()
        tap(app.staticTexts["Restaurar copia"])
        sleep(2)
        for c in [app.buttons["Cancelar"], app.buttons["Cancel"]] where c.exists { c.tap(); break }

        // Persistencia de ajustes tras relanzar.
        relaunch()
        tab("Ajustes")
        XCTAssertEqual(app.buttons["toggle.Timer de descanso"].value as? String, "0")
        XCTAssertTrue(app.staticTexts["180 cm · 80 kg"].exists)

        // Borrar todos los datos: la app queda vacía, el perfil se queda.
        tap(app.staticTexts["Borrar todos los datos"])
        tap(app.sheets.buttons["Borrar ejercicios, rutina e historial"])
        tab("Ejercicios")
        XCTAssertTrue(exists(app.staticTexts["Aún no hay ejercicios"]))
        tab("Ajustes")
        XCTAssertTrue(app.staticTexts["Tester"].exists)
        snap("ajustes")
    }

    // MARK: - 10. Ciclo de vida: fondo, relanzar, cambiar de pestaña a lo bruto

    func test10_Lifecycle() {
        launch()
        tap(app.buttons["day.Lunes"])
        tap(app.buttons["set.Press de banca.1"])
        XCTAssertTrue(exists(app.otherElements["timer.card"]))
        let clock = app.staticTexts["timer.clock"]
        let before = clock.label
        XCUIDevice.shared.press(.home)
        sleep(6)
        app.activate()
        XCTAssertTrue(exists(app.otherElements["timer.card"], 8), "el descanso sigue al volver")
        XCTAssertNotEqual(clock.label, before, "el reloj ha avanzado contra el reloj de pared")
        tap(app.buttons["timer.stop"])

        for _ in 0..<6 {
            for t in ["Calendario", "Ejercicios", "Historial", "Ajustes", "Inicio"] { app.tabBars.buttons[t].tap() }
        }
        // Abrir y cerrar hojas repetidas veces.
        for _ in 0..<3 {
            tap(app.buttons["info.Press de banca"])
            closeSheet()
            tab("Ejercicios")
            tap(app.buttons["Nuevo"])
            closeSheet()
            tab("Inicio")
        }
        for _ in 0..<4 { relaunch(); XCTAssertTrue(exists(app.tabBars.firstMatch)) }
        XCTAssertEqual(app.buttons["set.Press de banca.1"].value as? String, "hecha", "la serie marcada sobrevive a los relanzamientos")
        snap("lifecycle")
    }
}

/// Toda la batería otra vez en modo claro (repaso visual: las capturas quedan adjuntas).
final class LightModeUITests: ChamaFitUITests {
    override class var extra: [String] { ["--light"] }
}
