---
column: done
technical: false
refs:
  - realtime-channel/Listening/supabase.REMOTE_FOLDER_CHANGED
drift: lwta0evn
proposal: null
agent: false
created: 2026-10-13T05:23:24.917Z
finished: 2026-10-13T05:25:01.395Z
---
# Fix code to match the Model: Remote folder change ignored while a local delete is queued

## What happens

Se il cloud invia una cartella mentre il dispositivo ha un'eliminazione di quella cartella in coda, la versione del cloud viene ignorata sempre, anche se il cloud l'ha modificata dopo l'eliminazione. La cartella resta eliminata qui e la sincronizzazione successiva invia l'eliminazione.

## What should happen

Il Model dice che la cartella del cloud sovrascrive sempre quella locale. Nella sincronizzazione completa, invece, un'eliminazione in coda viene scartata se il cloud ha modificato la cartella dopo l'eliminazione, e la cartella torna con il download.

## Chosen option

**Confrontare con la data dell'eliminazione in coda**

La cartella del cloud sovrascrive quella locale e toglie l'eliminazione in coda solo se il cloud l'ha modificata dopo l'eliminazione; altrimenti l'eliminazione resta e viene inviata. È la stessa regola della sincronizzazione completa, quindi il Model del canale va cambiato da sempre a questa regola. Costo: il canale deve leggere la data della coda.

## Where in the code

lib/core/services/sync_service.dart: handleRemoteFolderChange (controllo dell'eliminazione in coda)
