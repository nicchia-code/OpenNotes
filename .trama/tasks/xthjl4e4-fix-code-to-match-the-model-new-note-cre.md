---
column: done
technical: false
refs:
  - note-selection/Note selected/user.CREATE_NOTE
drift: 95o0yrhe
proposal: null
agent: false
created: 2026-10-12T08:09:28.325Z
finished: 2026-10-12T08:12:47.480Z
---
# Fix code to match the Model: New note created in trash is hidden from the list

## What happens

Con la vista **Cestino** aperta, creando una nota dal pulsante di nuova nota (dall'elenco o dalla schermata delle cartelle su mobile) la nota viene salvata nelle note attive, quindi non compare nell'elenco del cestino. Il sistema la seleziona comunque: la nota selezionata non è più una della vista corrente, e alla ricarica successiva la selezione passa alla prima nota del cestino.

## What should happen

Il Model dice che creare una nota seleziona la nuova nota e che la nota selezionata è sempre una della vista corrente, cioè quella evidenziata nell'elenco e aperta nell'editor. Nel Model non è scritto cosa succede se si crea una nota mentre si guarda il cestino: la regola non può essere rispettata così com'è, e la scelta cambia ciò che vede l'utente.

## Chosen option

**Hide the new-note button in the trash on mobile**

Nella vista Cestino su mobile il pulsante di nuova nota non compare, come già accade su desktop. Si evita la nota fuori vista, ma l'utente deve uscire dal cestino per creare una nota. Costo: una funzione in meno in quella vista, e il comportamento mobile torna allineato a quello desktop.

## Where in the code

lib/core/state/notes_provider.dart (createNote); lib/ui/mobile/mobile_notes_list_screen.dart (footer new-note button); lib/ui/mobile/mobile_folders_screen.dart (new-note button)
