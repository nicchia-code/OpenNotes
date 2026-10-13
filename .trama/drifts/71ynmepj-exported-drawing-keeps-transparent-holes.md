---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#drawing-canvas
  - requirements/data#drawing-canvas
  - drawing-canvas/Drawing/user.SAVE_DRAWING
proposal: null
task: px6d2obm
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:24:56.628Z
---
# Exported drawing keeps transparent holes where erased

## What happens

Nel disegno salvato le zone attraversate dalla gomma diventano **trasparenti**, non bianche. Sulla tela a schermo sembrano bianche, perché lo sfondo sta sotto i tratti; al salvataggio invece la gomma cancella anche lo sfondo bianco, che viene disegnato prima dei tratti.

## What should happen

Il disegno salvato è un'immagine 800×600 con **sfondo bianco**: anche dove è passata la gomma l'immagine deve restare bianca, come appare sulla tela.

## Fix options

### Sfondo bianco sotto i tratti

Al salvataggio lo sfondo bianco viene disegnato sotto tutti i tratti, invece che prima di essi, così la gomma cancella solo i tratti. Le zone cancellate risultano bianche, come sulla tela. Costo: poche righe nella sola esportazione; la tela non cambia.

### La gomma dipinge di bianco

La gomma non cancella più, ma disegna in bianco sopra i tratti, sia sulla tela sia nel file. Il risultato visibile è lo stesso e il file ha sempre lo sfondo bianco. Costo: se un domani lo sfondo non fosse bianco, la gomma andrebbe ripensata; l'annullamento continua a funzionare.

### Accettare lo sfondo trasparente

Le zone cancellate restano trasparenti nel file, come oggi, e il requisito dello sfondo bianco va cambiato di conseguenza. Costo: nessun lavoro nel codice, ma su uno sfondo scuro o in un'altra app le cancellature appaiono come buchi, e il file non corrisponde più alla tela.

## Where in the code

lib/ui/drawing/apple_pencil_canvas.dart: _exportCanvas e _createPaint. La gomma usa BlendMode.clear e viene disegnata dopo lo sfondo bianco.
