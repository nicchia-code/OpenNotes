---
column: done
technical: false
refs:
  - note
  - requirements/rules#note
drift: null
proposal: 634nfp49
agent: false
created: 2026-10-17T10:33:15.023Z
finished: 2026-10-17T11:41:52.104Z
---
# Note sync transitions

La nota segue le transizioni di sincronizzazione aggiornate della macchina `note`.

- Note di benvenuto create all'avvio guardando solo il dispositivo, senza attendere la sincronizzazione; scartate dal giro se il cloud ha note non eliminate.
- Una versione del cloud sostituisce quella locale solo se è nuova per il dispositivo e non c'è una modifica in attesa della nota strettamente più recente.
- CLOUD_NOTE_REMOVED (giro) e CLOUD_NOTE_REMOVED (tempo reale) rimuovono la nota con il suo file nel vault senza accodare nulla.
- L'eliminazione locale di una cartella sposta le note in "Note" senza cambiare la data di modifica ma accodandole; l'eliminazione ricevuta dal cloud (tempo reale o giro) le sposta senza accodarle.
- SAVED aggiorna l'elemento già in coda invece di aggiungerne uno.

Fatto quando i casi sopra si verificano in un test con un cloud simulato.
