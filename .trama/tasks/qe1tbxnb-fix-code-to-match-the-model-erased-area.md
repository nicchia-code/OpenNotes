---
column: done
technical: false
refs:
  - drawing-canvas/Drawing
  - requirements/rules#drawing-canvas
drift: null
proposal: null
agent: false
created: 2026-10-12T10:45:28.628Z
finished: 2026-10-12T13:53:13.528Z
---
# Fix code to match the Model: Erased area of the drawing canvas shows the page background, not white

La tela del disegno è bianca nel Model. Sul proprio schermo, la parte cancellata dalla gomma deve restare bianca, come nell'immagine salvata. Oggi, con il tema scuro, la gomma lascia vedere lo sfondo della pagina (nero) invece del bianco; l'immagine esportata è già bianca. Fare in modo che la tela mostri il bianco anche dove la gomma è passata, senza cambiare il comportamento della gomma né lo spessore dei tratti.
