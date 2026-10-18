---
column: done
technical: false
refs:
  - note-editor
drift: null
proposal: null
agent: false
created: 2026-10-18T17:35:16.728Z
finished: 2026-10-18T17:39:03.436Z
---
# Table insert adds an empty section even when the next part is text

Inserendo una tabella (comando Tabella della barra o voce del menu blocchi), l'editor aggiunge sempre una sezione di testo vuota dopo la tabella, anche quando la parte successiva è già una sezione di testo che non è un paragrafo (titolo, intestazione, checklist, elenco, citazione, codice). Secondo il Model (INSERT_TABLE) e il Requirement di inserimento, la sezione vuota va aggiunta solo se la parte successiva non è testo: il controllo deve riconoscere ogni sezione di testo, non solo il paragrafo.
