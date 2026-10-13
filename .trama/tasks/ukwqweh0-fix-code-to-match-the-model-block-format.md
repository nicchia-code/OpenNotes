---
column: done
technical: false
refs:
  - export-pdf/Idle/user.EXPORT_NOTE_AS_PDF
  - requirements/rules#export-pdf
drift: 03roce46
proposal: null
agent: false
created: 2026-10-12T10:59:40.486Z
finished: 2026-10-12T11:01:14.384Z
---
# Fix code to match the Model: Block-format notes exported to PDF as raw JSON

## What happens

Esportando in PDF una nota creata nell'editor, il documento non mostra il testo della nota: stampa il suo contenuto interno a blocchi così com'è, su una riga lunga piena di simboli di struttura. Titoli, intestazioni, caselle ed elenchi non compaiono come nell'editor. Il codice fa quello che il Requirement dice: stampare il contenuto grezzo, riga per riga.

## What should happen

Il Model dice che la nota viene impaginata con data, titolo, linea divisoria e corpo. Il Requirement chiede di impaginare il **contenuto grezzo** della nota, riga per riga, con le regole di titoli, caselle ed elenchi. Per le note a blocchi, però, il contenuto grezzo non è testo leggibile: il Requirement non dice come trattarle, mentre la condivisione e l'esportazione su file le convertono prima in Markdown.

## Chosen option

**Convert the note to Markdown before the layout**

Il PDF parte dalla stessa conversione in Markdown già usata per condivisione ed esportazione su file: titoli, intestazioni, caselle ed elenchi tornano come nell'editor, e le note in testo semplice restano uguali. Va cambiata la regola del PDF, che oggi dice «contenuto grezzo». Costo: piccolo, perché la conversione esiste già.

## Where in the code

lib/core/services/pdf_export_service.dart (il corpo viene diviso per righe del contenuto della nota); il formato a blocchi è scritto da lib/ui/editor/notion_document_editor.dart e lib/core/state/notes_provider.dart; la conversione Markdown esiste in lib/core/models/note_model.dart (toMarkdown).
