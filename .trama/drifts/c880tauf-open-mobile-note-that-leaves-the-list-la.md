---
status: resolved
resolution: fix-code
refs:
  - note-editor/Open
proposal: null
task: tua1rzje
origin: null
critical: false
option: 1
note: null
resolvedBy: psazi867
created: 2026-10-12T17:02:32.379Z
---
# Open mobile note that leaves the list: later edits are lost

## What happens

Sull'editor mobile, se la nota aperta esce dall'elenco caricato, per esempio perché viene spostata in un'altra cartella dal suo menu o perché la sincronizzazione la elimina, l'editor resta aperto e mostra ancora il testo. Le modifiche fatte da quel momento non vengono salvate né in memoria, né nel database, né nel file. Non compare nessun avviso, e la nota nella sua nuova posizione conserva il testo di prima.

## What should happen

Il Model dice che l'editor consegna il documento intero a ogni modifica e che la nota resta modificabile, ma il salvataggio accetta solo le note presenti nell'elenco caricato. Per l'editor mobile il Model prevede la chiusura quando la nota finisce nel cestino o viene eliminata dal suo menu, ma non dice nulla sullo spostamento in un'altra cartella né sulla sparizione della nota per sincronizzazione. Il Model non dice quindi se l'editor debba chiudersi o continuare a salvare: la scelta cambia ciò che l'utente vede e se il testo viene conservato.

## Fix options

### Close the mobile editor whenever its note leaves the list

Ogni volta che la nota aperta esce dall'elenco, per spostamento o per sincronizzazione, l'editor mobile torna all'elenco, come già fa per il cestino e l'eliminazione. Il testo ancora in attesa viene consegnato prima della chiusura, così non si perde nulla. Costa: la schermata si chiude anche per cambiamenti che l'utente non ha fatto, e il Model va esteso con questi casi.

### Keep the editor open and save edits to the note wherever it is

L'editor resta aperto e ogni modifica viene salvata sulla nota anche se non è più nell'elenco caricato, nella sua nuova cartella o nel cestino. Così il Model resta com'è: l'editor consegna sempre il documento. Costa: il salvataggio deve riconoscere la nota aperta anche fuori dall'elenco, e va deciso cosa succede a una nota eliminata dal cloud, che non deve tornare per effetto di una modifica.

### Close only on move and keep deletions as they are

L'editor mobile si chiude solo quando la nota viene spostata dal suo menu, come già accade per il cestino. Le eliminazioni che arrivano dalla sincronizzazione restano come oggi: l'editor resta aperto e le modifiche successive si perdono. Costa: il caso della sincronizzazione resta scoperto e va deciso a parte.

## Where in the code

lib/ui/mobile/mobile_note_editor_screen.dart (menu Sposta e uscita dall'editor); lib/core/state/notes_provider.dart (updateNoteContent esce senza salvare se la nota non è nell'elenco caricato).
