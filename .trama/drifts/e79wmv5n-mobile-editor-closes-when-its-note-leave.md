---
status: resolved
resolution: fix-code
refs:
  - mobile-navigation/Editor from list
proposal: null
task: 6j7824lt
origin: null
critical: false
option: 1
note: null
resolvedBy: qcyswaks
created: 2026-10-12T17:30:32.460Z
---
# Mobile editor closes when its note leaves the list, the Model says it stays open

## What happens

Sul telefono, se la nota aperta esce dalla selezione corrente (spostata in un'altra cartella o ripristinata dal cestino) oppure sparisce dai dati, l'editor si chiude e riporta alla lista o alle Cartelle. Questa chiusura è stata introdotta per evitare che le modifiche successive vadano perse: il testo non viene più mostrato come ultima versione.

## What should happen

Il Model di navigazione mobile dice che spostare la nota, fissarla o ripristinarla dal cestino **lasciano l'editor aperto**, e che se la nota sparisce dai dati **resta mostrata la sua ultima versione**. Il Model dell'editor, però, chiude l'editor mobile solo per cestino ed eliminazione, e il salvataggio accetta solo le note dell'elenco caricato. Le tre descrizioni non si accordano con la chiusura attuale.

## Fix options

### Chiudere l'editor quando la nota esce dall'elenco

L'editor torna alla lista o alle Cartelle appena la nota non è più nella selezione, dopo aver consegnato il testo in attesa. Nessuna modifica va persa e il codice resta com'è. Costo: la schermata si chiude anche per cambiamenti che l'utente non ha fatto, e il Model va aggiornato in tre punti: navigazione mobile, editor e salvataggio della nota.

### Tenere l'editor aperto e salvare la nota ovunque si trovi

Dopo uno spostamento o un ripristino l'editor resta aperto e ogni modifica viene salvata sulla nota nella sua nuova posizione, anche nel cestino. Il Model di navigazione resta com'è. Costi: il salvataggio deve riconoscere la nota aperta fuori dall'elenco e va regolata la regola del salvataggio; la nota eliminata dal cloud non deve tornare per effetto di una modifica.

## Where in the code

lib/ui/mobile/mobile_note_editor_screen.dart (build: chiusura quando la nota non è più nell'elenco caricato); lib/core/state/notes_provider.dart (salvataggio del testo: solo note dell'elenco caricato)
