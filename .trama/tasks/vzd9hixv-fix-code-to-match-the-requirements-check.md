---
column: done
technical: false
refs:
  - note-editor/Open
  - requirements/rules#note-editor
  - requirements/data#note-editor
drift: null
proposal: null
agent: false
created: 2026-10-13T14:27:21.499Z
finished: 2026-10-13T14:44:53.381Z
---
# Fix code to match the Requirements: Checkbox marker without text after it is not loaded as a checklist item

Quando una nota viene caricata, una riga che contiene solo la casella «[ ]» oppure «- [ ]» (anche rientrata, senza testo dopo la casella) deve diventare una voce da fare «○ », come già accade quando la casella è seguita da testo. Oggi la casella resta scritta nel testo perché il riconoscimento richiede uno spazio dopo la parentesi. Lo stesso vale per «[x]» e «- [x]», che diventano «● ». Il caricamento in formato a blocchi e quello in Markdown o testo semplice devono dare lo stesso risultato. Le altre regole di caricamento restano come sono.
