---
status: resolved
resolution: fix-code
refs:
  - note-editor/Open/user.NAVIGATE_BACK
proposal: null
task: 42q1h3r2
origin: null
critical: false
option: 1
note: null
resolvedBy: v0urpc7v
created: 2026-10-13T12:47:36.043Z
---
# Model still says the editor discards the waiting edit when the note is trashed, but trash saves it first

## What happens

Spostare la nota nel cestino, dal menu dell'editor mobile o dalla barra desktop, consegna prima il testo ancora in attesa nell'editor: moveToTrash chiama _settleContent, che passa il testo all'editor e lo scrive subito nel database e nel file. Solo dopo la nota va nel cestino, e l'editor mobile si chiude o quello desktop passa alla nota successiva. La modifica digitata nell'ultimo mezzo secondo quindi viene salvata, non scartata.

## What should happen

Il Model dell'editor dice che, quando la nota aperta viene spostata nel cestino dal menu dell'editor mobile, l'editor si chiude allo stesso modo di NAVIGATE_BACK, cioè scartando la modifica in attesa senza salvarla. La decisione presa per le note (Drift qe5hjjfy, risolto con la Task 4vn00ef8) è invece consegnare e scrivere il testo in attesa prima di ogni cambio di stato, cestino compreso. Le due regole non possono essere seguite insieme: il Model dell'editor non è stato aggiornato dopo quella decisione.

## Fix options

### Consegnare la modifica prima del cestino e correggere il Model

Il testo digitato poco prima dello spostamento viene salvato, come già accade per duplicare, condividere ed esportare. Il Model dell'editor va corretto per le uscite dal cestino: sul mobile l'editor si chiude dopo la consegna, sul desktop passa alla nota successiva. Costo: una scrittura in più quando c'è un testo in attesa; il codice resta com'è.

### Scartare la modifica in attesa quando la nota va nel cestino, come dice il Model

Il comando del cestino non consegna più il testo dell'editor, e i caratteri digitati nell'ultimo mezzo secondo prima dello spostamento vanno persi, senza avviso. Costo: un'eccezione in _settleContent solo per il cestino, senza cambiare il Model; la versione salvata resta quella di prima, quindi non si riscrive testo vecchio.
