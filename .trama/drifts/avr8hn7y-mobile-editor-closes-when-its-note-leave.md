---
status: resolved
resolution: fix-code
refs:
  - mobile-navigation/Editor from list
proposal: null
task: hpy1okh6
origin: null
critical: false
option: 1
note: null
resolvedBy: fiomlg7l
created: 2026-10-13T05:21:58.082Z
---
# Mobile editor closes when its note leaves the list, the Model keeps it open

## What happens

Quando la nota dell'editor esce dalla selezione mostrata (spostata in un'altra cartella, ripristinata dal cestino, oppure sparita dai dati con la sincronizzazione), l'editor si chiude da solo sulla schermata precedente. Il codice lo fa di proposito: un commento spiega che, uscita dalla lista, la nota non si può più salvare. Anche ripristinare la nota dal cestino da un editor aperto chiude l'editor.

## What should happen

Il Model dice che spostare la nota in un'altra cartella, fissarla o ripristinarla dal cestino lascia l'editor aperto, e che se la nota sparisce dai dati resta mostrata la sua ultima versione. Fissare la nota non la fa uscire dalla lista: lì il comportamento coincide.

## Fix options

### Tenere l'editor aperto come dice il Model

L'editor resta aperto e mostra l'ultima versione vista della nota, anche se la nota non è più nella selezione. Le modifiche continuano a essere salvate sulla nota. Costo: va verificato che il salvataggio di una nota fuori dalla lista funzioni davvero, e che nulla vada perso quando la sincronizzazione elimina la nota.

### Chiudere l'editor e correggere il Model

Si mantiene la chiusura attuale, salvando prima le ultime modifiche, e il Model viene corretto per dire che l'editor si chiude quando la nota esce dalla selezione. Costo: spostare o ripristinare una nota interrompe chi sta scrivendo, e il Model cambia in più punti (spostamento, ripristino, sincronizzazione).

### Restare aperto solo per spostamento e ripristino

Spostare e ripristinare dal cestino lasciano l'editor aperto come nel Model; solo l'eliminazione dai dati chiude l'editor, dopo aver salvato le ultime modifiche. Costo: nel codice servono due casi distinti, e il Model va precisato per la sola sincronizzazione.

## Where in the code

lib/ui/mobile/mobile_note_editor_screen.dart: il controllo in build che chiude l'editor quando la nota non è più elencata (_lastKnownNote e _leave).
