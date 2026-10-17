---
column: done
technical: false
refs:
  - note-editor/Protected
drift: 5q024l63
proposal: null
agent: false
created: 2026-10-17T13:41:35.388Z
finished: 2026-10-17T13:47:48.621Z
---
# Fix code to match the Model: Protected note: the mobile Block menu button arms a menu that opens on unlock

## What happens

Sul telefono la barra sopra la tastiera ha sempre il pulsante «Menu blocchi», anche con la nota protetta. Se il testo della nota è già stato mostrato in questa sessione, il pulsante segna la sezione come menu aperto senza mostrare nulla. Quando l'utente sblocca la nota con «Visualizza nota», il menu blocchi compare sotto quella sezione, come se l'utente lo avesse aperto. Se il testo non è mai stato mostrato in questa sessione, il pulsante non fa nulla.

## What should happen

Il Modello, per lo stato Protetto, elenca i comandi della barra che modificano e salvano il documento nascosto; il pulsante del menu blocchi non vi compare e il Modello non dice cosa fa. Il Requisito non dice nulla sul menu blocchi di una nota protetta. Quindi il Modello non copre il caso, e ciò che l'utente vede dopo lo sblocco non è descritto.

## Chosen option

**Do nothing while the note is protected**

Con la nota protetta il pulsante non apre né arma alcun menu. Costo: il pulsante non risponde nello stato Protetto, come gli altri comandi che non salvano nulla.

## Where in the code

lib/ui/editor/notion_document_editor.dart: openBlockMenu e _openBlockMenu, che armano il menu anche con la nota nascosta; lib/ui/mobile/mobile_note_editor_screen.dart: pulsante onBlockMenu della barra, sempre attivo
