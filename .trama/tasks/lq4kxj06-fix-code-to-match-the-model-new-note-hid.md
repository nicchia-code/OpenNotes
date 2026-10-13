---
column: done
technical: false
refs:
  - note-selection/Note selected
drift: kdjlai9a
proposal: null
agent: false
created: 2026-10-12T07:38:53.832Z
finished: 2026-10-12T07:43:30.576Z
---
# Fix code to match the Model: New note hidden by an active search leaves the editor empty

## What happens

Con una ricerca attiva, creando una nota nuova il sistema la seleziona, ma la nota può non rientrare nell'elenco della vista: il titolo «Nuova nota» e il contenuto iniziale non corrispondono alla ricerca. L'editor allora mostra «Nessuna nota selezionata» e la nota non compare nell'elenco. Alla ricarica successiva dell'elenco la selezione passa alla prima nota visibile.

## What should happen

Il Model dice che creare una nota seleziona la nuova nota, che viene aperta nell'editor, e che la nota selezionata è sempre una della vista corrente. Quindi la nota appena creata deve essere visibile nell'elenco e aperta nell'editor, anche quando una ricerca era attiva.

## Chosen option

**Clear the search when a note is created**

Alla creazione la ricerca testuale viene azzerata, così la nuova nota compare nell'elenco e si apre nell'editor come previsto. Costo: chi stava cercando perde il filtro e deve riscriverlo. È l'unico cambio di vista che la creazione provoca.

## Where in the code

lib/core/state/notes_provider.dart (createNote, selectedNote); lib/ui/shell/adaptive_app_shell.dart (editor placeholder)
