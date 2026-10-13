---
column: done
technical: false
refs:
  - note-editor/Open/user.TOGGLE_CHECKLIST
drift: igia0uy7
proposal: null
agent: false
created: 2026-10-12T11:27:34.885Z
finished: 2026-10-12T11:31:08.232Z
---
# Fix code to match the Model: Checklist with the cursor in a table: the Model does not say where the item goes

## What happens

Con il cursore in una tabella, il pulsante checklist non tocca nulla vicino al cursore: aggiunge una voce vuota in fondo alla nota e il cursore salta lì, lontano dalla tabella in cui si lavora. Nelle sezioni di testo, invece, la voce compare sulla riga del cursore.

## What should happen

Il Modello dice che il pulsante alterna la voce di checklist sulla riga del cursore, oppure la crea. Una tabella non ha righe di testo e il Modello non dice dove deve finire la voce creata in questo caso: non si può seguire alla lettera, serve una scelta.

## Chosen option

**Creare la voce subito dopo la tabella**

La voce vuota va nella posizione della tabella attiva, come accade per tabelle e foto, e riceve il cursore. Costo: nasce una sezione di testo in più in quel punto; il Modello va aggiornato con questo caso.

## Where in the code

lib/ui/editor/notion_document_editor.dart: insertChecklist, ramo in cui non c'è una sezione di testo attiva con il controller
