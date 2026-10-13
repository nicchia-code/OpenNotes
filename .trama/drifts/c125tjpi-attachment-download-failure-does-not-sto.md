---
status: resolved
resolution: proposal
refs:
  - sync-run/Pulling
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: xiy2hxml
created: 2026-10-12T14:34:53.295Z
---
# Attachment download failure does not stop the sync run

## What happens

Se la foto o il disegno di una nota non si può scaricare dal cloud, la sincronizzazione prosegue: la nota arriva con il suo testo, senza l'immagine, e le altre note vengono scaricate normalmente. Nessun avviso all'utente; il download dell'immagine viene ritentato alla sincronizzazione successiva.

## What should happen

Il Model dice che al primo errore in qualsiasi passo la sincronizzazione si interrompe e termina come fallita, senza aggiornare l'ora dell'ultima sincronizzazione. Non distingue gli allegati: per il Model, un'immagine irraggiungibile è un errore come un altro. Caricare un allegato, invece, interrompe già la sincronizzazione.

## Fix options

### Keep the sync going and describe attachments in the Model

Il download di un'immagine mancante non conta come errore di sincronizzazione: la nota arriva senza immagine, il giro prosegue e l'immagine viene ritentata al giro successivo. Il Model viene ampliato per dire questo, così il comportamento compare nel Diagramma. Costo: per un po' una nota può comparire senza la sua immagine, senza avviso all'utente, e il Model cresce di una regola sugli allegati.

### Stop the sync run at a missing image

Un'immagine che non si scarica interrompe la sincronizzazione come ogni altro errore: la nota non viene applicata, le note successive attendono e l'ora dell'ultima sincronizzazione non cambia. Il giro riparte alla richiesta successiva. Costo: una sola immagine irraggiungibile blocca l'arrivo di tutte le altre note del cloud, finché il download non riesce.

## Where in the code

lib/core/services/sync_service.dart: il download degli allegati intercetta l'errore e lo registra soltanto
