---
column: done
technical: false
refs:
  - note-content-save
drift: null
proposal: null
agent: false
created: 2026-10-17T07:36:02.321Z
finished: 2026-10-17T07:50:12.979Z
---
# Fix code to match the Requirements: tags are not sorted alphabetically with accented letters

Il Requirement dice che i tag del testo si salvano in ordine alfabetico. Il codice ordina ancora i tag con il confronto dei caratteri Unicode, quindi le lettere accentate finiscono dopo la z invece di stare tra le lettere base. La correzione era stata decisa con il Drift mhdhstxk (opzione: ordinare con un confronto alfabetico sensibile agli accenti, approvata nel Proposal 2di39ebu), ma nel codice non c'è ancora. Da fare: ordinare i tag estratti dal contenuto con un confronto alfabetico sensibile agli accenti, senza cambiare duplicati e minuscole. Le note già salvate si riordinano alla prossima consegna. Applicare la stessa regola al getter che normalizza i tag salvati.
