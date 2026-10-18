---
status: approved
base:
  requirements/tech/general.md: 9b99443a37db3503970bc73724ccd795328af1a2cfb06dc1703388fb2dad116d
delete: []
request: 2026-10-18T21-55-07
created: 2026-10-18T20:03:18.657Z
label: macOS Icon Composer icon
---
# macOS icon from Icon Composer

Su macOS l'icona compare ancora nel riquadro grigio che il sistema aggiunge da macOS 26: l'icona PNG con angoli disegnati (raggio misurato di circa 80 px, non la curvatura continua di Apple) non è riconosciuta conforme. L'icona macOS deve essere a tutta superficie, con la maschera applicata dal sistema.

Decisioni:
- macOS usa un file Icon Composer (.icon) con un solo livello, il ritaglio quadrato a tutta superficie; la maschera la applica il sistema. Supera la scelta «niente Icon Composer» della Proposal lfokkb76.
- Il livello è OpenNotes-full-bleed.png (876 px) ingrandito fino a riempire la tela di 1024 px.
- Aspetto piatto: effetti vetro, riflesso e ombra del livello spenti.
- Aspetti scuro, trasparente e colorato ricavati dal sistema, senza disegni aggiuntivi.
- macOS da 10.15 a 15: immagini ricavate da Xcode dal file .icon; si eliminano il set PNG AppIcon e la sezione macOS di flutter_launcher_icons.
- Windows e Linux restano su OpenNotes-desktop.png, invariati.
- CI: il job macOS usa esplicitamente un runner macOS 26 o successivo e seleziona Xcode 26 o successivo.
