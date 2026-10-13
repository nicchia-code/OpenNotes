---
status: approved
kind: resolution
automatic: true
drifts:
  - drift: qwjeec17
    decision: fix-code
    option: 1
  - drift: 56uiwkvb
    decision: fix-code
    option: 1
  - drift: 3ztwg41p
    decision: fix-code
    option: 1
  - drift: ootkeuzx
    decision: fix-code
    option: 1
  - drift: wkoe92qh
    decision: fix-code
    option: 1
base: {}
delete: []
created: 2026-10-12T08:30:09.265Z
---
# Resolve export, loading and checklist Drifts

Risoluzione automatica: per ciascun Drift si sceglie la prima opzione di correzione, da applicare nel codice.

- Messaggio di esportazione mostra il nome proposto con altra estensione: correzione del codice, il messaggio usa il nome reale del file salvato quando ha un'estensione qualunque.
- Old-format note: a leading blank line takes the title style: correzione del codice, le righe vuote iniziali restano corpo e il titolo va alla prima riga con testo.
- Loaded lists lose their indent in the block format: correzione del codice, le voci rientrate mantengono rientro e simbolo del loro livello anche nel formato a blocchi.
- Checklist button changes all selected lines, not only the cursor line: correzione del codice, il pulsante agisce solo sulla riga del cursore.
- Checklist toggles when the first letters of an item are tapped: correzione del codice, la spunta cambia solo con un tocco sul cerchio.
