---
column: done
technical: false
refs:
  - note-editor
  - requirements/rules#note-editor
drift: null
proposal: null
agent: false
created: 2026-10-17T18:18:04.145Z
finished: 2026-10-17T18:23:11.950Z
---
# Fix code to match the Requirements: Indented dash lines in block-format content do not become bullets

Quando un contenuto a blocchi viene caricato, ogni riga di testo che comincia con «- » o «* » deve diventare una voce puntata «• », come dice il Requirement del caricamento di un contenuto JSON, anche quando la riga è rientrata. Oggi una riga rientrata prende il simbolo del suo livello («◦ » o «▪ »), che è la regola del Markdown e del testo semplice e non quella del contenuto a blocchi.
