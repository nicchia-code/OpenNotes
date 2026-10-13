---
status: resolved
resolution: fix-code
refs:
  - drawing-canvas/Drawing/user.SAVE_DRAWING
  - requirements/rules#drawing-canvas
proposal: null
task: kdgf6mfk
origin: null
critical: false
option: 1
note: null
resolvedBy: p136jufl
created: 2026-10-12T07:59:35.713Z
---
# Exported drawing is cut or shifted by the canvas size

## What happens

Il disegno viene salvato come se la tela fosse grande quanto l'immagine finale: i tratti restano dove sono stati tracciati sullo schermo, senza essere adattati alla cornice. Su schermi piccoli il disegno compare **in un angolo** dell'immagine, con molto bianco intorno; su schermi o finestre più grandi di 800×600 le parti che cadono fuori dalla cornice **spariscono** dall'allegato, anche se l'utente le ha viste sulla tela.

## What should happen

Il disegno salvato deve essere un'immagine 800×600 con sfondo bianco che riproduce il disegno fatto sulla tela. Il Model e il requisito fissano la dimensione dell'immagine, ma non dicono come la tela si traduce nella cornice; la scelta cambia ciò che l'utente ritrova nell'allegato, quindi va decisa.

## Fix options

### Tela di dimensione fissa 800×600

La zona di disegno ha sempre le proporzioni e la dimensione della cornice: ciò che si disegna è esattamente ciò che viene salvato, e lo spessore dei tratti resta quello del requisito. Costo: su telefono o finestra piccola la tela è più grande dello schermo e va fatta scorrere o ingrandita; la modifica riguarda la tela e l'esportazione.

### Adattare il disegno alla cornice

Al salvataggio il disegno viene ridimensionato proporzionalmente per entrare in 800×600 e centrato su sfondo bianco, così nulla viene tagliato. Costo: i tratti vengono scalati insieme al disegno, quindi lo spessore nel file non è più quello indicato dal requisito; su schermi con proporzioni diverse restano bande bianche.

### Mostrare la cornice sulla tela

La tela resta com'è, ma un riquadro 800×600 indica la parte che verrà salvata, e il resto è visibile ma escluso. Costo: l'utente vede subito cosa andrà perso, senza che il file cambi; su schermi piccoli il riquadro può non entrare, e il ritaglio resta.

## Where in the code

lib/ui/drawing/apple_pencil_canvas.dart: _exportCanvas disegna i tratti alle coordinate della tela su una superficie di 800×600, senza trasformazioni; la tela occupa tutta l'area disponibile sotto la barra.
