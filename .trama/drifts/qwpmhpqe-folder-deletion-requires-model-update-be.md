---
status: resolved
resolution: fix-code
refs:
  - folder/User folder/user.DELETE_FOLDER
proposal: null
task: e6ntdqna
origin: pb2g9hf1
critical: false
option: 1
note: "Il codice elimina già la cartella nel cloud. In più: un'eliminazione di cartella in coda viene scartata se la cartella del cloud è stata modificata dopo il momento dell'eliminazione; nella sincronizzazione completa le cartelle si scaricano prima delle note."
resolvedBy: ccg944lf
created: 2026-10-12T11:59:16.920Z
---
# Folder deletion requires Model update before code change

## What happens

Oggi il dispositivo mette in coda per il cloud ogni modifica alle cartelle, eliminazione compresa. Se si correggesse il codice per allinearlo al Model, cioè non mettendo in coda l'eliminazione, la cartella eliminata tornerebbe dopo ogni sincronizzazione, perché il cloud la conserva. La correzione scelta nel Drift 9oa1tgu6 (eliminare la cartella anche nel cloud) contraddice però il Model, che dice che le modifiche alle cartelle non entrano mai in coda e che l'eliminazione non viene messa in coda. La Proposta di risoluzione va7uprsh è approvata ma non tocca alcun file: il Model non descrive la nuova regola.

## What should happen

Il Model deve dire esplicitamente che l'eliminazione di una cartella arriva al cloud, come eccezione alla regola che le cartelle non entrano mai in coda. Senza questa modifica, il Task chiede di implementare un comportamento che il Model vieta, e non posso farlo: il Model e i Requirement hanno la precedenza sul codice. Il Model non è stato aggiornato dalla risoluzione, quindi il Task è bloccato finché il Model non cambia o la scelta non cambia.

## Fix options

### Aggiornare prima il Model, poi il codice

Il Model descrive l'eliminazione di una cartella che arriva al cloud come eccezione alla regola che le cartelle non entrano mai in coda; poi si implementa la correzione scelta. La cartella eliminata non ricompare su nessun dispositivo e le note restano in Note qui e nel cloud. Serve una Proposta di modifica del Model da approvare. Costa un cambio di comportamento del cloud e del Model.

### Tornare alla regola del Model

Il dispositivo smette di mettere in coda le modifiche alle cartelle, come scrive il Model. Alla sincronizzazione però il cloud riporta la cartella eliminata e la ricrea, e le note tornano nella cartella originale: è proprio il problema da correggere. Non è utilizzabile senza un'altra modifica del Model o del comportamento.

### Ricordare localmente le cartelle eliminate

Il dispositivo ricorda le cartelle eliminate localmente e le ignora quando il cloud le riporta, senza mandare nulla al cloud. La cartella non ricompare qui e le note restano in Note. Il cloud però continua a contenere la cartella e gli altri dispositivi la vedono ancora. Il Model deve descrivere questo ricordo locale e la sua durata, e costa una memoria locale in più.

## Where in the code

lib/core/state/notes_provider.dart (deleteFolder, notifyFolderChanged); lib/core/services/sync_service.dart (notifyFolderChanged, syncNow step 5)
