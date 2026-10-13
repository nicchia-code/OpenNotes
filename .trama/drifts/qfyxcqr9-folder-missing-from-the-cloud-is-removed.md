---
status: resolved
resolution: fix-code
refs:
  - folder/User folder
  - sync-run/Pulling
proposal: null
task: ee2tvgdr
origin: null
critical: false
option: 1
note: null
resolvedBy: 32w3ze0y
created: 2026-10-12T18:16:11.501Z
---
# Folder missing from the cloud is removed by a full sync, the Model says local folders are not touched

## What happens

Durante una sincronizzazione completa, se il cloud non ha più una cartella che il dispositivo ha e questa non ha modifiche in coda, il dispositivo la elimina. Le sue note passano nella cartella "Note" senza essere inviate. Succede anche a una cartella eliminata nel cloud mentre il dispositivo era offline, cioè senza la notifica in tempo reale.

## What should happen

Il Model della cartella non ha nessuna transizione che porti la cartella a Eliminata con una sincronizzazione: la cartella passa a Eliminata solo con l'eliminazione fatta dall'utente o con la notifica in tempo reale. Il Model della sincronizzazione dice che, nel download, le note e le cartelle presenti solo sul dispositivo non vengono toccate.

## Fix options

### Keep the removal and describe it in the Model

La sincronizzazione completa rimuove dal dispositivo le cartelle che il cloud non ha più, come già fa la notifica in tempo reale, e le loro note passano nella cartella "Note". Il Model della cartella e della sincronizzazione va aggiornato con questa transizione. Costo: una cartella eliminata altrove viene tolta anche dopo lunghe assenze dalla rete, senza che l'utente la veda prima.

### Stop the removal in the full sync

Le cartelle eliminate nel cloud restano sul dispositivo finché non arriva la notifica in tempo reale o l'utente non le elimina. Il Model resta com'è. Costo: dispositivi offline possono mostrare cartelle che il cloud non ha più, e le note restano in quelle cartelle fino a un evento in tempo reale.

## Where in the code

lib/core/services/sync_service.dart, syncNow, step 4b: removal of local folders the cloud no longer has (the closed Task c2noyss4 asked for this removal).
