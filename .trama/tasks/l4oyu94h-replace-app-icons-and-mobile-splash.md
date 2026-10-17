---
column: done
technical: true
refs:
  - requirements/tech#General
drift: null
proposal: 0mg7tkmx
agent: false
created: 2026-10-17T17:08:44.140Z
finished: 2026-10-17T17:41:45.397Z
---
# Replace app icons and mobile splash with OpenNotes.png

Oggi tutte le piattaforme hanno l'icona predefinita di Flutter e `OpenNotes.png` sta alla radice del repository, non usata.

- Spostare `OpenNotes.png` in `assets/icon/OpenNotes.png` e ricavarne una volta i due file salvati accanto: `OpenNotes-square.png` (immagine intera centrata in un quadrato 1280×1280 con margini trasparenti) e `OpenNotes-full-bleed.png` (ritaglio 1024×1024 dall'interno del riquadro, senza angoli, bordo, ombra né trasparenza).
- Aggiungere `flutter_launcher_icons` come dipendenza di sviluppo, configurarlo in `pubspec.yaml` e generare le icone: Android classica e adattiva (primo piano e sfondo) dal ritaglio; iOS dal ritaglio senza canale alfa; macOS, Windows e web (favicon, icone del manifest e varianti maskable) dall'immagine quadrata.
- Linux: installare l'immagine quadrata nel bundle e impostarla come icona della finestra GTK all'avvio; nel workflow `desktop-build` l'AppImage la usa al posto di `web/icons/Icon-512.png`.
- Aggiungere `flutter_native_splash` come dipendenza di sviluppo, configurato in `pubspec.yaml` solo per iOS e Android: immagine quadrata al centro, fondo `#FFFFFF` in tema chiaro e `#000000` in tema scuro; su Android 12 e successivi il riquadro arrotondato sta tutto dentro il cerchio del sistema.
- Nessuno dei file in `assets/icon/` entra nella sezione `assets` di `pubspec.yaml`.
