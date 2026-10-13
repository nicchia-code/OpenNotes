---
status: resolved
resolution: fix-code
refs:
  - drawing-canvas/Pen/user.DRAW_STROKE
  - drawing-canvas/Eraser/user.DRAW_STROKE
proposal: null
task: g3sfnd0e
origin: null
critical: false
option: 1
note: null
resolvedBy: 1c1mgdxc
created: 2026-10-13T10:38:54.329Z
---
# Tap on the drawing canvas leaves no mark, the Model does not say so

## What happens

Un tocco sulla tela, senza trascinare il dito o la penna, non lascia alcun segno: né con il colore scelto né con la gomma. Solo un movimento crea un tratto.

## What should happen

Il Model dice che un tratto aggiunge un segno del colore scelto e che la gomma cancella lungo il tratto, ma non dice cosa succede con un solo tocco. Il Model tace su un caso che cambia ciò che l'utente vede: un punto oppure niente.

## Fix options

### Un tocco lascia un punto

Un tocco senza movimento lascia un punto del colore scelto, oppure cancella un punto con la gomma, come un tratto di lunghezza zero. La tela risponde subito a ogni tocco, come nelle note di Apple. Costo: un tocco involontario lascia un segno, che si toglie con Annulla o con la gomma.

### Un tocco non lascia segni

Resta il comportamento attuale: solo un movimento crea un tratto, e il codice non cambia. Costo: un tocco sulla tela non dà alcuna risposta visibile, e l'utente può pensare che la penna non funzioni. La scelta va poi scritta nel Model.

## Where in the code

lib/ui/drawing/apple_pencil_canvas.dart: il gesto di trascinamento sulla superficie della tela
