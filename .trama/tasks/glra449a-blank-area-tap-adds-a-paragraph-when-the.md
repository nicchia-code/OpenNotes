---
column: done
technical: false
refs:
  - note-editor
drift: null
proposal: null
agent: false
created: 2026-10-18T17:35:22.321Z
finished: 2026-10-18T17:39:55.710Z
---
# Blank-area tap adds a paragraph when the last part is another empty text section

Toccando l'area vuota sotto il documento, l'editor controlla che l'ultima parte sia un paragrafo vuoto; se l'ultima parte è un'altra sezione di testo vuota (titolo, intestazione, checklist, elenco, citazione), aggiunge invece una nuova sezione di paragrafo. Secondo il Model (TAP_EMPTY_EDITOR_AREA) e il Requirement, la sezione va aggiunta solo se l'ultima parte non è una sezione di testo vuota; altrimenti si dà solo il focus a quella parte.
