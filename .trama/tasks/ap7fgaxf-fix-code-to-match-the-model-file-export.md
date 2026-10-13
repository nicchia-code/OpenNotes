---
column: done
technical: false
refs:
  - export-markdown-file/Choosing destination/operating-system.FILE_SAVE_DIALOG_CLOSED
drift: 3asckbs9
proposal: null
agent: false
created: 2026-10-12T08:09:28.331Z
finished: 2026-10-12T08:11:22.170Z
---
# Fix code to match the Model: File export message shows the proposed name, not the saved file name

## What happens

Quando il file viene salvato, l'app mostra il messaggio di conferma con il nome proposto dal titolo. Se nella finestra di salvataggio l'utente cambia il nome del file, il messaggio mostra comunque il nome proposto, che non è più quello del file scritto.

## What should happen

Il Model dice che, dopo la scelta della posizione, l'app mostra un breve messaggio con il **nome del file esportato**: deve essere il nome con cui il file è stato davvero salvato. Il nome proposto è solo il punto di partenza della finestra di salvataggio.

## Chosen option

**Mostrare il nome con cui il file è stato salvato**

Il messaggio riprende il nome del file come restituito dalla finestra di salvataggio, quindi mostra sempre quello che l'utente ritrova nelle cartelle. Costo: il riferimento restituito non è uguale su tutte le piattaforme (su alcuni sistemi può essere un identificativo poco leggibile), quindi serve una regola per ricavare un nome leggibile e un ripiego sul nome proposto quando non è possibile.

## Where in the code

lib/ui/notes_list/note_actions.dart, caso di esportazione in Markdown: messaggio mostrato dopo la finestra di salvataggio
