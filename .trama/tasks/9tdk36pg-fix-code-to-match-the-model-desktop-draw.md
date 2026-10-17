---
column: done
technical: false
refs:
  - drawing-canvas/Closed/user.OPEN_DRAWING
drift: null
proposal: null
agent: false
created: 2026-10-17T14:08:42.168Z
finished: 2026-10-17T14:39:01.892Z
---
# Fix code to match the Model: Desktop drawing command shown with no note selected or in the trash

Il Model dice che su desktop il comando «Disegno» (pulsante della barra superiore e voce del menu «Inserisci») compare solo quando c'è una nota selezionata e la nota non è nel cestino. Oggi il comando è sempre attivo: anche con nessuna nota selezionata, dove la tela si apre e il disegno finito va perso senza entrare in nessuna nota, e anche con una nota nel cestino, dove il disegno entra in una nota che il Model non consente. Quando il comando non è disponibile, non deve comparire né aprire la tela, in nessuna delle due forme (pulsante e voce di menu). Sul telefono non cambia nulla: il comando resta nella barra sopra la tastiera dell'editor.
