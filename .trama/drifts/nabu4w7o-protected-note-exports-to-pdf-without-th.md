---
status: resolved
resolution: fix-code
refs:
  - export-pdf/Idle/user.EXPORT_NOTE_AS_PDF
  - requirements/rules#note-access
proposal: null
task: sn46fgha
origin: null
critical: false
option: 1
note: null
resolvedBy: lw176xay
created: 2026-10-12T15:27:26.146Z
---
# Protected note exports to PDF without the PIN, the Requirement keeps copies protected

## What happens

Esportando in PDF una nota protetta la finestra di stampa si apre senza chiedere il PIN, come previsto dal Model. Il servizio di impaginazione non controlla in alcun modo il lucchetto della nota: il documento viene generato e consegnato alla stampa così com'è.

## What should happen

Il Requirement sulle note protette dice che la copia di una nota protetta resta protetta e che alcune azioni richiedono sempre il PIN corretto, tra cui l'esportazione in Markdown; il PDF non compare in quell'elenco. Il Model dice invece che il PDF non chiede il PIN nemmeno per le note protette. Le due fonti non coincidono, e il codice segue il Model.

## Fix options

### Chiedere il PIN anche per il PDF

Il PDF di una nota protetta chiede il PIN corretto prima di aprire la finestra di stampa, come l'esportazione in Markdown e la condivisione. Il Model dell'esportazione PDF cambia: la transizione non è più libera per le note protette. Costo: un controllo in più prima della stampa e un Model da aggiornare.

### Tenere il PDF senza PIN e chiarire la regola

Il PDF resta senza PIN, come descrive oggi il Model, e il Requirement delle note protette viene aggiornato per escludere esplicitamente il PDF. Costo: nessuna modifica al codice, ma una stampa o un file PDF di una nota protetta esce dall'app senza alcuna protezione, e questo va accettato come scelta.

### Non generare il PDF delle note protette

Per una nota protetta l'esportazione PDF non apre la finestra di stampa: l'utente deve prima togliere il lucchetto con il PIN, come per le altre copie. Il Model cambia per escludere le note protette dall'esportazione PDF. Costo: piccolo, ma l'utente non può ottenere un PDF di una nota protetta senza sbloccarla.

## Where in the code

Servizio di impaginazione PDF; nessuna schermata dell'app lo chiama oggi
