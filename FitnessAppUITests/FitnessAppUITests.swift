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

    /// Espera y toca. Si el elemento está fuera de pantalla (o aún no existe
    /// porque la lista es perezosa), hace scroll hasta encontrarlo.
    func tap(_ element: XCUIElement, timeout: TimeInterval = 8, file: StaticString = #filePath, line: UInt = #line) {
        if !element.waitForExistence(timeout: min(timeout, 3)) { search(element) }
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "no existe \(element)", file: file, line: line)
        // Si está en pantalla pero animándose (una hoja que sube), se espera un poco antes de hacer scroll.
        if !element.isHittable {
            let hittable = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: element)
            _ = XCTWaiter().wait(for: [hittable], timeout: 2)
        }
        if !element.isHittable { scrollTo(element) }
        if element.isHittable { element.tap() } else { forceTap(element) }
    }

    /// Elige un día en la tira de Inicio y comprueba que ha quedado elegido
    /// (un toque durante la animación de arranque a veces no llega).
    func selectDay(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
        let chip = app.buttons["day.\(name)"]
        for _ in 0..<3 {
            tap(chip, file: file, line: line)
            if chip.value as? String == "seleccionado" { return }
            sleep(1)
            if chip.value as? String == "seleccionado" { return }
        }
        XCTFail("no se pudo elegir el \(name)", file: file, line: line)
    }

    /// Confirma un diálogo de confirmación: como hoja de acciones o, dentro
    /// de otra hoja, como menú flotante (entonces el botón es el último con ese nombre).
    func confirm(_ title: String, file: StaticString = #filePath, line: UInt = #line) {
        let inSheet = app.sheets.buttons[title]
        if inSheet.waitForExistence(timeout: 2) { inSheet.tap(); return }
        let all = app.buttons.matching(identifier: title)
        XCTAssertTrue(all.firstMatch.waitForExistence(timeout: 5), "no sale la confirmación «\(title)»", file: file, line: line)
        all.element(boundBy: max(0, all.count - 1)).tap()
    }

    /// Hay una hoja abierta: deslizar hacia abajo la cerraría.
    var sheetOpen: Bool { app.buttons["sheet.close"].exists }

    /// Busca un elemento que aún no existe (listas perezosas): primero hacia
    /// abajo, luego hacia arriba del todo.
    func search(_ element: XCUIElement) {
        var swipes = 0
        while !element.exists && swipes < 4 { app.swipeUp(velocity: .slow); swipes += 1 }
        swipes = 0
        while !element.exists && swipes < 10 && !sheetOpen { app.swipeDown(velocity: .slow); swipes += 1 }
        swipes = 0
        while !element.exists && swipes < 6 { app.swipeUp(velocity: .slow); swipes += 1 }
    }

    /// Toca por coordenadas (para etiquetas dentro de menús, que no son "hittable").
    func forceTap(_ element: XCUIElement) {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    /// El menú de rutinas del Calendario.
    var routineMenu: XCUIElement { app.descendants(matching: .any)["routine.menu"].firstMatch }

    func scrollTo(_ element: XCUIElement, maxSwipes: Int = 8) {
        // Por encima de la pantalla: hacia arriba; por debajo: hacia abajo.
        let screen = app.windows.firstMatch.frame
        let above = element.frame.maxY < screen.minY + 120
        var tries = 0
        while !element.isHittable && tries < maxSwipes {
            if above {
                if sheetOpen { break }
                app.swipeDown(velocity: .slow)
            } else {
                app.swipeUp(velocity: .slow)
            }
            tries += 1
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

    /// Cierra el teclado con el "Listo" que la app pone encima (también en los numéricos).
    func dismissKeyboard() {
        guard app.keyboards.firstMatch.exists else { return }
        let done = app.buttons["keyboard.done"].firstMatch
        if done.waitForExistence(timeout: 2) {
            done.tap()
        } else {
            XCTFail("el teclado no tiene botón Listo")
        }
        assertGone(app.keyboards.firstMatch, 3)
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
        selectDay("Lunes")
        let s1 = app.buttons["set.Press de banca.1"]
        let s2 = app.buttons["set.Press de banca.2"]
        tap(s1)
        XCTAssertEqual(s1.value as? String, "hecha")
        let timer = app.buttons["timer.stop"]
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
        XCTAssertTrue(exists(app.staticTexts["SERIE 2 · MARCAR"]), "editor rápido")
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
        XCTAssertTrue(exists(app.staticTexts["SERIE 1 · EDITAR"]))
        tap(app.buttons["Calentamiento"])
        tap(app.buttons["Guardar"])
        assertGone(app.staticTexts["SERIE 1 · EDITAR"])

        // Descanso manual desde la tarjeta y volver a hoy.
        tap(app.buttons["rest.Press de banca"])
        XCTAssertTrue(exists(timer))
        tap(app.buttons["timer.stop"])
        tap(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Volver a hoy'")).firstMatch)
        XCTAssertEqual(app.buttons["day.Lunes"].value as? String, "5", "Lunes deja de estar seleccionado")
        snap("inicio")

        // La cabecera de sesión enseña progreso.
        selectDay("Lunes")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '2/'")).firstMatch.exists
                      || app.staticTexts["2"].exists)
    }

    // MARK: - 3. Inicio vacío y rutina de ejemplo

    func test03_EmptyHomeLoadsSample() {
        launch(["--named"])
        XCTAssertTrue(exists(app.buttons["Cargar rutina de ejemplo"], 8), "estado vacío")
        tap(app.buttons["Cargar rutina de ejemplo"])
        XCTAssertTrue(exists(app.buttons["day.Lunes"]))
        selectDay("Viernes")
        XCTAssertTrue(exists(app.buttons["set.Sentadilla.1"]))
        tab("Ejercicios")
        XCTAssertTrue(exists(app.staticTexts["15 en tu biblioteca"]))
        snap("ejercicios")
    }

    // MARK: - 4. Superserie

    func test04_Superset() {
        launch()
        selectDay("Lunes")
        tap(app.buttons["info.Press de banca"])
        tap(app.buttons["detail.superset"])
        tap(app.buttons["Superserie A"])
        XCTAssertTrue(exists(app.buttons["Superserie A"]))
        closeSheet()
        tap(app.buttons["info.Aperturas"])
        tap(app.buttons["detail.superset"])
        tap(app.buttons["Superserie A"])
        closeSheet()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'superserie a'")).firstMatch.waitForExistence(timeout: 5),
                      "cabecera del grupo en Inicio")
        tap(app.buttons["set.Press de banca.1"])
        XCTAssertFalse(app.buttons["timer.stop"].waitForExistence(timeout: 2), "sin descanso: falta la pareja")
        tap(app.buttons["set.Aperturas.1"])
        XCTAssertTrue(exists(app.buttons["timer.stop"]), "vuelta cerrada: descanso")
        tap(app.buttons["timer.stop"])
        snap("superserie")
        // Quitar la superserie (arriba del todo: la cabecera tapa la tarjeta si está a medio scroll).
        app.swipeDown(); app.swipeDown()
        tap(app.buttons["info.Press de banca"])
        tap(app.buttons["detail.superset"])
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
        tap(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Elegir del catálogo'")).firstMatch)
        let search = app.textFields.firstMatch
        type("zzzz", into: search)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Nada con'")).firstMatch.waitForExistence(timeout: 3))
        dismissKeyboard()
        clearAndType("", into: search)
        dismissKeyboard()
        tap(app.buttons["catalog.chip.Pecho"])
        tap(app.buttons["catalog.Fondos"])
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
        let secDown = app.buttons["rest.seg.down"], secUp = app.buttons["rest.seg.up"]
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
        confirm("Eliminar ejercicio")
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
        tap(routineMenu)
        tap(app.buttons["Nueva rutina…"])
        let alertField = app.alerts.textFields.firstMatch
        XCTAssertTrue(alertField.waitForExistence(timeout: 5))
        alertField.tap()
        alertField.typeText("Fuerza")
        tap(app.alerts.buttons["Vacía"])
        XCTAssertTrue(exists(app.staticTexts["Fuerza"]))
        XCTAssertTrue(app.staticTexts["Día libre · sin ejercicios"].firstMatch.exists)

        tap(routineMenu)
        tap(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Mi rutina'")).firstMatch)
        XCTAssertTrue(exists(app.staticTexts["Mi rutina"]))
        XCTAssertTrue(exists(app.staticTexts["Pecho fuerte"]))

        tap(routineMenu)
        tap(app.buttons["Renombrar la actual…"])
        let rename = app.alerts.textFields.firstMatch
        XCTAssertTrue(rename.waitForExistence(timeout: 5))
        rename.tap()
        rename.typeText(" base")
        tap(app.alerts.buttons["Guardar"])
        XCTAssertTrue(exists(app.staticTexts["Mi rutina base"]))

        tap(routineMenu)
        tap(app.buttons["Fuerza"].firstMatch)                  // sección Eliminar
        confirm("Eliminar rutina")
        tap(routineMenu)
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
        dismissKeyboard()                                     // "Listo" guarda (Guardar queda bajo el teclado)
        XCTAssertTrue(exists(app.staticTexts["70,5 kg"]))
        tap(app.buttons["Editar"].firstMatch)
        clearAndType("abc", into: app.textFields.firstMatch)
        dismissKeyboard()
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
        search(app.buttons["cal.\(stamp(trained))"])
        XCTAssertEqual(app.buttons["cal.\(stamp(trained))"].value as? String, "entrenado")
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS 'series'")).firstMatch
        tap(row)
        XCTAssertTrue(exists(app.buttons["detail.plates"]))
        closeSheet()
        tap(app.buttons["Borrar historial del día"])
        confirm("Borrar historial del día")
        XCTAssertTrue(exists(app.staticTexts["No hay ejercicios completados"]))
        search(app.buttons["cal.\(stamp(trained))"])
        XCTAssertEqual(app.buttons["cal.\(stamp(trained))"].value as? String, "")

        // Un día sin rutina.
        tap(app.buttons["cal.\(stamp(lastRestDay()))"])
        XCTAssertTrue(exists(app.staticTexts["No hay ejercicios completados"]))
        XCTAssertFalse(app.buttons["Borrar historial del día"].exists)

        // Récords → detalle.
        let record = app.buttons.matching(NSPredicate(format: "label CONTAINS 'kg'")).allElementsBoundByIndex.last
        if let record { tap(record); XCTAssertTrue(exists(app.buttons["detail.plates"])); closeSheet() }
        snap("historial")
    }

    // MARK: - 8. Detalle: series de hoy, calculadora, gráfica

    func test08_DetailPlatesAndChart() {
        launch(["--named", "--seed-history"])
        selectDay("Lunes")
        tap(app.buttons["set.Press de banca.1"])
        if exists(app.buttons["timer.stop"], 3) { app.buttons["timer.stop"].tap() }
        tap(app.buttons["info.Press de banca"])
        XCTAssertTrue(exists(app.staticTexts["SERIES DE HOY"]))
        // Editar la serie de hoy desde la fila.
        let kg = app.textFields.firstMatch
        clearAndType("52,5", into: kg)
        dismissKeyboard()
        tap(app.buttons["setlog.type.1"])                      // menú de tipo
        tap(app.buttons["Drop set"])
        XCTAssertTrue(exists(app.staticTexts["D"]))

        // Gráfica.
        tap(app.buttons["Volumen"])
        tap(app.buttons["1RM"])
        tap(app.buttons["Peso máx"])

        // Calculadora de discos.
        tap(app.buttons["detail.plates"])
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
        XCTAssertTrue(exists(app.staticTexts["ÍNDICE DE MASA CORPORAL"]))
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
        confirm("Borrar ejercicios, rutina e historial")
        tab("Ejercicios")
        XCTAssertTrue(exists(app.staticTexts["Aún no hay ejercicios"]))
        tab("Ajustes")
        XCTAssertTrue(app.staticTexts["Tester"].exists)
        snap("ajustes")
    }

    // MARK: - 10. Ciclo de vida: fondo, relanzar, cambiar de pestaña a lo bruto

    func test10_Lifecycle() {
        launch()
        selectDay("Lunes")
        tap(app.buttons["set.Press de banca.1"])
        XCTAssertTrue(exists(app.buttons["timer.stop"]))
        let clock = app.staticTexts["timer.clock"]
        let before = clock.label
        XCUIDevice.shared.press(.home)
        sleep(6)
        app.activate()
        XCTAssertTrue(exists(app.buttons["timer.stop"], 8), "el descanso sigue al volver")
        XCTAssertNotEqual(clock.label, before, "el reloj ha avanzado contra el reloj de pared")
        XCTAssertEqual(app.buttons["day.Lunes"].value as? String, "seleccionado", "volver del fondo no cambia el día que se entrena")
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
        // Al abrir de cero, Inicio enseña hoy; la serie del lunes sigue marcada.
        selectDay("Lunes")
        XCTAssertEqual(app.buttons["set.Press de banca.1"].value as? String, "hecha", "la serie marcada sobrevive a los relanzamientos")
        snap("lifecycle")
    }

    // MARK: - 11. Modo entreno de principio a fin

    func test11_WorkoutMode() {
        launch(["--named", "--seed-history"])
        selectDay("Lunes")
        tap(app.buttons["home.startWorkout"])
        XCTAssertTrue(exists(app.staticTexts["session.exercise"], 8), "modo entreno abierto")
        let first = app.staticTexts["session.exercise"].label
        XCTAssertTrue(exists(app.otherElements["detail.suggestion"]) || app.staticTexts["HOY TOCA"].exists,
                      "sugerencia de peso con historial")
        tap(app.buttons["session.weight.plus"])
        tap(app.buttons["session.reps.minus"])
        tap(app.buttons["session.done"])
        XCTAssertTrue(exists(app.buttons["rest.skip"], 5), "descanso a pantalla completa")
        tap(app.buttons["rest.extend"])
        tap(app.buttons["rest.skip"])
        tap(app.buttons["session.undo"])
        tap(app.buttons["session.done"])
        tap(app.buttons["rest.skip"])
        tap(app.buttons["session.skip"])
        XCTAssertNotEqual(app.staticTexts["session.exercise"].label, first, "saltar pasa al siguiente")
        tap(app.buttons["session.done"])
        if exists(app.buttons["rest.skip"], 3) { app.buttons["rest.skip"].tap() }
        tap(app.buttons["session.finish"])
        confirm("Terminar y ver resumen")
        XCTAssertTrue(exists(app.staticTexts["¡Buen entreno!"], 8), "resumen")
        XCTAssertTrue(exists(app.buttons["summary.share"], 5), "tarjeta para compartir lista")
        snap("resumen")
        tap(app.buttons["summary.close"])
        XCTAssertTrue(exists(app.buttons["home.startWorkout"], 5), "vuelta a Inicio")
        XCTAssertEqual(app.buttons["set.Press de banca.1"].value as? String, "hecha")
    }
}

/// Toda la batería otra vez en modo claro (repaso visual: las capturas quedan adjuntas).
final class LightModeUITests: ChamaFitUITests {
    override class var extra: [String] { ["--light"] }
}
