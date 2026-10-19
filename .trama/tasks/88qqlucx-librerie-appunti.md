---
column: done
technical: true
refs:
  - specs#frameworks
  - specs#notes
  - requirements/tech#General
drift: null
proposal: sdhwy7m7
agent: false
created: 2026-10-19T15:28:11.378Z
finished: 2026-10-19T16:30:35.071Z
---
# Librerie per gli appunti

Quando il lavoro è finito:

- `pubspec.yaml` dipende da `super_clipboard` 0.9.1 e da `image` (versione stabile più recente compatibile con il vincolo SDK Dart `^3.11.4`), con `pubspec.lock` aggiornato.
- `super_clipboard` usa i binari nativi precompilati: la build in locale e quella della CI (Windows, macOS universale, Linux AppImage su `ubuntu-22.04`) riescono senza toolchain Rust; su Android la build ha l'NDK richiesto dalla libreria.
- `flutter analyze` e `flutter test` passano.
