---
status: resolved
resolution: fix-code
refs:
  - note-editor/Protected/user.TOGGLE_CHECKLIST
proposal: null
task: ec7nadjr
origin: null
critical: false
option: 1
note: null
resolvedBy: 3tg049lq
created: 2026-10-12T14:17:33.460Z
---
# Hidden note: style change counts as shown text for checklist

## What happens

In una nota protetta il cui testo non è mai stato mostrato, cambiare lo stile di una parte fa considerare il testo come già visto. Il comando checklist successivo modifica la riga della parte attiva invece di aggiungere una voce vuota in fondo alla nota. Se lo stile cambia su una parte diversa da quella attiva, la voce viene messa dopo la parte attiva e non in fondo.

## What should happen

Secondo il modello, una nota protetta il cui testo non è mai stato mostrato da quando l'app è aperta riceve la voce vuota in fondo. I cambi di stile non contano come testo mostrato: solo il testo realmente visualizzato permette di alternare la voce nella parte attiva.

## Fix options

### Tenere separato il testo mostrato dallo stile

Il sistema ricorda se il testo della nota è stato mostrato con un segnale che lo stile non modifica. Lo stile resta applicato al documento nascosto e la checklist torna in fondo alla nota, come descritto nel modello. Costo: un dato in più da tenere allineato quando la nota viene ricaricata o cambia.

### Far contare lo stile come testo mostrato

Il modello diventa quello che il codice già fa: un cambio di stile rende il testo già visto, e la checklist successiva alterna la voce nella parte attiva. Nessun codice da cambiare, ma va aggiornata la descrizione del modello. Costo: una nota mai aperta si comporta in modo diverso a seconda che abbia avuto uno stile cambiato.

## Where in the code

lib/ui/editor/notion_document_editor.dart: insertChecklist, setBlockType (creazione del controller dal cambio di stile)
