---
column: done
technical: true
refs:
  - requirements/data#cloud-sync
drift: gb7cn58z
proposal: null
agent: false
created: 2026-10-12T08:09:28.350Z
finished: 2026-10-12T08:17:27.796Z
---
# Fix code to match the Requirements: Images and drawings never reach the cloud

## What happens

Le foto e i disegni inseriti nelle note restano solo sul dispositivo, nella cartella degli allegati del vault. Il loro testo arriva sugli altri dispositivi tramite la nota, ma le immagini e i disegni non ci sono: la nota compare con spazi vuoti al loro posto.

## What should happen

I requisiti descrivono nel cloud un archivio pensato per immagini e disegni, con una cartella per ogni utente, e le regole permettono di caricarvi i file. Il modello però descrive il cloud solo come note e cartelle, e non dice se gli allegati debbano seguire la nota.

## Chosen option

**Caricare anche gli allegati**

Foto e disegni vengono caricati nell'archivio del cloud, nella cartella dell'utente, e scaricati insieme alla nota sugli altri dispositivi. Le immagini compaiono ovunque, ma servono caricamento, download, pulizia quando una nota viene eliminata e più spazio nel cloud. Il modello va ampliato per dirlo.

## Where in the code

lib/core/services/vault_service.dart (saveAttachment); lib/core/services/sync_service.dart (nessun caricamento verso il bucket note-attachments)
