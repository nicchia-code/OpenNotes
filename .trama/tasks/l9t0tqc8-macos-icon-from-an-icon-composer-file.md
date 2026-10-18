---
column: done
technical: true
refs:
  - requirements/tech#General
drift: null
proposal: 4nv9aqlg
agent: false
created: 2026-10-18T20:05:27.339Z
finished: 2026-10-18T20:09:26.751Z
---
# macOS icon from an Icon Composer file

Oggi macOS usa il set PNG `AppIcon.appiconset` generato da `flutter_launcher_icons` a partire da `assets/icon/OpenNotes-desktop.png`, con angoli disegnati di circa 80 px di raggio: da macOS 26 il sistema chiude l'icona nel riquadro grigio.

- Creare un file Icon Composer `.icon` in `macos/Runner` con un solo livello: `assets/icon/OpenNotes-full-bleed.png` ingrandito fino a riempire la tela di 1024×1024 px, senza forma, margini o angoli disegnati. Effetti vetro (Liquid Glass), riflesso e ombra del livello spenti; nessuna variante scura, trasparente o colorata dedicata.
- Aggiungere il file al target Runner e impostarlo come icona dell'app (`ASSETCATALOG_COMPILER_APPICON_NAME` in tutte le configurazioni).
- Eliminare `macos/Runner/Assets.xcassets/AppIcon.appiconset` e la sezione macOS di `flutter_launcher_icons` in `pubspec.yaml`; Windows resta generato da `OpenNotes-desktop.png`. Linux, web, iOS, Android, schermate di avvio e icona del README non cambiano.
- Nel workflow `desktop-build` il job macOS usa un runner macOS 26 o successivo indicato per nome al posto di `macos-latest` e seleziona esplicitamente Xcode 26 o successivo.
- Verificare con una build pulita, installata al posto di quella in `/Applications` e dopo aver aggiornato la cache delle icone, che su macOS 26 o successivo l'icona nel Dock, nel Finder, nel Launchpad e nella finestra del DMG sia a tutta superficie con la maschera di sistema e senza riquadro grigio; controllare che il bundle contenga anche l'icona statica per i macOS precedenti.
