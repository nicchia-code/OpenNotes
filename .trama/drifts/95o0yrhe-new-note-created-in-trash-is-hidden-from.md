---
status: resolved
resolution: fix-code
refs:
  - note-selection/Note selected/user.CREATE_NOTE
proposal: null
task: xthjl4e4
origin: null
critical: false
option: 1
note: null
resolvedBy: p136jufl
created: 2026-10-12T08:00:39.071Z
---
# New note created in trash is hidden from the list

## What happens

Con la vista **Cestino** aperta, creando una nota dal pulsante di nuova nota (dall'elenco o dalla schermata delle cartelle su mobile) la nota viene salvata nelle note attive, quindi non compare nell'elenco del cestino. Il sistema la seleziona comunque: la nota selezionata non è più una della vista corrente, e alla ricarica successiva la selezione passa alla prima nota del cestino.

## What should happen

Il Model dice che creare una nota seleziona la nuova nota e che la nota selezionata è sempre una della vista corrente, cioè quella evidenziata nell'elenco e aperta nell'editor. Nel Model non è scritto cosa succede se si crea una nota mentre si guarda il cestino: la regola non può essere rispettata così com'è, e la scelta cambia ciò che vede l'utente.

## Fix options

### Hide the new-note button in the trash on mobile

Nella vista Cestino su mobile il pulsante di nuova nota non compare, come già accade su desktop. Si evita la nota fuori vista, ma l'utente deve uscire dal cestino per creare una nota. Costo: una funzione in meno in quella vista, e il comportamento mobile torna allineato a quello desktop.

### Switch to all notes when creating from the trash

Creando una nota mentre si guarda il cestino la vista passa a Tutte le note e la nuova nota viene selezionata e mostrata nell'elenco. Costo: l'utente perde la posizione nel cestino senza averlo chiesto, e la regola di creazione cambia a seconda della vista.

### Keep the new note selected outside the trash

La nota resta aperta nell'editor anche se non compare nell'elenco del cestino, e scompare alla ricarica successiva. Costo: la selezione è fuori dalla vista corrente, contro la regola del Model, e l'utente non ritrova la nota dove l'ha creata.

## Where in the code

lib/core/state/notes_provider.dart (createNote); lib/ui/mobile/mobile_notes_list_screen.dart (footer new-note button); lib/ui/mobile/mobile_folders_screen.dart (new-note button)
