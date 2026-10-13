---
description: Serve quando si leggono o scrivono cartelle, tag, viste dell'elenco note o la nota selezionata, nell'archivio locale o nel cloud.
---
# Organization data

## folder
- Cartella: identificativo testuale (UUID v4 per le cartelle utente), nome obbligatorio, cartella superiore facoltativa, icona (predefinita `folder`), indicatore di cartella di sistema, data di creazione e di ultima modifica (ISO 8601).
- Archivio locale SQLite: tabella `folders` con indicatore di sistema intero 0/1; alla creazione del database viene inserita la cartella di sistema `notes` con nome "Note".
- Cloud Supabase: tabella `folders` con gli stessi campi più l'utente proprietario (eliminato a cascata con l'utente); cartella superiore con riferimento che si azzera se la superiore viene eliminata; indicatore di sistema booleano; data di modifica aggiornata da un trigger; Row Level Security che limita lettura, inserimento, modifica ed eliminazione alle righe dell'utente; tabella pubblicata in realtime.
- Una nota appartiene a una sola cartella tramite il suo identificativo (predefinito `notes`); non c'è vincolo di integrità tra nota e cartella, né in locale né nel cloud.

## note-browser
- Tag: nome normalizzato e numero di note non nel cestino che lo usano. Non è memorizzato: si ricava a ogni lettura dai tag memorizzati delle note e dai `#tag` presenti nel loro contenuto. Due tag sono uguali a prescindere da maiuscole e minuscole.
- Viste che non sono cartelle memorizzate: "Tutte le note" (`system_all`), "Eliminati di recente" (`system_trash`), "Note rapide" (`system_quick_notes`, mai mostrata).
- Stato della vista, solo in memoria: vista selezionata (all'avvio `system_all`), insieme dei tag selezionati (normalizzati), testo di ricerca, elenco cartelle, elenco tag, conteggio per "Tutte le note", per "Note" e per ogni cartella, numero di note nel cestino.

## note-selection
- Al più una nota selezionata, indicata dal suo identificativo; solo in memoria.
