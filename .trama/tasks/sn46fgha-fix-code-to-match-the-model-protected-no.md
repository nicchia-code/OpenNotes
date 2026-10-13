---
column: done
technical: false
refs:
  - export-pdf/Idle/user.EXPORT_NOTE_AS_PDF
  - requirements/rules#note-access
drift: nabu4w7o
proposal: null
agent: false
created: 2026-10-12T15:31:57.789Z
finished: 2026-10-12T15:35:33.508Z
---
# Fix code to match the Model: Protected note exports to PDF without the PIN, the Requirement keeps copies protected

## What happens

Esportando in PDF una nota protetta la finestra di stampa si apre senza chiedere il PIN, come previsto dal Model. Il servizio di impaginazione non controlla in alcun modo il lucchetto della nota: il documento viene generato e consegnato alla stampa così com'è.

## What should happen

Il Requirement sulle note protette dice che la copia di una nota protetta resta protetta e che alcune azioni richiedono sempre il PIN corretto, tra cui l'esportazione in Markdown; il PDF non compare in quell'elenco. Il Model dice invece che il PDF non chiede il PIN nemmeno per le note protette. Le due fonti non coincidono, e il codice segue il Model.

## Chosen option

**Chiedere il PIN anche per il PDF**

Il PDF di una nota protetta chiede il PIN corretto prima di aprire la finestra di stampa, come l'esportazione in Markdown e la condivisione. Il Model dell'esportazione PDF cambia: la transizione non è più libera per le note protette. Costo: un controllo in più prima della stampa e un Model da aggiornare.

## Where in the code

Servizio di impaginazione PDF; nessuna schermata dell'app lo chiama oggi
