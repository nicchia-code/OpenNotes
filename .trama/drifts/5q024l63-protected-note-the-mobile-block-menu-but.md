---
status: resolved
resolution: fix-code
refs:
  - note-editor/Protected
proposal: null
task: 82cxa19i
origin: null
critical: false
option: 1
note: null
resolvedBy: uo2rau9q
created: 2026-10-17T12:49:59.201Z
---
# Protected note: the mobile Block menu button arms a menu that opens on unlock

## What happens

Sul telefono la barra sopra la tastiera ha sempre il pulsante «Menu blocchi», anche con la nota protetta. Se il testo della nota è già stato mostrato in questa sessione, il pulsante segna la sezione come menu aperto senza mostrare nulla. Quando l'utente sblocca la nota con «Visualizza nota», il menu blocchi compare sotto quella sezione, come se l'utente lo avesse aperto. Se il testo non è mai stato mostrato in questa sessione, il pulsante non fa nulla.

## What should happen

Il Modello, per lo stato Protetto, elenca i comandi della barra che modificano e salvano il documento nascosto; il pulsante del menu blocchi non vi compare e il Modello non dice cosa fa. Il Requisito non dice nulla sul menu blocchi di una nota protetta. Quindi il Modello non copre il caso, e ciò che l'utente vede dopo lo sblocco non è descritto.

## Fix options

### Do nothing while the note is protected

Con la nota protetta il pulsante non apre né arma alcun menu. Costo: il pulsante non risponde nello stato Protetto, come gli altri comandi che non salvano nulla.

### Ask for the PIN from the button

Il pulsante chiede il PIN con la stessa finestra di «Visualizza nota» e apre il menu blocchi solo dopo lo sblocco; annullando non succede nulla. Costo: un passaggio in più dal pulsante, con una finestra di PIN aperta da una barra che oggi non la apre.

### Hide the button while the note is protected

Sul telefono la barra non mostra «Menu blocchi» quando la nota è protetta. Costo: la barra cambia forma secondo lo stato della nota, e le altre voci restano come sono.

## Where in the code

lib/ui/editor/notion_document_editor.dart: openBlockMenu e _openBlockMenu, che armano il menu anche con la nota nascosta; lib/ui/mobile/mobile_note_editor_screen.dart: pulsante onBlockMenu della barra, sempre attivo
