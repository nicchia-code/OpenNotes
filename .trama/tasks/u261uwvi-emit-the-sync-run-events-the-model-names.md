---
column: done
technical: false
refs:
  - sync-run
drift: null
proposal: null
agent: false
created: 2026-10-18T17:44:19.456Z
finished: 2026-10-18T19:39:34.908Z
---
# Emit the sync-run events the Model names

Il Model di sync-run nomina gli eventi CLOUD_FOLDER_REMOVED (cartella eliminata dal cloud, ricevuta da note/Unpinned, note/Pinned, note/In trash, folder/User folder), SAMPLE_NOTE_DISCARDED (nota di benvenuto eliminata perché il cloud ha note, ricevuta da note/Active e note/In trash), PREVIOUS_ACCOUNT_NOTE_REMOVED (nota eliminata al cambio di account, ricevuta da pending-change/Pending, note/Active, note/In trash). Il codice emette invece CloudFolderChanged per ogni cambio di cartella (lib/core/services/sync_service.dart, _removeRemoteFolder, handleRemoteFolderChange, _applyCloudFolders, _sendUnsyncedNote) e CloudNoteRemoved per la nota di benvenuto e il cambio di account (_sendUnsyncedNote, _adoptAccount). Allineare gli eventi emessi ai nomi del Model. Correggere anche il commento a riga 34 di sync_service.dart («the Model names no folder event»), che non è più vero.
