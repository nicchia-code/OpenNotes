---
status: resolved
resolution: fix-code
refs:
  - sync-run/Pushing changes
  - requirements/rules#cloud-sync
proposal: null
task: s5u2yknk
origin: null
critical: false
option: 1
note: null
resolvedBy: ke2oiwmu
created: 2026-10-12T15:08:42.036Z
---
# Attachment overwrite and removal need storage permissions the database setup does not grant

## What happens

Quando una nota con allegati viene inviata, ogni allegato viene ricaricato sopra quello già presente nel cloud, e quando una nota viene eliminata i suoi allegati vengono rimossi dal cloud. Nella configurazione del database del repository, però, il bucket degli allegati permette solo di caricare file nuovi e di leggerli: sovrascrivere e rimuovere vengono rifiutati, e la sincronizzazione si ferma.

## What should happen

Il Requirement permette il caricamento degli allegati solo nella cartella dell'utente e la lettura a chiunque; non dice nulla su sovrascrittura o rimozione. Un invio di nota con immagini già caricate non deve fermare la sincronizzazione.

## Fix options

### Allow overwrite and removal in the user's own folder

Aggiungere al bucket i permessi di aggiornamento e di cancellazione, limitati alla cartella dell'utente. Gli allegati si sovrascrivono e si rimuovono come oggi. Costo: il Requirement va esteso con questi due permessi; un utente può cancellare solo i propri file.

### Upload only missing attachments and keep removed ones

Prima dell'invio il sistema controlla se il file esiste nel cloud e lo carica solo se manca; gli allegati di una nota eliminata restano nel bucket. Non servono permessi nuovi. Costo: file orfani nel bucket e un controllo in più per ogni allegato a ogni invio.

## Where in the code

supabase/schema.sql (storage policies); lib/core/services/sync_service.dart (_uploadAttachments, _removeUnusedAttachments). Non verificato sul progetto Supabase reale: controllare le policy effettive.
