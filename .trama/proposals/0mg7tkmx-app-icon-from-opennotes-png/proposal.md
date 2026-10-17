---
status: approved
base:
  requirements/tech/general.md: 0953cdd0548ba03e056df20e9466886f262c9b89e253f1a01f4ff5f414ca958b
  requirements/docs/readme.md: 8fb7f135ccb33239b0eb15dfccc7a682547492cbc3d187ad1f5f6e45bd194e68
delete: []
request: 2026-10-17T18-52-59
created: 2026-10-17T17:01:46.725Z
label: App icon
---
# App icon from OpenNotes.png

Sostituisce l'icona predefinita di Flutter con l'immagine OpenNotes.png (panda rosso che appende foglietti), come chiesto nella richiesta di design.

Decisioni:
- L'icona vale per tutte le piattaforme: Android, iOS, macOS, Linux, Windows e web.
- Il file sorgente si sposta dalla radice in assets/icon/OpenNotes.png; non è un asset Flutter incluso nell'app.
- Le icone di ogni piattaforma si generano con flutter_launcher_icons, dipendenza di sviluppo configurata in pubspec.yaml.
- iOS e Android usano un ritaglio a tutta superficie dell'illustrazione (senza angoli arrotondati, ombra né margini), salvato come secondo PNG in assets/icon/; su Android lo stesso ritaglio è il primo piano dell'icona adattiva.
- Desktop e web usano l'immagine intera, riquadro arrotondato con ombra, centrata in un quadrato con margini trasparenti.
- Su Linux la nuova icona va nell'AppImage e la finestra GTK la imposta all'avvio.
- Il README mostra l'icona a 128 px sopra il titolo.
- La schermata di avvio di iOS e Android mostra al centro il riquadro arrotondato intero, su fondo bianco in tema chiaro e nero in tema scuro, generata con flutter_native_splash.

Assunzioni da verificare:
- Anche l'immagine quadrata con margini trasparenti (1280×1280) è un file derivato salvato in assets/icon/, come il ritaglio.
- Il livello di sfondo dell'icona adattiva Android usa lo stesso ritaglio del primo piano, senza scegliere un colore.
- Su Android 12 e successivi il riquadro arrotondato della schermata di avvio sta tutto dentro il cerchio del sistema, senza tagli.
