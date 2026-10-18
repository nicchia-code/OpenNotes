---
status: approved
base:
  requirements/tech/general.md: 1bf212df43724b556fa2638f6432710fbdf979c8e5f49aa069f611820b3f811e
delete: []
request: 2026-10-18T18-25-25
created: 2026-10-18T16:29:47.949Z
label: Desktop icon
---
# Desktop app icon without grey border

Da macOS 26 il sistema chiude in un riquadro grigio le icone che non hanno esattamente la forma arrotondata di Apple; l'icona attuale, ricavata dall'immagine quadrata con bordo chiaro, ombra e angoli propri, ci finisce dentro.

Decisioni:
- Nuovo file derivato dal ritaglio a tutta superficie, nella forma arrotondata a curvatura continua del modello macOS di Apple (824×824 px al centro di una tela 1024×1024, 100 px di margine trasparente), generato con flutter_launcher_icons; niente Icon Composer.
- Nessuna ombra né bordo disegnati nell'immagine.
- La nuova icona vale per macOS, Windows e Linux (finestra GTK e file .desktop dell'AppImage); web e schermate di avvio restano sull'immagine quadrata attuale.
- Windows e Linux usano lo stesso file di macOS, con gli stessi margini.
