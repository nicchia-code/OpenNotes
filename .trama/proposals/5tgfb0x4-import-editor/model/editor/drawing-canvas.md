# Drawing canvas

Una tela a schermo intero dove disegnare a mano libera. Il disegno finito entra nella nota aperta come immagine.

## States

### Closed (initial)
- `user.OPEN_DRAWING` → Drawing: dalla barra degli strumenti su desktop o dalla barra sopra la tastiera su mobile. La tela parte vuota e la penna è nera.

### Drawing
Una tela bianca con una tavolozza di sette colori, una gomma, il comando per annullare l'ultimo tratto e quello per cancellare tutto.
- `user.CANCEL_DRAWING` → Closed: scarta il disegno.
- `user.SAVE_DRAWING` → Closed: esporta il disegno come immagine, anche se la tela è vuota, e lo salva tra gli allegati del vault.

#### Pen (initial)
Si disegna con il colore scelto.
- `user.DRAW_STROKE` → Pen: aggiunge un tratto del colore scelto.
- `user.SELECT_DRAWING_COLOR` → Pen
- `user.TOGGLE_ERASER` → Eraser
- `user.UNDO_STROKE` → Pen: se c'è almeno un tratto. Toglie l'ultimo.
- `user.CLEAR_DRAWING` → Pen: toglie tutti i tratti.

#### Eraser
Ogni tratto cancella ciò che attraversa.
- `user.DRAW_STROKE` → Eraser: cancella lungo il tratto.
- `user.SELECT_DRAWING_COLOR` → Pen
- `user.TOGGLE_ERASER` → Pen
- `user.UNDO_STROKE` → Eraser: se c'è almeno un tratto. Toglie l'ultimo.
- `user.CLEAR_DRAWING` → Eraser: toglie tutti i tratti.

## Events

### DRAWING_SAVED
Emesso quando l'utente conferma il disegno e l'immagine è stata salvata tra gli allegati. L'editor della nota la inserisce nel documento.
