---
status: resolved
resolution: fix-code
refs:
  - note-selection/Note selected
proposal: null
task: lq4kxj06
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:33:15.852Z
---
# New note hidden by an active search leaves the editor empty

## What happens

Con una ricerca attiva, creando una nota nuova il sistema la seleziona, ma la nota può non rientrare nell'elenco della vista: il titolo «Nuova nota» e il contenuto iniziale non corrispondono alla ricerca. L'editor allora mostra «Nessuna nota selezionata» e la nota non compare nell'elenco. Alla ricarica successiva dell'elenco la selezione passa alla prima nota visibile.

## What should happen

Il Model dice che creare una nota seleziona la nuova nota, che viene aperta nell'editor, e che la nota selezionata è sempre una della vista corrente. Quindi la nota appena creata deve essere visibile nell'elenco e aperta nell'editor, anche quando una ricerca era attiva.

## Fix options

### Clear the search when a note is created

Alla creazione la ricerca testuale viene azzerata, così la nuova nota compare nell'elenco e si apre nell'editor come previsto. Costo: chi stava cercando perde il filtro e deve riscriverlo. È l'unico cambio di vista che la creazione provoca.

### Open the new note even outside the search

La nuova nota resta aperta nell'editor anche se la ricerca non la mostra. Costo: l'elenco non contiene la nota aperta, la nota scompare alla ricarica successiva e serve un'eccezione alla regola che la selezione è una della vista corrente.

### Keep the search and select nothing

La nota viene creata con la ricerca attiva ma non selezionata, e l'editor resta vuoto. Costo: l'utente non vede subito la nota appena creata e deve cercarla; il comportamento si discosta dal Model, che seleziona la nuova nota.

## Where in the code

lib/core/state/notes_provider.dart (createNote, selectedNote); lib/ui/shell/adaptive_app_shell.dart (editor placeholder)
