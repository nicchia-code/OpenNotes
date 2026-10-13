---
description: Use when changing how notes and folders are synchronised, conflicts resolved, the queue retried, users authenticated or the cloud project secured.
---
# Cloud sync rules

## cloud-sync
- Row-level security attiva su `notes` e `folders`: lettura, inserimento, modifica ed eliminazione permesse solo sulle righe con `user_id` uguale all'utente autenticato.
- Pubblicazione realtime attiva su `notes` e `folders`; l'app si iscrive filtrando per `user_id` uguale all'utente connesso.
- Archiviazione `note-attachments`: caricamento permesso solo nella cartella il cui primo segmento è l'identificativo dell'utente; lettura permessa a chiunque sul bucket.

## cloud-connection
- Indirizzo e chiave predefiniti dalle variabili di build `SUPABASE_URL` e `SUPABASE_ANON_KEY`; in loro assenza, valori incorporati nel codice (progetto `https://azbvjyvflrauysxcktji.supabase.co` e relativa chiave anonima).
- I valori salvati sul dispositivo hanno precedenza su quelli predefiniti; il collegamento si prepara solo se entrambi non sono vuoti.

## account
- Provider di accesso: Google OAuth tramite Supabase Auth.
- Su desktop (Linux, macOS, Windows) il ritorno avviene su un server locale in ascolto su 127.0.0.1 porta 3000, con indirizzo di ritorno `http://localhost:3000`; se la porta non si apre, e su mobile, l'indirizzo di ritorno è `opennotes://login-callback`.
- La pagina di successo nel browser tenta di chiudersi dopo 1500 ms.
- Su macOS l'app sandbox dichiara i permessi di rete client e server (necessari al server locale di ritorno).

## sync-run
- Una sola sincronizzazione alla volta; le richieste durante una sincronizzazione in corso vengono scartate.
- Ordine fisso: invio della coda, lettura del cloud, invio delle note mai sincronizzate, download delle note, download delle cartelle.
- Conflitti sulle note: vince l'ultimo che ha scritto, confrontando la data di modifica; la copia locale resta solo se strettamente più recente di quella del cloud, a parità vince il cloud. La stessa regola vale per le modifiche ricevute in tempo reale.
- Conflitti sulle cartelle: vince sempre il cloud, senza confronto di date.
- Note di benvenuto: una nota mai sincronizzata il cui titolo è esattamente "Benvenuto in OpenNotes" o "Pianificazione & Attività" viene eliminata definitivamente dal dispositivo, invece che inviata, se il cloud ha almeno una nota.
- Il download non elimina mai note o cartelle locali assenti dal cloud.

## pending-change
- Coda FIFO per identificativo crescente; nessuna fusione di cambiamenti sulla stessa nota.
- Un elemento viene rimosso solo dopo che il cloud lo ha accettato; al primo errore l'intera sincronizzazione si interrompe e gli elementi restanti attendono.
- Nessun ritardo, limite di tentativi o scarto: il nuovo tentativo avviene alla successiva richiesta di sincronizzazione (nuovo cambiamento accodato, accesso, rinnovo del token, avvio dell'app, comando manuale).
- Ogni accodamento, se un utente è connesso, chiede subito una sincronizzazione senza attenderla.
