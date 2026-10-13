---
status: resolved
resolution: fix-code
refs:
  - requirements/data#vault-file
proposal: null
task: erupbysz
origin: null
critical: false
option: 1
note: null
resolvedBy: 37m9hzhb
created: 2026-10-13T05:42:12.000Z
---
# Attachment references with an absolute path are synced as vault paths

## What happens

La sincronizzazione cerca in ogni nota ogni riferimento che contiene una cartella di allegati e lo tratta come un file del vault, anche quando la nota lo indica con un percorso assoluto. Così un allegato con percorso assoluto viene cercato dentro il vault: se manca lì, il dispositivo lo scarica dal cloud e lo scrive nel vault, anche se la nota lo indicava altrove.

## What should happen

Il Requirement dei dati per il vault dice che un riferimento che non inizia con la cartella degli allegati è un percorso assoluto, cioè non si risolve rispetto al vault. Il sincronizzatore non deve quindi scrivere nel vault nulla per quel riferimento.

## Fix options

### Sincronizzare solo i riferimenti interni al vault

Il sincronizzatore considera solo i riferimenti che iniziano con la cartella degli allegati del vault. Un riferimento con percorso assoluto non viene né caricato né scaricato su nessun dispositivo, e la nota mostra l'immagine solo dove il file esiste già. Costa: quel file non arriva mai agli altri dispositivi; il cambiamento è piccolo e coerente con il Requirement.

### Caricare i riferimenti assoluti, mai scaricarli

Il dispositivo che ha il file al percorso assoluto continua a caricarlo, ma un dispositivo che non lo ha non scrive nulla nel vault per quel riferimento. Costa: l'immagine compare su alcuni dispositivi e su altri no, e la regola di caricamento resta distinta da quella di scaricamento, quindi va spiegata nel codice.

## Where in the code

lib/core/services/sync_service.dart: attachmentRefs, _uploadAttachments, _downloadAttachments, _removeUnusedAttachments
