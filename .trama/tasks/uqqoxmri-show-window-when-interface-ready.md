---
column: done
technical: false
refs:
  - app-window/Hidden
  - requirements/rules#app-window
  - requirements/tech#General
drift: null
proposal: 7ebtbwti
agent: false
created: 2026-10-17T21:08:31.832Z
finished: 2026-10-17T21:09:57.586Z
---
# Show window when interface is ready

Su macOS la finestra non compare: `MainMenu.xib` la crea con `visibleAtLaunch="NO"`, il motore Flutter su macOS parte solo quando la finestra compare, quindi `main()` non gira e `windowManager.show()` non viene mai chiamato.

- In `macos/Runner/Base.lproj/MainMenu.xib` togliere `visibleAtLaunch="NO"`, come nel template di Flutter.
- In `macos/Runner/MainFlutterWindow.swift` aggiungere l'override di `order(_:relativeTo:)` che chiama `super` e poi `hiddenWindowAtLaunch()` di `window_manager`.
- In `lib/main.dart` la callback di `waitUntilReadyToShow` non mostra più la finestra: `windowManager.show()` e `windowManager.focus()` partono dopo il primo frame disegnato da `runApp` (callback post-frame), su Linux, macOS e Windows.

Fatto quando, su macOS, l'app avviata da Finder o da `flutter run -d macos` mostra la finestra centrata 1280 × 760 senza barra del titolo di sistema e già con l'interfaccia disegnata, e su Linux e Windows la finestra compare anch'essa solo con l'interfaccia disegnata, mai vuota o trasparente.
