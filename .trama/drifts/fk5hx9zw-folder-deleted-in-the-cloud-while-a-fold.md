---
status: resolved
resolution: fix-code
refs:
  - realtime-channel/Listening/supabase.REMOTE_FOLDER_DELETED
proposal: null
task: la7n12ft
origin: null
critical: false
option: 1
note: null
resolvedBy: g08cr3wn
created: 2026-10-12T14:49:53.161Z
---
# Folder deleted in the cloud while a folder change is queued on the device

## What happens

Una cartella eliminata nel cloud, mentre sul dispositivo è in coda una sua creazione o rinomina, viene eliminata qui e le sue note passano in «Note». La modifica in coda però resta. Alla sincronizzazione successiva viene inviata e ricrea la cartella nel cloud; il download la riporta sul dispositivo e le note tornano dentro, come se l'eliminazione non ci fosse stata.

## What should happen

Il Model del canale dice che la cartella locale viene eliminata e le note spostate in «Note», ma non dice cosa accade alle modifiche in coda della cartella. Il Model della cartella dice che «Deleted» è definitivo e che una cartella torna solo con il download, e solo se il cloud l'ha cambiata dopo l'eliminazione. Il Model della sincronizzazione dice invece che creazione e rinomina in coda sovrascrivono il cloud senza confronto di date. Per le note esiste la regola «nota eliminata altrove», che scarta il salvataggio in coda; per le cartelle non c'è una regola equivalente, quindi il risultato dipende dall'ordine degli eventi.

## Fix options

### Drop the queued folder change

Quando il cloud non ha più la cartella, la creazione o rinomina in coda viene scartata, come per le note eliminate altrove. La cartella resta eliminata su tutti i dispositivi e le sue note restano in «Note». Il Model della sincronizzazione va completato con questa regola per le cartelle.

### Send the queued change anyway

La modifica in coda viene inviata come descrive oggi il Model della sincronizzazione: la cartella torna nel cloud e sul dispositivo, con le sue note. L'eliminazione fatta su un altro dispositivo viene annullata senza che l'utente lo sappia. Il Model del canale va completato con questo esito.

## Where in the code

lib/core/services/sync_service.dart: handleRemoteFolderChange (ramo di eliminazione) e syncNow (coda, ramo folder upsert)
