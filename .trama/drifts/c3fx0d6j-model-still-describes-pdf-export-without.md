---
status: resolved
resolution: fix-code
refs:
  - export-pdf/Idle/user.EXPORT_NOTE_AS_PDF
  - requirements/rules#note-access
proposal: null
task: d8o7dkj3
origin: null
critical: false
option: 1
note: null
resolvedBy: psazi867
created: 2026-10-12T16:45:47.237Z
---
# Model still describes PDF export without PIN after its Drift was resolved

## What happens

Esportando in PDF una nota protetta, l'app chiede il PIN principale prima di aprire la finestra di stampa: con il PIN sbagliato o con l'annullamento la finestra non si apre. Così è stata risolta la Drift **nabu4w7o**, ma il Model dice ancora che il PDF non chiede il PIN nemmeno per le note protette.

## What should happen

Il Requirement sulle note protette dice che **la copia di una nota protetta resta protetta**, e che l'esportazione in Markdown richiede sempre il PIN corretto. Il Model dell'esportazione PDF dovrebbe descrivere la decisione già presa: per una nota protetta si attende il PIN corretto, e solo dopo si apre la finestra di stampa.

## Fix options

### Descrivere il PIN nel Model

Il Model dell'esportazione PDF riscrive la transizione di Idle: per una nota protetta l'app attende il PIN corretto; con PIN errato o annullato non si apre nulla. Il codice già si comporta così, quindi non cambia. Costo: una Proposal che aggiorna il Model dell'esportazione PDF, coerente con la Drift risolta.

### Tenere il PDF senza PIN

Il PDF di una nota protetta torna ad aprirsi senza chiedere il PIN, come oggi dice il Model. Il codice smette di chiedere il PIN per il PDF, e il Requirement delle note protette va chiarito per escludere il PDF. Costo: una stampa o un file PDF di una nota protetta esce dall'app senza alcuna protezione, e la decisione presa sulla Drift nabu4w7o viene ribaltata.

### Non generare il PDF delle note protette

Per una nota protetta l'esportazione PDF non apre la finestra di stampa: l'utente deve prima togliere il lucchetto con il PIN. Il Model esclude le note protette dall'esportazione PDF, e il codice cambia con una sola condizione. Costo: l'utente non può ottenere il PDF di una nota protetta senza sbloccarla.

## Where in the code

Servizio di impaginazione PDF; nessuna schermata dell'app lo chiama oggi
