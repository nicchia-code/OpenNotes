---
column: done
technical: false
refs:
  - note-content-save/Waiting
  - requirements/rules#note-content-save
drift: null
proposal: null
agent: false
created: 2026-10-17T18:13:15.614Z
finished: 2026-10-17T18:18:19.615Z
---
# Fix code to match the Requirements: Failed-save warning stays after the save succeeds

Quando una scrittura della nota riesce dopo un fallimento, l'avviso «Nota non salvata: il salvataggio verrà ritentato.» deve sparire subito, come dice il Requirement del salvataggio: oggi resta visibile fino alla sua scadenza automatica. Il comportamento degli altri casi resta com'è: l'avviso compare una sola volta per ogni fallimento, la versione non scritta viene ritentata e nessun altro messaggio viene toccato.
