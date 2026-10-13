---
status: resolved
resolution: fix-code
refs:
  - requirements/data#cloud-sync
proposal: null
task: e0u6k5ws
origin: null
critical: false
option: 1
note: null
resolvedBy: p136jufl
created: 2026-10-12T08:00:55.180Z
---
# Images and drawings never reach the cloud

## What happens

Le foto e i disegni inseriti nelle note restano solo sul dispositivo, nella cartella degli allegati del vault. Il loro testo arriva sugli altri dispositivi tramite la nota, ma le immagini e i disegni non ci sono: la nota compare con spazi vuoti al loro posto.

## What should happen

I requisiti descrivono nel cloud un archivio pensato per immagini e disegni, con una cartella per ogni utente, e le regole permettono di caricarvi i file. Il modello però descrive il cloud solo come note e cartelle, e non dice se gli allegati debbano seguire la nota.

## Fix options

### Caricare anche gli allegati

Foto e disegni vengono caricati nell'archivio del cloud, nella cartella dell'utente, e scaricati insieme alla nota sugli altri dispositivi. Le immagini compaiono ovunque, ma servono caricamento, download, pulizia quando una nota viene eliminata e più spazio nel cloud. Il modello va ampliato per dirlo.

### Tenere gli allegati sul dispositivo

Foto e disegni restano locali e l'archivio del cloud viene tolto dai requisiti. È la soluzione più semplice, ma sugli altri dispositivi le note hanno testo senza immagini, e il modello e i requisiti devono dirlo esplicitamente.

## Where in the code

lib/core/services/vault_service.dart (saveAttachment); lib/core/services/sync_service.dart (nessun caricamento verso il bucket note-attachments)
