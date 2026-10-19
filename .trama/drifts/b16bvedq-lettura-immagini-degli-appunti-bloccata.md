---
status: resolved
resolution: fix-code
refs:
  - requirements/tech#General
proposal: null
task: xuumrxyj
origin: h7d2w7yr
critical: false
option: 1
note: null
resolvedBy: p4wq4e4l
created: 2026-10-19T15:35:31.024Z
---
# Lettura immagini degli appunti bloccata dal conflitto di share_plus

## What happens

Incollare un'immagine richiede di leggere gli appunti con super_clipboard 0.9.1, ma questa versione non si risolve insieme a share_plus 13.3.0 (vincolo win32, vedi D1 e P1): pub get fallisce e il codice che legge gli appunti non si può scrivere né compilare. Il lavoro sull'editor (PASTE_IMAGE, menu Incolla, salvataggio, ridimensionamento con image) è pronto a partire, ma non si può chiudere senza la lettura degli appunti.

## What should happen

Requirements tech#General impone super_clipboard 0.9.1 per leggere le immagini degli appunti e share_plus 13.3.0; le due versioni non possono stare nello stesso progetto. Il Task non si può completare finché D1 non è risolta.

## Fix options

### Attendere la risoluzione di D1 e poi completare il Task

Nessuna modifica ora: D1 decide la versione di share_plus; dopo, si implementa il Task come descritto.

### Chiudere il Task senza modifiche

Il Task si chiude con la nota che la lettura degli appunti non è possibile con le versioni richieste; il comportamento di incolla resta non implementato.

## Where in the code

lib/ui/editor/notion_document_editor.dart, lib/ui/shell/adaptive_app_shell.dart, lib/ui/mobile/mobile_note_editor_screen.dart (nessun codice scritto per la lettura degli appunti); pubspec.yaml
