---
status: resolved
resolution: proposal
refs:
  - requirements/rules#export-pdf
  - export-pdf/Idle/user.EXPORT_NOTE_AS_PDF
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: ccg944lf
created: 2026-10-12T12:01:54.887Z
---
# PDF body follows Markdown conversion, but the PDF Requirement still says raw content

## What happens

Il PDF di una nota viene impaginato dal suo corpo convertito in Markdown, senza il titolo: titoli, caselle ed elenchi compaiono come nell'editor, e la riga da cui nasce il titolo non viene ripetuta. Le decisioni prese sulle Drift **«Block-format notes exported to PDF as raw JSON»** e **«Title repeated in the PDF body when it is clipped or styled»** hanno cambiato il comportamento, ma il testo del Requirement non è stato aggiornato.

## What should happen

Il Requirement **export-pdf** chiede che il corpo venga dal **contenuto grezzo** della nota, riga per riga, e che la **prima riga identica al titolo** venga saltata una sola volta. Il resto delle regole (cerchi, punti, dimensioni) resta valido.

## Fix options

### Aggiornare il Requirement al corpo in Markdown

Il Requirement del PDF viene riscritto: il corpo nasce dalla stessa conversione Markdown usata per condivisione ed esportazione, e la riga da cui nasce il titolo viene saltata, anche se formattata o troncata. Il codice già lo fa, quindi non cambia nulla nel PDF. Costo: una modifica del solo testo del Requirement; immagini e tabelle compaiono come testo Markdown.

### Tornare al contenuto grezzo

Il codice torna a stampare il contenuto grezzo, riga per riga, come scritto nel Requirement, e salta solo la riga identica al titolo. Le note create nell'editor tornano illeggibili nel PDF, con i simboli di struttura al posto di titoli, caselle ed elenchi. Costo: piccolo nel codice, ma la conversione in Markdown del corpo smette di servire al PDF.

## Where in the code

lib/core/services/pdf_export_service.dart; corpo preso da toMarkdownBody in lib/core/models/note_model.dart
