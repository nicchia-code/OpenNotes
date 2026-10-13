---
status: approved
base:
  requirements/tech/general.md: 8ab71d4719c6f09016f630fefacf2bad8365ae3898aa31c164874247d86c7ce4
delete: []
request: 2026-10-12T09-01-21
created: 2026-10-12T07:15:20.879Z
scanScope:
  - ref: requirements/tech#General
    reason: changed
---
# Desktop build CI workflow

Serve un workflow GitHub Actions che verifichi il codice e compili OpenNotes per i sistemi desktop, pubblicando i pacchetti come artefatti e, sui tag di versione, in una GitHub Release. Il cambiamento riguarda solo i requisiti tecnici (nessun comportamento dell'app cambia).

Decisioni prese:
- Piattaforme: solo desktop — Windows x64, macOS universale (arm64 + x86_64), Linux x86_64; niente Android, iOS, web.
- Avvio: push su main, pull request, tag v* e avvio manuale.
- Uscite: artefatti a ogni esecuzione (conservati 30 giorni) + GitHub Release sui tag v*.
- Release pubblicata subito, marcata pre-release se il tag ha un suffisso; testo con le note generate da GitHub.
- Formati: zip su Windows, .dmg creato con create-dmg su macOS, AppImage creata con appimagetool su Linux, compilata su ubuntu-22.04.
- Nomi dei file: OpenNotes-<versione>-<sistema>-<arch>.
- Nessuna firma del codice (ad-hoc su macOS).
- Job iniziale con flutter analyze e flutter test; se fallisce le build non partono.
- Flutter fissato a 3.41.2 stable.
- SUPABASE_URL e SUPABASE_ANON_KEY dai segreti GitHub, obbligatori; solo nelle PR da fork si usano i valori incorporati.
- Versione: sui tag dal nome del tag, numero di build dal numero dell'esecuzione; tag non nella forma vX.Y.Z[-suffisso] → il workflow fallisce.
- Un nuovo push sullo stesso branch o PR annulla l'esecuzione in corso, mai sui tag.

Assunzioni: fuori dai tag la versione resta quella di pubspec.yaml con il numero di build dell'esecuzione; il workflow sta in un unico file.
