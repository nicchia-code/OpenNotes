---
column: done
technical: false
refs:
  - drawing-canvas/Drawing/user.SAVE_DRAWING
  - requirements/rules#drawing-canvas
drift: xdkh11lz
proposal: null
agent: false
created: 2026-10-12T08:09:28.312Z
finished: 2026-10-12T08:11:36.931Z
---
# Fix code to match the Model: Exported drawing is cut or shifted by the canvas size

## What happens

Il disegno viene salvato come se la tela fosse grande quanto l'immagine finale: i tratti restano dove sono stati tracciati sullo schermo, senza essere adattati alla cornice. Su schermi piccoli il disegno compare **in un angolo** dell'immagine, con molto bianco intorno; su schermi o finestre più grandi di 800×600 le parti che cadono fuori dalla cornice **spariscono** dall'allegato, anche se l'utente le ha viste sulla tela.

## What should happen

Il disegno salvato deve essere un'immagine 800×600 con sfondo bianco che riproduce il disegno fatto sulla tela. Il Model e il requisito fissano la dimensione dell'immagine, ma non dicono come la tela si traduce nella cornice; la scelta cambia ciò che l'utente ritrova nell'allegato, quindi va decisa.

## Chosen option

**Tela di dimensione fissa 800×600**

La zona di disegno ha sempre le proporzioni e la dimensione della cornice: ciò che si disegna è esattamente ciò che viene salvato, e lo spessore dei tratti resta quello del requisito. Costo: su telefono o finestra piccola la tela è più grande dello schermo e va fatta scorrere o ingrandita; la modifica riguarda la tela e l'esportazione.

## Where in the code

lib/ui/drawing/apple_pencil_canvas.dart: _exportCanvas disegna i tratti alle coordinate della tela su una superficie di 800×600, senza trasformazioni; la tela occupa tutta l'area disponibile sotto la barra.
