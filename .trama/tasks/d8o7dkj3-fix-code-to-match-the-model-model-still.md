---
column: done
technical: false
refs:
  - export-pdf/Idle/user.EXPORT_NOTE_AS_PDF
  - requirements/rules#note-access
drift: c3fx0d6j
proposal: null
agent: false
created: 2026-10-12T17:14:49.795Z
finished: 2026-10-12T17:16:31.564Z
---
# Fix code to match the Model: Model still describes PDF export without PIN after its Drift was resolved

## What happens

Esportando in PDF una nota protetta, l'app chiede il PIN principale prima di aprire la finestra di stampa: con il PIN sbagliato o con l'annullamento la finestra non si apre. Così è stata risolta la Drift **nabu4w7o**, ma il Model dice ancora che il PDF non chiede il PIN nemmeno per le note protette.

## What should happen

Il Requirement sulle note protette dice che **la copia di una nota protetta resta protetta**, e che l'esportazione in Markdown richiede sempre il PIN corretto. Il Model dell'esportazione PDF dovrebbe descrivere la decisione già presa: per una nota protetta si attende il PIN corretto, e solo dopo si apre la finestra di stampa.

## Chosen option

**Descrivere il PIN nel Model**

Il Model dell'esportazione PDF riscrive la transizione di Idle: per una nota protetta l'app attende il PIN corretto; con PIN errato o annullato non si apre nulla. Il codice già si comporta così, quindi non cambia. Costo: una Proposal che aggiorna il Model dell'esportazione PDF, coerente con la Drift risolta.

## Where in the code

Servizio di impaginazione PDF; nessuna schermata dell'app lo chiama oggi
