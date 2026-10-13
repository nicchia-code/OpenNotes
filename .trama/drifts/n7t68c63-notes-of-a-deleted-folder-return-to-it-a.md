---
status: resolved
resolution: fix-code
refs:
  - folder/User folder/user.DELETE_FOLDER
proposal: null
task: ry8lis4b
origin: null
critical: false
option: 1
note: null
resolvedBy: m16unv7j
created: 2026-10-12T11:23:01.704Z
---
# Notes of a deleted folder return to it at the next sync

## What happens

Quando una cartella viene eliminata, le sue note passano nella cartella «Note» sul dispositivo, senza cambiare la data di modifica e senza essere inviate al cloud. Alla sincronizzazione successiva, però, il download scarica ogni nota del cloud che ha ancora la cartella eliminata: la copia del cloud ha una data più recente di quella locale e la sostituisce. La nota torna così nella cartella che non esiste più: non compare più in «Note» né nel conteggio di alcuna cartella, resta visibile solo in «Tutte le note». Lo stesso accade su un altro dispositivo quando la cartella viene eliminata altrove.

## What should happen

Il Model dice che le note passano in «Note» senza cambiare la data e senza essere messe in coda per il cloud, ma non dice cosa succede al cloud né cosa fa la sincronizzazione quando una nota del cloud rimanda a una cartella che sul dispositivo non esiste. Il Requirement dice che una nota non ha vincolo verso la cartella e che il download non elimina dati: la nota non può quindi perdere la sua collocazione visibile. La scelta su come riallineare il cloud o il download va fatta da chi sviluppa.

## Fix options

### Il cloud segue l'eliminazione

Prima di eliminare la cartella sul cloud, la sincronizzazione sposta nel cloud le sue note nella cartella «Note», anche quelle nel cestino. Il download non le riporta più indietro e gli altri dispositivi le vedono in «Note». Costo: il Model della sincronizzazione e della cartella va riscritto, perché il cloud riceve un cambiamento che oggi non viene inviato; le note cambiano data sul cloud.

### Le note senza cartella vanno in Note

Il download colloca in «Note» ogni nota la cui cartella non esiste sul dispositivo, senza toccare il cloud. Costo: il cloud continua a indicare la cartella eliminata finché la nota non viene modificata; la regola va scritta nel Model della sincronizzazione e nel Requirement.

### Accodare anche le note spostate

Le note spostate dall'eliminazione entrano nella coda come le altre modifiche. Costo: va contro la regola del Model che le esclude dalla coda; senza cambiare la data l'invio verrebbe scartato dal confronto con il cloud, quindi servono una nuova data e un Model riscritto.

## Where in the code

lib/core/services/sync_service.dart (syncNow, applyRemoteNote); lib/core/services/database_service.dart (deleteFolder); lib/core/state/notes_provider.dart (deleteFolder)
