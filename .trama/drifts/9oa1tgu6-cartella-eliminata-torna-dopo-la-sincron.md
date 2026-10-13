---
status: resolved
resolution: fix-code
refs:
  - folder/User folder/user.DELETE_FOLDER
proposal: null
task: pb2g9hf1
origin: 59mfpbei
critical: false
option: 1
note: null
resolvedBy: va7uprsh
created: 2026-10-12T11:54:20.893Z
---
# Cartella eliminata torna dopo la sincronizzazione

## What happens

Il dispositivo mette in coda per il cloud ogni modifica alle cartelle, eliminazione compresa, mentre il Model dice che le modifiche alle cartelle non entrano mai nella coda e che l'eliminazione non viene messa in coda. Le note del cestino e le altre passano in Note senza essere messe in coda, quindi il cloud le conserva nella cartella eliminata. Alla sincronizzazione successiva la cartella eliminata ricompare, perché il cloud la conserva e la sincronizzazione la scarica di nuovo, e le note tornano nella cartella originale. Il Model non dice cosa succede alla cartella nel cloud dopo l'eliminazione locale e non prevede che l'eliminazione resti tale su tutti i dispositivi.

## What should happen

L'eliminazione di una cartella deve restare tale su tutti i dispositivi: la cartella non deve ricomparire dopo la sincronizzazione e le sue note devono restare in Note sia qui sia nel cloud. Il Model deve dire esplicitamente se l'eliminazione di una cartella arriva al cloud e in quale forma, e se questo cambia la regola che le modifiche alle cartelle non entrano mai nella coda. Qualunque scelta va scritta nel Model prima di cambiare il codice.

## Fix options

### Eliminare la cartella anche nel cloud

L'eliminazione di una cartella entra nella coda e viene applicata al cloud alla sincronizzazione, così la cartella non ricompare sugli altri dispositivi. Le note restano in Note qui e nel cloud, senza cambiare la data di modifica, e il cloud può avere ancora il vecchio riferimento alla cartella finché la nota non viene modificata. Il Model va riscritto per fare un'eccezione alla regola che le cartelle non entrano mai nella coda, limitata all'eliminazione. Costa un cambio di comportamento del cloud e del Model.

### Non mettere in coda le cartelle

Le modifiche alle cartelle non entrano mai nella coda, come dice il Model: alla sincronizzazione il cloud riporta la cartella eliminata e la ricrea qui. Le note tornano nella cartella originale. Questa opzione segue alla lettera il Model, ma l'utente vede la cartella tornare dopo ogni sincronizzazione, quindi non è utilizzabile senza una modifica del Model.

### Ignorare le cartelle eliminate dal cloud

Il dispositivo ricorda le cartelle eliminate localmente e le ignora quando il cloud le riporta, senza mandare nulla al cloud. Le note restano in Note qui e la cartella non ricompare, ma il cloud continua a contenere la cartella e gli altri dispositivi la vedono ancora. Il Model dovrebbe descrivere questo ricordo locale e la sua durata. Costa una memoria locale in più.

## Where in the code

lib/core/state/notes_provider.dart (deleteFolder, notifyFolderChanged); lib/core/services/sync_service.dart (notifyFolderChanged, syncNow step 5)
