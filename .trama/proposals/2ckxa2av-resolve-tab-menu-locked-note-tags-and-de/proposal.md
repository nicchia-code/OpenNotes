---
status: approved
kind: resolution
drifts:
  - drift: d8vm6j1d
    decision: fix-code
    option: 1
  - drift: y2i2cnqg
    decision: fix-code
    option: 1
  - drift: xrbkrzw2
    decision: proposal
base:
  organization/folder.md: 8f4bd0419b38c286f58797e64b21c0a6ea76476ed93c132e680430f025a54a70
  cloud-sync/realtime-channel.md: 6d86f10028dd2a71ed527fc51695f7f7d31f3cb324f6648733e83e6060e215a8
  cloud-sync/pending-change.md: b30ed3a6e87932e1a99074fc42f2221fbc5135d91cd392bd8f51a59b48f6b664
delete: []
created: 2026-10-18T20:01:54.198Z
---
# Resolve Tab menu, locked-note tags and deleted-folder drifts

Risoluzione di tre Drift secondo le risposte dello sviluppatore.

- d8vm6j1d Tab that changes no text still refreshes the menus: correggere il codice; Tab e Maiuscole+Tab cambiano il menu rapido e i suggerimenti di tag solo quando cambiano il testo della sezione.
- y2i2cnqg Hashtags in hidden protected notes appear in the tag list: correggere il codice; finché una nota protetta non è sbloccata nella sessione, nell'elenco dei tag e nei conteggi contano solo i suoi tag memorizzati, come nella ricerca.
- xrbkrzw2 Deleted folder comes back on a newer remote change (recurring, realtime path again): il Model descrive il comportamento attuale, già previsto dai Requirements; una modifica del cloud non più vecchia dell'eliminazione in coda, ricevuta in tempo reale, scarta l'eliminazione e riporta subito la cartella.
