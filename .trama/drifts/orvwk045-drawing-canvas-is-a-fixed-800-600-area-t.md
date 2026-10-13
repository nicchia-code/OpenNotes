---
status: resolved
resolution: fix-code
refs:
  - drawing-canvas/Drawing
  - requirements/rules#drawing-canvas
proposal: null
task: w7ocatw7
origin: null
critical: false
option: 1
note: null
resolvedBy: fz9axufm
created: 2026-10-12T10:45:37.093Z
---
# Drawing canvas is a fixed 800×600 area that phone touch cannot scroll to

## What happens

Sul telefono la tela è più larga dello schermo e ha una dimensione fissa di 800×600 punti. Il tocco disegna e non scorre, quindi la parte di tela oltre il bordo dello schermo non si raggiunge: non si può disegnare fino al bordo destro. Su desktop lo scorrimento con rotella o trackpad c'è.

## What should happen

Il Model descrive una tela a schermo intero. Il Requirement fissa invece l'immagine salvata a 800×600 pixel. Oggi la tela non si adatta allo schermo e una parte resta inaccessibile su telefono. Il Model non dice come conciliare schermo intero e immagine 800×600.

## Fix options

### Adattare la tela allo schermo e salvare a 800×600

La tela occupa la larghezza disponibile e il disegno viene convertito in coordinate dell'immagine 800×600 al salvataggio. Tutta la superficie è raggiungibile con il dito. Costo: su schermi diversi i tratti appaiono di spessore diverso, e lo spessore dei tratti deve essere riportato alla scala dell'immagine.

### Mantenere la tela 800×600 e far scorrere con il tocco

La dimensione resta quella attuale, ma serve un modo per spostarsi con il dito senza disegnare, ad esempio una modalità di spostamento o due dita. Costo: si aggiunge un'azione da imparare e disegnare sul bordo richiede di cambiare modalità.

### Tela 800×600 più piccola della finestra su telefono

Si adotta un rapporto 4:3 in punti logici più piccolo dello schermo, ad esempio 320×240 scalato per riempire la larghezza, lasciando invariata l'immagine salvata. Costo: il disegno resta piccolo su telefono e serve una scala ai tratti come nella prima opzione.

## Where in the code

lib/ui/drawing/apple_pencil_canvas.dart: dimensione fissa della tela e scorrimento senza trascinamento con il tocco
