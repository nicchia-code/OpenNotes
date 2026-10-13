---
column: done
technical: false
refs:
  - pending-change
  - requirements/data#pending-change
drift: null
proposal: null
agent: false
created: 2026-10-13T10:44:07.032Z
finished: 2026-10-13T10:54:58.051Z
---
# Fix code to match the Requirements: Queued note saves carry the local sync mark

Il Requirement dice che il payload di un salvataggio di nota in coda è la nota nel formato del cloud. Il codice vi aggiunge anche il segno locale di sincronizzazione, che serve a decidere, quando la nota non esiste più sul dispositivo, se era già stata sincronizzata. Adeguare il codice senza questo campo nel payload: la decisione va presa al momento in cui la nota viene rimossa dal dispositivo (cancellazione dal cloud, eliminazione definitiva, cambio di account), leggendo lo stato di sincronizzazione finché la nota esiste, come descrive il Model (salvataggio di una nota che il cloud non ha più ma che il dispositivo aveva già sincronizzato: scartato; nota mai sincronizzata: inviata). Non cambiano i comportamenti visibili descritti nel Model.
