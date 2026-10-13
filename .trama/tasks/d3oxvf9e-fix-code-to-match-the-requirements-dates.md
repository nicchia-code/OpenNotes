---
column: done
technical: false
refs:
  - pending-change/Queued
drift: null
proposal: null
agent: false
created: 2026-10-12T14:52:23.136Z
finished: 2026-10-12T16:33:20.634Z
---
# Fix code to match the Requirements: Dates sent to the cloud carry no time zone, so the server reads them as UTC

## What happens

Le date che il dispositivo invia al cloud (`created_at`, `updated_at`, `deleted_at` delle note; `created_at`, `updated_at` delle cartelle, anche nei payload già in coda) sono scritte con `toIso8601String()` su un `DateTime` locale, senza fuso orario, per esempio `2026-10-12T10:00:00.000`. Le colonne del cloud sono `timestamptz`, e Supabase usa UTC come fuso predefinito: Postgres interpreta quindi un valore senza fuso come UTC. Su un dispositivo a UTC+2 l'istante salvato risulta due ore più tardi. Il trigger imposta `updated_at` all'ora del server solo sugli aggiornamenti: il primo inserimento conserva la data sbagliata. Il confronto di date della coda ne risulta falsato: un secondo salvataggio della stessa nota fatto entro due ore dal primo viene scartato senza avviso, e un'eliminazione di cartella fatta entro due ore dalla sua creazione viene annullata e la cartella torna con il download.

## What should happen

I Requirement (`requirements/data#cloud-sync`) chiedono date ISO 8601 e colonne con fuso orario: le date inviate al cloud devono indicare l'istante in UTC con il suffisso di fuso (per esempio `2026-10-12T08:00:00.000Z`), come già avviene per le date scritte nel vault. Le date dei payload già in coda, scritte senza fuso, vanno convertite al momento dell'invio. Le date lette dal cloud e quelle locali restano confrontabili come istanti.

## Where in the code

lib/core/models/note_model.dart (`Note.toSupabaseJson`); lib/core/models/folder_model.dart (`Folder.toSupabaseJson`); lib/core/services/sync_service.dart (`syncNow`, rami delle note e delle cartelle; `notifyNoteChanged` e `notifyFolderChanged` costruiscono i payload).
