---
column: done
technical: false
refs:
  - note-browser
drift: null
proposal: null
agent: false
created: 2026-10-17T11:34:23.113Z
finished: 2026-10-17T11:36:17.513Z
---
# Fix code to match the Requirements: tag list is not sorted alphabetically with accented letters

Il Requirement dell'elenco dei tag dice di ordinarlo per nome. Il Drift mhdhstxk, con il Task fcmksgts, ha stabilito che i tag si ordinano alfabeticamente con le lettere accentate trattate come lettere base, ma quell'ordine è stato applicato solo ai tag estratti dal contenuto e ai tag salvati. L'elenco mostrato nella barra laterale e nelle schermate mobili arriva da getAllTags in lib/core/services/database_service.dart, che ordina con a.name.compareTo(b.name): così «città» finisce dopo «zen». Da fare: ordinare l'elenco di getAllTags con Note.compareTags, come già fanno i tag delle note, senza cambiare conteggi, duplicati o minuscole.
