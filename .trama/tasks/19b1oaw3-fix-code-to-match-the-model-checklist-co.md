---
column: done
technical: false
refs:
  - note-editor/Protected/user.TOGGLE_CHECKLIST
drift: n2vqm9up
proposal: null
agent: false
created: 2026-10-12T12:12:02.066Z
finished: 2026-10-12T13:56:40.070Z
---
# Fix code to match the Model: Checklist command on a hidden note adds the item after the active part, not at the end

## What happens

Con la nota protetta e il testo mai mostrato, il comando checklist crea la voce vuota dopo la parte attiva di partenza, cioè la seconda sezione di testo. Se il documento ha più parti, la voce finisce nel mezzo, tra la seconda e la terza, e non in fondo.

## What should happen

Il Modello dice che, con il testo mai mostrato, la voce vuota viene aggiunta in fondo al documento nascosto, e che il comando la salva subito. Nello stato Aperto il Modello non dice dove va la voce quando la creazione avviene, quindi la posizione dopo la parte attiva non contraddice quello stato.

## Chosen option

**Aggiungere la voce in fondo, come nel Modello**

La voce vuota va sempre in fondo al documento quando il testo non è mai stato mostrato. Il Modello resta com'è. Cambia solo dove compare la voce nel documento nascosto: la nota, quando viene sbloccata, mostra la voce in fondo, come descritto. Costo: una riga in più nel ramo del comando checklist senza testo caricato.

## Where in the code

lib/ui/editor/notion_document_editor.dart: insertChecklist, ramo senza controller (nuova voce inserita dopo la parte attiva).
