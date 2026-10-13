---
description: Use when reading or writing cloud tables, the local sync queue or the stored cloud connection settings.
---
# Cloud sync data

## cloud-sync
- Tabella cloud `notes` (Postgres su Supabase): `id` testo chiave primaria (stesso identificativo della nota locale); `user_id` UUID obbligatorio, riferito all'utente di autenticazione, con cancellazione a cascata; `title` testo, predefinito "Nuova nota"; `content` testo, predefinito vuoto (documento a blocchi in JSON, come in locale); `folder_id` testo, predefinito `notes`, senza vincolo verso le cartelle; `tags` array di testo, predefinito vuoto; `is_pinned`, `is_locked`, `is_deleted` booleani, predefiniti falso; `deleted_at` timestamp con fuso, facoltativo; `created_at`, `updated_at` timestamp con fuso, predefiniti all'ora del server.
- Tabella cloud `folders`: `id` testo chiave primaria; `user_id` UUID obbligatorio, cancellazione a cascata con l'utente; `name` testo obbligatorio; `parent_id` testo riferito a un'altra cartella, azzerato se quella viene eliminata; `icon` testo, predefinito `folder`; `is_system` booleano, predefinito falso; `created_at`, `updated_at` timestamp con fuso.
- Un trigger del server imposta `updated_at` all'ora del server a ogni aggiornamento di note e cartelle (non agli inserimenti).
- Bucket di archiviazione `note-attachments`, pubblico, pensato per immagini e disegni; i file di un utente stanno in una cartella con il suo identificativo.
- In locale ogni nota ha `synced_at` (testo ISO 8601, facoltativo): vuoto finché la nota non è mai stata sincronizzata; le note scaricate dal cloud lo ricevono all'ora del download. Il percorso del file nel vault e `synced_at` non vengono mai inviati al cloud.
- Conversione: in locale tag come testo JSON e flag come interi 0/1; sul cloud tag come array e flag come booleani; date in ISO 8601.

## pending-change
- Tabella locale SQLite `sync_queue`: `id` intero autoincrementale (ordine di invio); `entity_type` testo (`note` o `folder`); `entity_id` testo; `action` testo (`upsert` o `delete`); `payload` testo JSON; `created_at` testo ISO 8601.
- Per `upsert` il payload è la nota nel formato del cloud, con `user_id` dell'utente connesso o vuoto se nessuno lo è (sostituito all'invio); per `delete` contiene solo `id`.

## cloud-connection
- Impostazioni salvate nelle preferenze del dispositivo: `supabase_url` (indirizzo del progetto) e `supabase_anon_key` (chiave pubblica anonima), entrambe senza spazi iniziali e finali.

## account
- La sessione è conservata dalla libreria client Supabase tra un avvio e l'altro; l'identificativo dell'utente autenticato è il proprietario (`user_id`) di tutte le righe cloud; l'email viene solo mostrata.
