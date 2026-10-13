---
column: done
technical: false
refs:
  - drawing-canvas/Drawing
  - requirements/rules#drawing-canvas
drift: orvwk045
proposal: null
agent: false
created: 2026-10-12T10:59:40.497Z
finished: 2026-10-12T11:02:25.789Z
---
# Fix code to match the Model: Drawing canvas is a fixed 800×600 area that phone touch cannot scroll to

## What happens

Sul telefono la tela è più larga dello schermo e ha una dimensione fissa di 800×600 punti. Il tocco disegna e non scorre, quindi la parte di tela oltre il bordo dello schermo non si raggiunge: non si può disegnare fino al bordo destro. Su desktop lo scorrimento con rotella o trackpad c'è.

## What should happen

Il Model descrive una tela a schermo intero. Il Requirement fissa invece l'immagine salvata a 800×600 pixel. Oggi la tela non si adatta allo schermo e una parte resta inaccessibile su telefono. Il Model non dice come conciliare schermo intero e immagine 800×600.

## Chosen option

**Adattare la tela allo schermo e salvare a 800×600**

La tela occupa la larghezza disponibile e il disegno viene convertito in coordinate dell'immagine 800×600 al salvataggio. Tutta la superficie è raggiungibile con il dito. Costo: su schermi diversi i tratti appaiono di spessore diverso, e lo spessore dei tratti deve essere riportato alla scala dell'immagine.

## Where in the code

lib/ui/drawing/apple_pencil_canvas.dart: dimensione fissa della tela e scorrimento senza trascinamento con il tocco
