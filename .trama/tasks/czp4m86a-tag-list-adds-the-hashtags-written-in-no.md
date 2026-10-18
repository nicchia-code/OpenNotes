---
column: done
technical: false
refs:
  - note-browser
drift: null
proposal: null
agent: false
created: 2026-10-18T18:29:05.306Z
finished: 2026-10-18T19:37:59.824Z
---
# Tag list adds the hashtags written in note content

L'elenco dei tag deve unire, per ogni nota non nel cestino, i tag memorizzati (normalizzati) e i #tag presenti nel contenuto, come richiede il Requirement. Oggi getAllTags in database_service.dart usa solo i tag memorizzati. Il filtro per tag resta sui soli tag memorizzati, come richiesto.
