---
status: resolved
resolution: fix-code
refs:
  - export-pdf/Idle/user.EXPORT_NOTE_AS_PDF
  - requirements/rules#export-pdf
proposal: null
task: m67xoz0o
origin: null
critical: false
option: 1
note: null
resolvedBy: oasankgu
created: 2026-10-12T17:49:56.955Z
---
# Data nel PDF in UTC per le note arrivate dal cloud

## What happens

L'intestazione del PDF mostra l'ora in UTC per una nota letta dal cloud o dal database dopo una sincronizzazione, finché la nota non viene modificata localmente: l'ora stampata non è quella locale dell'ultima modifica. L'editor mostra la stessa data sbagliata nella sua intestazione.

## What should happen

Il Model dice che l'intestazione riporta la data dell'ultima modifica, e il Requirement ne fissa il formato «d MMMM yyyy, HH:mm» in italiano. L'utente si aspetta l'ora locale. Né il Model né il Requirement dicono quale fuso usare per la data mostrata.

## Fix options

### Convertire le date in ora locale quando la nota viene letta

Le date updated_at lette dal cloud e dal database diventano ora locale nel modello della nota, così PDF, editor ed elenco mostrano la stessa ora corretta. Costo: piccolo, in un solo punto del modello.

### Convertire in ora locale solo nel formato

La data viene convertita in ora locale solo quando viene formattata per il PDF e per l'editor. Costo: piccolo, ma le altre date che usano updatedAt restano in UTC.

### Lasciare l'ora UTC

Nessuna modifica: l'intestazione mostra l'ora UTC per le note sincronizzate. Costo zero, ma l'ora stampata non corrisponde a quella dell'utente.

## Where in the code

lib/core/models/note_model.dart: fromMap e fromJson leggono updated_at con DateTime.tryParse e restano in UTC; lib/core/services/pdf_export_service.dart: dateFormat.format(note.updatedAt); lib/ui/editor/notion_document_editor.dart: intestazione con widget.note.updatedAt.
