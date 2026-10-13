---
status: resolved
resolution: fix-code
refs:
  - realtime-channel/Listening/supabase.REMOTE_FOLDER_CHANGED
proposal: null
task: ky6raexp
origin: null
critical: false
option: 1
note: null
resolvedBy: fiomlg7l
created: 2026-10-13T05:21:05.027Z
---
# Remote folder change ignored while a local delete is queued

## What happens

Se il cloud invia una cartella mentre il dispositivo ha un'eliminazione di quella cartella in coda, la versione del cloud viene ignorata sempre, anche se il cloud l'ha modificata dopo l'eliminazione. La cartella resta eliminata qui e la sincronizzazione successiva invia l'eliminazione.

## What should happen

Il Model dice che la cartella del cloud sovrascrive sempre quella locale. Nella sincronizzazione completa, invece, un'eliminazione in coda viene scartata se il cloud ha modificato la cartella dopo l'eliminazione, e la cartella torna con il download.

## Fix options

### Confrontare con la data dell'eliminazione in coda

La cartella del cloud sovrascrive quella locale e toglie l'eliminazione in coda solo se il cloud l'ha modificata dopo l'eliminazione; altrimenti l'eliminazione resta e viene inviata. È la stessa regola della sincronizzazione completa, quindi il Model del canale va cambiato da sempre a questa regola. Costo: il canale deve leggere la data della coda.

### Cartella del cloud sempre vincente

La cartella del cloud sovrascrive sempre quella locale e l'eliminazione in coda viene tolta, come scrive il Model del canale. Nessuna eliminazione fatta sul dispositivo resiste a un cambio arrivato dal cloud. Costo: il codice va cambiato per togliere l'eliminazione in coda, e la regola della sincronizzazione completa va riallineata.

## Where in the code

lib/core/services/sync_service.dart: handleRemoteFolderChange (controllo dell'eliminazione in coda)
