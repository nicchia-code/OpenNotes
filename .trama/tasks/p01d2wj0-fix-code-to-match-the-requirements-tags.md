---
column: done
technical: false
refs:
  - note/Active
  - requirements/rules#note
drift: null
proposal: null
agent: false
created: 2026-10-12T15:08:38.242Z
finished: 2026-10-12T16:38:47.094Z
---
# Fix code to match the Requirements: Tags of a plain-text note that looks like a JSON list are not read

Quando una nota di testo semplice comincia con «[» ed è un elenco JSON valido ma non di soli oggetti (per esempio «["progetto #lavoro"]»), i tag del testo non vengono letti: la nota non riceve tag, mentre ogni altra nota di testo semplice li riceve. Il Requirement dice che un contenuto che non è un documento a blocchi è testo Markdown, quindi i tag vanno cercati nel testo. Quando il lavoro è finito, una nota di testo semplice ottiene i tag presenti nel suo testo anche se la prima riga sembra un elenco JSON, come le altre note di testo (vedi anche Task tdzgvg5p per il titolo della stessa classe di note).
