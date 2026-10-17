---
column: done
technical: true
refs:
  - requirements/data#cloud-sync
  - requirements/rules#cloud-sync
drift: null
proposal: 634nfp49
agent: false
created: 2026-10-17T10:33:15.023Z
finished: 2026-10-17T11:20:34.819Z
---
# Cloud schema revisions

Lo schema Supabase passa a migrazioni versionate e porta le revisioni.

- Nuova migrazione in `supabase/migrations/` che, su un progetto esistente: aggiunge `revision` (valorizzata dalla sequenza unica `sync_revision_seq` per le righe esistenti) e `purged_at` a `notes` e `folders`; aggiunge il trigger BEFORE INSERT OR UPDATE che assegna la revisione; rimuove il trigger che riscriveva `updated_at`; crea gli indici `(user_id, revision)`.
- Funzioni `push_note` e `push_folder` (`SECURITY DEFINER`): proprietario = `auth.uid()`, scrittura solo se la revisione di base coincide (o la riga non esiste e la base è vuota), altrimenti risposta di conflitto con la riga attuale; errore di permesso su una riga di un altro utente; il segnaposto di una cartella toglie la cartella superiore alle sottocartelle, ognuna con una nuova revisione; una scrittura su un segnaposto lo fa rinascere.
- Row Level Security: lettura diretta solo delle proprie righe; inserimento, modifica ed eliminazione diretti revocati a `authenticated`.
- Archiviazione `note-attachments`: permessi di sovrascrittura ed eliminazione nella cartella dell'utente.
- `supabase/schema.sql` aggiornato allo schema completo risultante.

Fatto quando la migrazione applicata a un progetto con dati esistenti lascia ogni riga con una revisione, una scrittura diretta da client fallisce per permesso e due invii con la stessa revisione di base producono un'accettazione e un conflitto.
