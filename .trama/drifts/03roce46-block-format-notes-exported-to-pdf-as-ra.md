---
status: resolved
resolution: fix-code
refs:
  - export-pdf/Idle/user.EXPORT_NOTE_AS_PDF
  - requirements/rules#export-pdf
proposal: null
task: ukwqweh0
origin: null
critical: false
option: 1
note: null
resolvedBy: fz9axufm
created: 2026-10-12T10:45:01.104Z
---
# Block-format notes exported to PDF as raw JSON

## What happens

Esportando in PDF una nota creata nell'editor, il documento non mostra il testo della nota: stampa il suo contenuto interno a blocchi così com'è, su una riga lunga piena di simboli di struttura. Titoli, intestazioni, caselle ed elenchi non compaiono come nell'editor. Il codice fa quello che il Requirement dice: stampare il contenuto grezzo, riga per riga.

## What should happen

Il Model dice che la nota viene impaginata con data, titolo, linea divisoria e corpo. Il Requirement chiede di impaginare il **contenuto grezzo** della nota, riga per riga, con le regole di titoli, caselle ed elenchi. Per le note a blocchi, però, il contenuto grezzo non è testo leggibile: il Requirement non dice come trattarle, mentre la condivisione e l'esportazione su file le convertono prima in Markdown.

## Fix options

### Convert the note to Markdown before the layout

Il PDF parte dalla stessa conversione in Markdown già usata per condivisione ed esportazione su file: titoli, intestazioni, caselle ed elenchi tornano come nell'editor, e le note in testo semplice restano uguali. Va cambiata la regola del PDF, che oggi dice «contenuto grezzo». Costo: piccolo, perché la conversione esiste già.

### Lay out the note directly from its blocks

Il PDF legge i blocchi della nota invece del testo, e applica le stesse dimensioni e gli stessi stili delle regole attuali. Il risultato è fedele all'editor, anche per i blocchi che la conversione in Markdown appiattisce. Costo: una seconda strada di impaginazione da mantenere in parallelo, e il Requirement va riscritto per i blocchi.

### Keep the raw content as written

Nessuna modifica: il PDF continua a stampare il contenuto grezzo come chiede il Requirement, e per le note create nell'editor il documento resta illeggibile. Costo zero, ma la funzione non serve per le note attuali. Scegliere questa via solo se l'esportazione PDF resta lontana dall'interfaccia finché non si decide altro.

## Where in the code

lib/core/services/pdf_export_service.dart (il corpo viene diviso per righe del contenuto della nota); il formato a blocchi è scritto da lib/ui/editor/notion_document_editor.dart e lib/core/state/notes_provider.dart; la conversione Markdown esiste in lib/core/models/note_model.dart (toMarkdown).
