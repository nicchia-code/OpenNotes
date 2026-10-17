---
column: done
technical: true
refs:
  - requirements/data#General
  - requirements/data#note
  - requirements/data#folder
  - requirements/data#pending-change
  - requirements/data#sync-run
drift: null
proposal: 634nfp49
agent: false
created: 2026-10-17T10:33:15.023Z
finished: 2026-10-17T13:45:51.263Z
---
# Local sync storage

Il database locale passa alla versione 2 dello schema e le preferenze conservano lo stato della sincronizzazione.

- `notes` e `folders` ricevono `cloud_revision` (vuota per le righe esistenti).
- `sync_queue` riceve `base_revision`, `attempts`, `set_aside`, `last_error` e l'indice unico su (`entity_type`, `entity_id`); la migrazione riduce la coda esistente a un elemento per nota o cartella, con il contenuto del più recente nella posizione del più vecchio.
- Nuova tabella `uploaded_attachments`.
- Preferenze `sync_last_revision` e `sync_last_completed_at`, accanto all'ultimo utente che ha sincronizzato.

Fatto quando un database alla versione 1 con note, cartelle e coda si apre senza perdere dati e con le nuove colonne vuote o ai valori predefiniti.
