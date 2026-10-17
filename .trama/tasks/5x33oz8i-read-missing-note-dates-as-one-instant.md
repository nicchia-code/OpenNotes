---
column: done
technical: true
refs:
  - requirements/data#note
drift: null
proposal: null
agent: false
created: 2026-10-17T19:25:28.334Z
finished: 2026-10-17T19:48:18.505Z
---
# Read missing note dates as one instant

Quando la lettura di una nota, dal database o dal cloud, trova la data di creazione o quella di modifica mancante o illeggibile, entrambe prendono l'istante della lettura. Oggi ciascuna delle due viene presa da un momento diverso, quindi possono differire: usare un solo istante per entrambe.
