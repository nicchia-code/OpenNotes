---
description: Dove e come vengono conservati i dati dell'app; serve per qualsiasi lavoro su persistenza, vault o sincronizzazione.
---

# General data

## General
- Database SQLite locale nel file `opennotes.db` nella cartella documenti dell'app, schema versione 2 con tabelle di cartelle, note, coda di sincronizzazione e allegati presenti sul cloud. L'aggiornamento dalla versione 1 aggiunge le colonne e la tabella della sincronizzazione senza toccare i dati esistenti; le revisioni note restano vuote e la coda esistente viene ridotta a un elemento per nota o cartella, con il contenuto del più recente nella posizione del più vecchio.
- Vault Markdown nella cartella `OpenNotes_Vault` dentro la cartella documenti dell'app, con sottocartella `attachments` per immagini e disegni; entrambe create all'avvio se mancano.
- Preferenze locali sul dispositivo per il PIN principale e per lo stato della sincronizzazione (ultima revisione scaricata, ora dell'ultima sincronizzazione, ultimo utente che ha sincronizzato); la configurazione cloud non è salvata sul dispositivo.
- Cloud Supabase facoltativo: tabelle di cartelle e note in Postgres e bucket di storage pubblico `note-attachments` per gli allegati.
- Gli identificatori di note, cartelle e blocchi sono stringhe UUID v4.
- Date e orari sono salvati come testo ISO 8601.
- Nel cloud ogni cartella e nota appartiene a un utente autenticato; ciascun utente può leggere solo i propri dati e scriverli solo attraverso le funzioni di sincronizzazione del database; eliminando l'utente si eliminano a cascata i suoi dati; gli allegati si caricano nella cartella dell'utente ma sono leggibili da chiunque.
