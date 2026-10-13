---
column: done
technical: false
refs:
  - note-editor/Protected/user.TOGGLE_CHECKLIST
drift: 5cmve79j
proposal: null
agent: false
created: 2026-10-12T14:20:57.151Z
finished: 2026-10-12T14:22:46.101Z
---
# Fix code to match the Model: Hidden note: style change counts as shown text for checklist

## What happens

In una nota protetta il cui testo non è mai stato mostrato, cambiare lo stile di una parte fa considerare il testo come già visto. Il comando checklist successivo modifica la riga della parte attiva invece di aggiungere una voce vuota in fondo alla nota. Se lo stile cambia su una parte diversa da quella attiva, la voce viene messa dopo la parte attiva e non in fondo.

## What should happen

Secondo il modello, una nota protetta il cui testo non è mai stato mostrato da quando l'app è aperta riceve la voce vuota in fondo. I cambi di stile non contano come testo mostrato: solo il testo realmente visualizzato permette di alternare la voce nella parte attiva.

## Chosen option

**Tenere separato il testo mostrato dallo stile**

Il sistema ricorda se il testo della nota è stato mostrato con un segnale che lo stile non modifica. Lo stile resta applicato al documento nascosto e la checklist torna in fondo alla nota, come descritto nel modello. Costo: un dato in più da tenere allineato quando la nota viene ricaricata o cambia.

## Where in the code

lib/ui/editor/notion_document_editor.dart: insertChecklist, setBlockType (creazione del controller dal cambio di stile)
