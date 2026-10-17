---
column: done
technical: false
refs:
  - note/In trash/realtime-channel.CLOUD_NOTE_REMOVED
drift: null
proposal: null
agent: false
created: 2026-10-17T12:44:04.092Z
finished: 2026-10-17T13:47:39.563Z
---
# Fix code to match the Model: Trashed note deleted in the cloud is removed from the device

Una nota nel cestino, già sincronizzata, che il cloud ha eliminato dopo la sua ultima modifica locale viene rimossa dal dispositivo insieme al suo file nell'archivio Markdown, senza accodare nulla, come una nota fuori dal cestino. Le sue modifiche in attesa vengono tolte dalla coda subito, senza essere inviate, quando l'eliminazione arriva dal canale in tempo reale; vale lo stesso per il download e per il controllo completo quando il cloud non la ha più. Oggi il codice conserva la nota nel cestino e lascia in coda le sue modifiche fino al giro successivo, dove vengono scartate senza rimuovere la nota.

Fatto quando una nota nel cestino eliminata nel cloud sparisce dal dispositivo insieme al suo file, e una sua modifica in coda non viene inviata né la ricrea nel cloud.
