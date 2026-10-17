---
description: Use when reading or writing cloud tables, the local sync queue or the stored cloud connection settings.
---
# Cloud sync data

## cloud-sync
- Tabella cloud `notes` (Postgres su Supabase): `id` testo chiave primaria (stesso identificativo della nota locale); `user_id` UUID obbligatorio, riferito all'utente di autenticazione, con cancellazione a cascata; `title` testo, predefinito "Nuova nota"; `content` testo, predefinito vuoto (documento a blocchi in JSON, come in locale); `folder_id` testo, predefinito `notes`, senza vincolo verso le cartelle; `tags` array di testo, predefinito vuoto; `is_pinned`, `is_locked`, `is_deleted` booleani, predefiniti falso; `deleted_at` timestamp con fuso, facoltativo; `created_at`, `updated_at` timestamp con fuso, predefiniti all'ora del server; `revision` bigint obbligatorio; `purged_at` timestamp con fuso, facoltativo.
- Tabella cloud `folders`: `id` testo chiave primaria; `user_id` UUID obbligatorio, cancellazione a cascata con l'utente; `name` testo obbligatorio; `parent_id` testo riferito a un'altra cartella, azzerato se quella viene eliminata; `icon` testo, predefinito `folder`; `is_system` booleano, predefinito falso; `created_at`, `updated_at` timestamp con fuso; `revision` bigint obbligatorio; `purged_at` timestamp con fuso, facoltativo.
- `revision`: assegnata da un trigger BEFORE INSERT OR UPDATE su `notes` e `folders` con il valore successivo di un'unica sequenza `sync_revision_seq`, condivisa dalle due tabelle; il client non la sceglie mai.
- `updated_at`: scritto dal client con l'ora di modifica del dispositivo; nessun trigger lo riscrive. Il trigger che lo impostava all'ora del server viene rimosso.
- `purged_at`: vuoto per una riga viva; valorizzato con l'ora dell'eliminazione per un segnaposto di eliminazione, che per una nota ha `title` e `content` vuoti e `tags` vuoto, e per una cartella conserva solo il nome.
- Indici: `notes (user_id, revision)` e `folders (user_id, revision)`.
- Funzioni del database `push_note(p_note jsonb, p_base_revision bigint)` e `push_folder(p_folder jsonb, p_base_revision bigint)`, `SECURITY DEFINER`, eseguibili dal ruolo `authenticated`: impostano `user_id` a `auth.uid()` e restituiscono un JSON `{"status": "accepted", "revision": <nuova revisione>}` oppure `{"status": "conflict", "row": <riga attuale>}`. Al ruolo `authenticated` restano solo i permessi di lettura diretta su `notes` e `folders`.
- Le tabelle `notes` e `folders` hanno `REPLICA IDENTITY FULL`; le eliminazioni arrivano al canale realtime come aggiornamenti delle righe, perché diventano segnaposti.
- Bucket di archiviazione `note-attachments`, pubblico, pensato per immagini e disegni; i file di un utente stanno in una cartella con il suo identificativo.
- In locale ogni nota ha `synced_at` (testo ISO 8601, facoltativo): vuoto finché la nota non è mai stata sincronizzata; le note scaricate dal cloud lo ricevono all'ora del download. Note e cartelle locali hanno `cloud_revision` (intero, facoltativo): l'ultima revisione del cloud vista dal dispositivo, vuota se il dispositivo non ne ha mai vista una. Il percorso del file nel vault, `synced_at` e `cloud_revision` non vengono mai inviati al cloud.
- Conversione: in locale tag come testo JSON e flag come interi 0/1; sul cloud tag come array e flag come booleani; date in ISO 8601.
- Migrazione del cloud per le revisioni: aggiunge `revision` (valorizzata dalla sequenza per le righe esistenti) e `purged_at`, la sequenza, i trigger, le funzioni, gli indici, la revoca delle scritture dirette e i permessi di sovrascrittura ed eliminazione degli allegati; rimuove il trigger che riscriveva `updated_at`.

## pending-change
- Tabella locale SQLite `sync_queue`: `id` intero autoincrementale (ordine di invio); `entity_type` testo (`note` o `folder`); `entity_id` testo; `action` testo (`upsert` o `delete`); `payload` testo JSON; `created_at` testo ISO 8601, il momento in cui il cambiamento è entrato in coda o è stato aggiornato (per un'eliminazione è il momento dell'eliminazione, confrontato con `updated_at` del cloud); `base_revision` intero facoltativo, la revisione del cloud su cui si basa; `attempts` intero, predefinito 0, i rifiuti di fila; `set_aside` intero 0/1, predefinito 0; `last_error` testo facoltativo, il messaggio dell'ultimo rifiuto.
- Indice unico su (`entity_type`, `entity_id`).
- Per `upsert` di una nota il payload è la nota nel formato del cloud, con `user_id` dell'utente connesso o vuoto se nessuno lo è (sostituito all'invio); per `upsert` di una cartella è la cartella nel formato del cloud, con lo stesso trattamento di `user_id`; per `delete` contiene solo `id`.

## sync-run
- Preferenze locali: `sync_last_revision` (intero), l'ultima revisione scaricata, assente finché il dispositivo non ha completato un controllo completo con le revisioni; `sync_last_completed_at` (testo ISO 8601), l'ora dell'ultima sincronizzazione completata.
- Tabella locale SQLite `uploaded_attachments`: `path` testo chiave primaria, il percorso relativo di un allegato del vault che il cloud ha già.

## cloud-connection
- Indirizzo e chiave non vengono salvati sul dispositivo. Le preferenze `supabase_url` e `supabase_anon_key` scritte da versioni precedenti restano sul dispositivo ma non vengono più lette né scritte, né cancellate.

## account
- La sessione è conservata dalla libreria client Supabase tra un avvio e l'altro; l'identificativo dell'utente autenticato è il proprietario (`user_id`) di tutte le righe cloud; l'email viene solo mostrata.
- Il dispositivo ricorda nelle preferenze locali l'identificativo dell'ultimo utente che ha sincronizzato; non viene cancellato alla disconnessione e serve a riconoscere il cambio di account.
