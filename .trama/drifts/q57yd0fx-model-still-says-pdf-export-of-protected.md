---
status: resolved
resolution: dismissed
refs:
  - export-pdf/Idle/user.EXPORT_NOTE_AS_PDF
  - requirements/rules#note-access
proposal: null
task: null
origin: null
critical: false
option: null
note: null
created: 2026-10-13T05:20:03.579Z
---
# Model still says PDF export of protected notes skips the PIN

## What happens

Esportando in PDF una nota protetta, l'app chiede il PIN principale prima di aprire la finestra di stampa: con PIN errato o annullamento la finestra non si apre. Il Model dice invece che il PDF non chiede il PIN nemmeno per le note protette.

## What should happen

Il Model dell'esportazione PDF dovrebbe descrivere la decisione già presa nella Drift **c3fx0d6j**: per una nota protetta l'app attende il PIN corretto e solo dopo apre la finestra di stampa. Il Task **d8o7dkj3** risulta chiuso, ma la frase del Model è ancora quella vecchia. Il Requirement sulle note protette dice che **la copia di una nota protetta resta protetta**.

## Fix options

### Descrivere il PIN nel Model

Il Model dell'esportazione PDF riscrive la transizione di Idle: per una nota protetta l'app attende il PIN corretto; con PIN errato o annullato la finestra di stampa non si apre. Il codice non cambia. Costo: una Proposal che aggiorna il Model dell'esportazione PDF, come già deciso nella Drift risolta.

### Tenere il PDF senza PIN

Il PDF di una nota protetta torna ad aprirsi senza chiedere il PIN, come dice oggi il Model. Il codice smette di chiedere il PIN per il PDF e il Requirement delle note protette va chiarito. Costo: il PDF di una nota protetta esce dall'app senza alcuna protezione, e la decisione già presa viene ribaltata.

### Niente PDF per le note protette

Per una nota protetta l'esportazione PDF non apre la finestra di stampa: l'utente deve prima togliere il lucchetto con il PIN. Il Model esclude le note protette dall'esportazione PDF, e il codice cambia con una sola condizione. Costo: il PDF di una nota protetta non è disponibile senza sbloccarla.

## Where in the code

lib/core/services/pdf_export_service.dart: exportNoteToPdf, controllo confirmPin per note protette
