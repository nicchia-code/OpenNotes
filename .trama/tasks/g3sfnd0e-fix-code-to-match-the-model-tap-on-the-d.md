---
column: done
technical: false
refs:
  - drawing-canvas/Pen/user.DRAW_STROKE
  - drawing-canvas/Eraser/user.DRAW_STROKE
drift: nvfm46hb
proposal: null
agent: false
created: 2026-10-13T10:57:25.236Z
finished: 2026-10-13T10:59:27.821Z
---
# Fix code to match the Model: Tap on the drawing canvas leaves no mark, the Model does not say so

## What happens

Un tocco sulla tela, senza trascinare il dito o la penna, non lascia alcun segno: né con il colore scelto né con la gomma. Solo un movimento crea un tratto.

## What should happen

Il Model dice che un tratto aggiunge un segno del colore scelto e che la gomma cancella lungo il tratto, ma non dice cosa succede con un solo tocco. Il Model tace su un caso che cambia ciò che l'utente vede: un punto oppure niente.

## Chosen option

**Un tocco lascia un punto**

Un tocco senza movimento lascia un punto del colore scelto, oppure cancella un punto con la gomma, come un tratto di lunghezza zero. La tela risponde subito a ogni tocco, come nelle note di Apple. Costo: un tocco involontario lascia un segno, che si toglie con Annulla o con la gomma.

## Where in the code

lib/ui/drawing/apple_pencil_canvas.dart: il gesto di trascinamento sulla superficie della tela
