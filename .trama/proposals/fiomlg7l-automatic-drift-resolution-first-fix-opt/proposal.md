---
status: approved
kind: resolution
automatic: true
drifts:
  - drift: ab2v1y1w
    decision: fix-code
    option: 1
  - drift: lwta0evn
    decision: fix-code
    option: 1
  - drift: rzj1mn5k
    decision: fix-code
    option: 1
  - drift: myy7r511
    decision: fix-code
    option: 1
  - drift: aaw1w6zf
    decision: fix-code
    option: 1
  - drift: jxiu29pk
    decision: fix-code
    option: 1
  - drift: 3lqov4js
    decision: fix-code
    option: 1
  - drift: avr8hn7y
    decision: fix-code
    option: 1
  - drift: 8p8efttk
    decision: fix-code
    option: 1
base: {}
delete: []
created: 2026-10-13T05:23:10.562Z
---
# Automatic Drift resolution: first fix options

Risoluzione automatica dei Drift autorizzati, ciascuno con la prima opzione di correzione del codice:
- D2 Share sheet failure is not in the Model: fix-code, Mostrare un messaggio e tornare a Idle
- D4 Remote folder change ignored while a local delete is queued: fix-code, Confrontare con la data dell'eliminazione in coda
- D5 Remote note change ignored while a local delete is queued: fix-code, Confrontare con la data dell'eliminazione in coda
- D6 Renewed session does not reopen the realtime channel: fix-code, Riaprire il canale a ogni rinnovo
- D7 Inline bold, italic and strikethrough split by other styles: fix-code, Unire i tratti con lo stesso stile
- D8 Failed sign-in return through the app link leaves the app waiting for login: fix-code, Tornare allo stato senza accesso con il messaggio
- D9 Settings window keeps the success message when the sign-in return fails: fix-code, Mostrare l'esito reale del ritorno
- D12 Mobile editor closes when its note leaves the list, the Model keeps it open: fix-code, Tenere l'editor aperto come dice il Model
- D13 Desktop: tapping a tag suggestion closes the menu without inserting the tag: fix-code, Keep the tag menu inside the text-field tap area
