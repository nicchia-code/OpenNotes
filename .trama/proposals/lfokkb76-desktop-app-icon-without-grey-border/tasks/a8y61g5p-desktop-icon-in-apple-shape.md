---
technical: true
refs:
  - requirements/tech#General
---
# Desktop icon in Apple's macOS icon shape

Oggi macOS, Windows e Linux usano `OpenNotes-square.png`, con bordo chiaro, ombra, angoli propri e margini ampi: su macOS 26 e successivi il sistema chiude l'icona in un riquadro grigio.

- Ricavare una volta dal ritaglio a tutta superficie `assets/icon/OpenNotes-desktop.png`: tela 1024×1024 trasparente, al centro il ritaglio ridimensionato a 824×824 px con 100 px di margine per lato, ritagliato nel rettangolo arrotondato a curvatura continua della maschera Apple per le icone macOS (raggio d'angolo di circa 185 px); nessun bordo, ombra o alone.
- In `pubspec.yaml` generare con `flutter_launcher_icons` le icone di macOS e Windows dal nuovo file; il web resta sull'immagine quadrata.
- Linux: installare il nuovo file nel bundle al posto dell'immagine quadrata e impostarlo come icona della finestra GTK; nel workflow `desktop-build` l'AppImage lo usa come icona del file `.desktop`.
- Le schermate di avvio di iOS e Android, le icone di iOS, Android e web e l'icona del README non cambiano.
- Verificare su macOS 26 o successivo, con l'app compilata, che nel Dock, nel Finder e nella finestra del DMG l'icona non sia dentro il riquadro grigio.
