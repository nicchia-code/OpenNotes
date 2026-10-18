---
column: done
technical: false
refs:
  - folder/Deleted
  - requirements/rules#sync-run
drift: null
proposal: null
agent: false
created: 2026-10-18T19:48:49.141Z
finished: 2026-10-18T20:08:24.762Z
---
# Fix code to match the Model: Folder the cloud no longer has drops its newer queued changes

Quando il cloud non ha più una cartella che il dispositivo aveva inviato, la cartella esce dal dispositivo e ogni sua modifica ancora in coda viene scartata, anche quella fatta dopo la modifica che si stava inviando. Oggi il ramo di rifiuto dell'invio rimuove solo la modifica inviata e la cartella; una modifica più recente resta in coda e alla sincronizzazione successiva ricrea la cartella nel cloud. Il Model (sync-run, CLOUD_FOLDER_REMOVED, ramo dell'invio) e il Requirement (rules#sync-run) dicono invece che il salvataggio viene sempre scartato, anche se più recente. Decisione già presa nella Drift vhczaywa (Proposal famz2y49). Acceptance: dopo un invio a cui il cloud risponde senza riga per la cartella, nessuna modifica della cartella resta in coda e la cartella non ricompare alla sincronizzazione successiva.
