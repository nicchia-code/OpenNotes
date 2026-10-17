# Drawing canvas

Una tela dove disegnare a mano libera: ha proporzioni 4:3, occupa la larghezza disponibile ed è centrata sullo schermo; l'immagine salvata ha sempre la stessa dimensione, qualunque sia lo schermo. Si apre solo dalla nota aperta, e il disegno finito entra in quella nota come immagine.

## States

### Closed (initial)
- `user.OPEN_DRAWING` → Drawing: solo con una nota aperta nell'editor. Su desktop il comando «Disegno» (pulsante della barra superiore o voce del menu «Inserisci») compare solo quando c'è una nota selezionata e non si è nel cestino; su mobile si apre dalla barra sopra la tastiera dell'editor. La tela parte vuota e la penna è nera.

### Drawing
Una tela bianca, anche dove si è usata la gomma, con una tavolozza di sette colori, una gomma, il comando per annullare l'ultimo tratto e quello per cancellare tutto.
- `user.CANCEL_DRAWING` → Closed: scarta il disegno.
- `user.SAVE_DRAWING` → Saving: esporta il disegno come immagine, anche se la tela è vuota, e lo salva tra gli allegati del vault.

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

### Saving
Il disegno viene esportato e salvato. La tela resta visibile; altri tocchi su «Fine» sono ignorati, quindi il disegno viene salvato e inserito una sola volta.
- `DRAWING_SAVED` → Closed: l'immagine è tra gli allegati; la tela si chiude.
- `DRAWING_SAVE_FAILED` → Drawing: l'esportazione o il salvataggio non sono riusciti; compare il messaggio «Disegno non salvato», la tela resta aperta con il disegno intatto e si può riprovare.

## Events

### DRAWING_SAVED
Emesso quando l'utente conferma il disegno e l'immagine è stata salvata tra gli allegati. L'editor della nota la inserisce nel documento.

### DRAWING_SAVE_FAILED
Emesso quando l'esportazione del disegno o il suo salvataggio tra gli allegati non riescono.
