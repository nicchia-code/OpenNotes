---
description: Dove e come vengono conservati i dati dell'app; serve per qualsiasi lavoro su persistenza, vault o sincronizzazione.
---

# General data

## General
- Database SQLite locale nel file `opennotes.db` nella cartella documenti dell'app, schema versione 1 con tabelle di cartelle, note e coda di sincronizzazione.
- Vault Markdown nella cartella `OpenNotes_Vault` dentro la cartella documenti dell'app, con sottocartella `attachments` per immagini e disegni; entrambe create all'avvio se mancano.
- Preferenze locali sul dispositivo per il PIN principale; la configurazione cloud non è salvata sul dispositivo.
- Cloud Supabase facoltativo: tabelle di cartelle e note in Postgres e bucket di storage pubblico `note-attachments` per gli allegati.
- Gli identificatori di note, cartelle e blocchi sono stringhe UUID v4.
- Date e orari sono salvati come testo ISO 8601.
- Nel cloud ogni cartella e nota appartiene a un utente autenticato; le regole di accesso consentono a ciascun utente di leggere, creare, modificare ed eliminare solo i propri dati; eliminando l'utente si eliminano a cascata i suoi dati; gli allegati si caricano nella cartella dell'utente ma sono leggibili da chiunque.
