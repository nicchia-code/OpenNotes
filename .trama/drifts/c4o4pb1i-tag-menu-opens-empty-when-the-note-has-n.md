---
status: resolved
resolution: fix-code
refs:
  - editor-suggestions/Tag suggestions
  - requirements/rules#editor-suggestions
proposal: null
task: dq4eshal
origin: null
critical: false
option: 1
note: null
resolvedBy: 1c1mgdxc
created: 2026-10-13T10:40:40.470Z
---
# Tag menu opens empty when the note has no tags and nothing is typed after the hash

## What happens

Quando l'utente scrive un cancelletto da solo in una sezione di testo e l'app non ha ancora nessun tag, compare il menu dei tag con la sola intestazione «TAG SUGGERITI» e nessuna voce sotto: non c'è né un tag da proporre né una voce «Crea».

## What should happen

Il Modello dice quali voci mostra il menu dei tag quando ci sono tag e quando il testo digitato non corrisponde a nessun tag, ma non dice se il menu compare quando non c'è nulla da proporre. Il Requisito tace allo stesso modo. La scelta cambia ciò che l'utente vede alla prima scrittura di un cancelletto.

## Fix options

### Non mostrare il menu finché non c'è nulla da proporre

Il menu dei tag compare solo quando c'è almeno un tag da proporre o del testo digitato dopo il cancelletto. Senza tag e senza testo il cancelletto resta semplice testo. Costo: l'utente non vede il menu alla prima scrittura di un cancelletto in un'app senza tag; il Modello va completato con questa regola.

### Mostrare un avviso di nessun tag

Il menu compare anche senza tag, con la riga «Nessun tag ancora» al posto dell'elenco vuoto, finché l'utente non scrive testo dopo il cancelletto. Costo: una scritta nuova da descrivere nel Modello e da tradurre.

### Lasciare il menu vuoto così com'è

Il Modello resta com'è e l'intestazione «TAG SUGGERITI» resta da sola finché non esiste un tag. Costo: l'utente vede un riquadro senza contenuto alla prima scrittura di un cancelletto, e il Modello non descrive questo caso.

## Where in the code

lib/ui/editor/notion_document_editor.dart (_buildFloatingTagMenu)
