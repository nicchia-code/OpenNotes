---
column: done
technical: false
refs:
  - folder/User folder/user.DELETE_FOLDER
drift: ai11jwv3
proposal: null
agent: false
created: 2026-10-12T11:44:40.861Z
finished: 2026-10-12T11:46:07.935Z
---
# Fix code to match the Model: Notes of a deleted folder return to it at the next sync

## What happens

Quando una cartella viene eliminata, le sue note passano in «Note» senza cambiare data e senza essere inviate al cloud. Alla sincronizzazione successiva il download sostituisce la copia locale con quella del cloud, che è più recente e punta ancora alla cartella eliminata: la nota torna in una cartella inesistente e sparisce da «Note» e da ogni conteggio, restando visibile solo in «Tutte le note». Accade anche sugli altri dispositivi.

## What should happen

Il Model dice che le note passano in «Note» senza cambiare data e senza essere messe in coda per il cloud, ma non dice cosa fa la sincronizzazione quando una nota del cloud rimanda a una cartella che sul dispositivo non esiste. Il Requirement dice che una nota non ha vincolo verso la cartella e che il download non elimina dati. Seguire il Model impedisce di riallineare il cloud, perché l'eliminazione non va in coda; quindi la collocazione va difesa in fase di download, ma quale regola usare è una scelta che il Model non fa.

## Chosen option

**Il download conserva la cartella «Note» locale**

Quando la cartella della nota remota non esiste sul dispositivo, la nota resta in «Note» e il download aggiorna solo il resto. Non cambia il Model né il cloud. Costo: il cloud continua a riferire la cartella eliminata e gli altri dispositivi la vedranno nella stessa posizione solo dopo il loro download.

## Where in the code

lib/core/services/sync_service.dart (syncNow, applyRemoteNote); lib/core/services/database_service.dart (deleteFolder); lib/core/state/notes_provider.dart (deleteFolder)
