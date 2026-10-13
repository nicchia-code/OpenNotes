---
column: done
technical: false
refs:
  - requirements/rules#drawing-canvas
  - requirements/data#drawing-canvas
  - drawing-canvas/Drawing/user.SAVE_DRAWING
drift: 71ynmepj
proposal: null
agent: false
created: 2026-10-12T07:38:53.685Z
finished: 2026-10-12T07:41:03.631Z
---
# Fix code to match the Model: Exported drawing keeps transparent holes where erased

## What happens

Nel disegno salvato le zone attraversate dalla gomma diventano **trasparenti**, non bianche. Sulla tela a schermo sembrano bianche, perché lo sfondo sta sotto i tratti; al salvataggio invece la gomma cancella anche lo sfondo bianco, che viene disegnato prima dei tratti.

## What should happen

Il disegno salvato è un'immagine 800×600 con **sfondo bianco**: anche dove è passata la gomma l'immagine deve restare bianca, come appare sulla tela.

## Chosen option

**Sfondo bianco sotto i tratti**

Al salvataggio lo sfondo bianco viene disegnato sotto tutti i tratti, invece che prima di essi, così la gomma cancella solo i tratti. Le zone cancellate risultano bianche, come sulla tela. Costo: poche righe nella sola esportazione; la tela non cambia.

## Where in the code

lib/ui/drawing/apple_pencil_canvas.dart: _exportCanvas e _createPaint. La gomma usa BlendMode.clear e viene disegnata dopo lo sfondo bianco.
