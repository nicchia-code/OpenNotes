---
description: Use when changing how notes and folders are synchronised, conflicts resolved, the queue retried, users authenticated or the cloud project secured.
---
# Cloud sync rules

## cloud-sync
- Row-level security attiva su `notes` e `folders`: lettura, inserimento, modifica ed eliminazione permesse solo sulle righe con `user_id` uguale all'utente autenticato.
- Pubblicazione realtime attiva su `notes` e `folders`; l'app si iscrive filtrando per `user_id` uguale all'utente connesso.
- Archiviazione `note-attachments`: caricamento permesso solo nella cartella il cui primo segmento è l'identificativo dell'utente; lettura permessa a chiunque sul bucket.

## cloud-connection
- Indirizzo e chiave vengono solo dalle variabili di build `SUPABASE_URL` e `SUPABASE_ANON_KEY`; non esistono valori incorporati nel codice e i valori salvati sul dispositivo non vengono usati.
- Una variabile conta come mancante se non è passata, è vuota o contiene solo spazi; il formato dei valori non viene controllato. Il collegamento si prepara solo se nessuna delle due manca.
- Testo dell'avviso di cloud non configurato: "Cloud non configurato: manca SUPABASE_URL." oppure "Cloud non configurato: manca SUPABASE_ANON_KEY."; se mancano entrambe, "Cloud non configurato: mancano SUPABASE_URL e SUPABASE_ANON_KEY.".
- All'avvio l'avviso compare una sola volta come barra temporanea in basso, con lo stesso stile degli altri messaggi globali dell'app; il tentativo di accesso Google mostra lo stesso testo.

## account
- Provider di accesso: Google OAuth tramite Supabase Auth.
- Su desktop (Linux, macOS, Windows) il ritorno avviene su un server locale in ascolto su 127.0.0.1 porta 3000, con indirizzo di ritorno `http://localhost:3000`; se la porta non si apre, e su mobile, l'indirizzo di ritorno è `opennotes://login-callback`.
- La pagina di successo nel browser tenta di chiudersi dopo 1500 ms.
- Su macOS l'app sandbox dichiara i permessi di rete client e server (necessari al server locale di ritorno).

## sync-run
- Una sola sincronizzazione alla volta; le richieste durante una sincronizzazione in corso vengono scartate.
- Ordine fisso: invio della coda, lettura del cloud, invio delle note mai sincronizzate, download delle cartelle, download delle note.
- Conflitti sulle note: vince l'ultimo che ha scritto, confrontando la data di modifica; la copia locale resta solo se strettamente più recente di quella del cloud, a parità vince il cloud. La stessa regola vale per le modifiche ricevute in tempo reale. Un salvataggio in coda non strettamente più recente della copia del cloud viene scartato.
- Eliminazioni di note in coda: si confronta il momento in cui l'eliminazione è entrata in coda (`created_at` della coda) con la data di modifica della nota del cloud; se il cloud è più recente l'eliminazione viene scartata e la nota torna sul dispositivo con il download, altrimenti la nota viene cancellata dal cloud.
- Nota eliminata altrove: se il cloud non ha più una nota già sincronizzata dal dispositivo, il suo salvataggio in coda viene scartato e la nota viene eliminata dal dispositivo con il suo file nel vault (se nessun'altra nota lo usa).
- Conflitti sulle cartelle: creazione e rinomina in coda sovrascrivono la cartella del cloud senza confronto di date, anche se il cloud la ha già; un'eliminazione in coda viene scartata se la cartella del cloud è stata modificata dopo il momento in cui l'eliminazione è entrata in coda; al download la cartella del cloud sovrascrive sempre quella locale.
- Nota scaricata (sincronizzazione completa o tempo reale) la cui cartella non esiste sul dispositivo: va nella cartella `notes`, senza cambiare la data di modifica e senza entrare in coda.
- Note di benvenuto: una nota mai sincronizzata il cui titolo è esattamente "Benvenuto in OpenNotes" o "Pianificazione & Attività" non entra in coda quando viene salvata; durante la sincronizzazione viene eliminata definitivamente dal dispositivo, invece che inviata, se il cloud ha almeno una nota.
- Il download non elimina mai note o cartelle locali assenti dal cloud.
- Allegati scaricati: quando la versione del cloud di una nota sostituisce quella locale, si scaricano le immagini e i disegni che mancano sul dispositivo; un download non riuscito viene solo annotato nel registro dell'app e non interrompe la sincronizzazione; la nota arriva senza quell'allegato e il download viene ritentato alla sincronizzazione successiva in cui la nota viene di nuovo sostituita dalla versione del cloud.

## pending-change
- Coda FIFO per identificativo crescente; nessuna fusione di cambiamenti sulla stessa nota.
- Un elemento viene rimosso dopo che il cloud lo ha accettato oppure quando viene scartato; al primo errore l'intera sincronizzazione si interrompe e gli elementi restanti attendono.
- Nessun ritardo né limite di tentativi: il nuovo tentativo avviene alla successiva richiesta di sincronizzazione (nuovo cambiamento accodato, accesso, rinnovo del token, avvio dell'app, comando manuale).
- Scarti, senza avvisare l'utente: salvataggio di nota non strettamente più recente della copia del cloud; salvataggio di una nota che il cloud non ha più ma che il dispositivo aveva già sincronizzato; eliminazione di nota o di cartella più vecchia dell'ultima modifica sul cloud; cambiamenti delle note rimosse per il cambio di account.
- Ogni accodamento, se un utente è connesso, chiede subito una sincronizzazione senza attenderla.
