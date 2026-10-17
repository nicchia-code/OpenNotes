---
column: done
technical: false
refs:
  - folder
  - requirements/rules#folder
drift: null
proposal: 634nfp49
agent: false
created: 2026-10-17T10:33:15.023Z
finished: 2026-10-17T10:41:44.912Z
---
# Folder sync rules

Le cartelle seguono le stesse regole delle note.

- Una versione del cloud (tempo reale o giro) sostituisce la cartella locale salvo che ci sia una modifica in attesa della stessa cartella strettamente più recente.
- Un'eliminazione fatta altrove (tempo reale o segnaposto scaricato) elimina la cartella locale salvo una modifica in attesa più recente; il controllo completo elimina anche le cartelle già sincronizzate che il cloud non ha più; le note passano in "Note" senza essere accodate.
- L'eliminazione locale accoda la cartella e le note spostate.

Fatto quando una rinomina locale più recente non viene sovrascritta dal download e una cartella eliminata su un altro dispositivo sparisce anche qui.
