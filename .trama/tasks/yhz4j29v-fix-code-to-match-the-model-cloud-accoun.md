---
column: done
technical: false
refs:
  - vault-file/Written/note.PERMANENTLY_DELETED
  - realtime-channel.CLOUD_NOTE_REMOVED
  - sync-run.PREVIOUS_ACCOUNT_NOTE_REMOVED
  - sync-run.SAMPLE_NOTE_DISCARDED
drift: null
proposal: null
agent: false
created: 2026-10-12T11:50:35.164Z
finished: 2026-10-12T13:57:15.453Z
---
# Fix code to match the Model: Cloud, account-switch and welcome-note removals delete a vault file another note still uses

Quando una nota viene eliminata definitivamente per una cancellazione arrivata dal cloud, per il cambio di account o perché una nota di benvenuto mai sincronizzata viene scartata, il file Markdown della nota viene rimosso solo se nessun'altra nota risulta scritta nello stesso file, esattamente come per l'eliminazione dell'utente e lo svuotamento del cestino. Oggi questi tre percorsi cancellano il file in ogni caso, anche quando contiene la copia di un'altra nota ancora presente, che così perde la sua copia nel vault.
