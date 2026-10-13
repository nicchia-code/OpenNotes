---
status: resolved
resolution: fix-code
refs:
  - sync-run/Pushing changes
  - realtime-channel/Listening/supabase.REMOTE_FOLDER_DELETED
  - pending-change/Queued
proposal: null
task: s84pb9wx
origin: null
critical: false
option: 1
note: null
resolvedBy: oasankgu
created: 2026-10-12T17:52:37.114Z
---
# Cartella in coda modificata dopo l'eliminazione nel cloud: la sincronizzazione la ricrea, il tempo reale la scarta

## What happens

Se la cartella viene eliminata nel cloud mentre il dispositivo è offline o il canale in tempo reale non la riceve, una rinomina o una creazione ancora in coda viene inviata: la cartella torna nel cloud e, al download, anche sul dispositivo, con le sue note. Se invece il canale in tempo reale riceve l'eliminazione, la modifica in coda viene scartata e la cartella locale sparisce con le sue note spostate in «Note».

## What should happen

Il Model della sincronizzazione dice che creazione e rinomina in coda vengono sempre inviate e sovrascrivono il cloud senza confronto. Il Model del canale e della cartella non dice cosa succede alla modifica in coda quando la cartella è eliminata nel cloud. La decisione risolta con fk5hx9zw chiedeva di scartarla quando il cloud non ha più la cartella, ma è applicata solo nel ramo in tempo reale. Le cartelle non hanno un segno di sincronizzazione (come synced_at per le note): la sincronizzazione non distingue una cartella mai inviata da una eliminata altrove, quindi lo scarto non può essere applicato lì senza un'aggiunta allo schema locale.

## Fix options

### Inviare sempre la modifica in coda

La sincronizzazione resta com'è: creazione e rinomina sovrascrivono il cloud. Si toglie lo scarto del tempo reale, così una cartella eliminata altrove ricompare se è stata rinominata offline. Nessun cambiamento al Model e al Requirement della sincronizzazione, che già dicono così; il Model del canale va completato. Costo: una cartella eliminata altrove può tornare.

### Scartare la modifica quando il cloud non ha più la cartella, in ogni percorso

Le cartelle ottengono un segno di sincronizzazione locale (come synced_at per le note), così la sincronizzazione distingue una cartella mai inviata da una eliminata altrove e scarta solo la seconda. Il Requirement delle cartelle va completato con questa eccezione. Costo: una colonna in più nel database locale e una regola in più nel Model.

## Where in the code

lib/core/services/sync_service.dart: syncNow (ramo cartelle, invio della coda) e handleRemoteFolderChange (ramo di eliminazione)
