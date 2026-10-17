---
description: Serve quando si cambiano cartelle, filtri per tag, ricerca, ordinamento e conteggi dell'elenco note o le regole di selezione automatica della nota.
---
# Organization rules

## folder
- Identità: `notes` ("Note") è l'unica cartella di sistema memorizzata e non può essere eliminata; `system_all`, `system_trash` e `system_quick_notes` sono solo identificativi di vista.
- Nome: spazi agli estremi rimossi; il nome vuoto non è accettato; nessun controllo di unicità; nessuna lunghezza massima.
- Ordinamento dell'elenco cartelle: prima quelle di sistema, poi per nome crescente con il confronto binario di SQLite (maiuscole prima delle minuscole).
- Selettore "Sposta in…": esclude "Tutte le note" e il cestino; mostra le cartelle ad albero secondo la cartella superiore, fratelli ordinati per nome senza distinzione tra maiuscole e minuscole, rientro proporzionale alla profondità; le cartelle orfane vanno in fondo; la cartella attuale della nota non è selezionabile.
- Eliminazione: rimuove solo cartelle non di sistema; tutte le note con quella cartella, comprese quelle nel cestino, passano a `notes`, senza cambiare la data di modifica, ed entrano nella coda come salvataggi. Sul dispositivo le sottocartelle non vengono toccate subito; quando l'eliminazione arriva al cloud, le sottocartelle perdono la cartella superiore e, alla sincronizzazione successiva, diventano di primo livello anche sul dispositivo. Le note di una cartella eliminata altrove passano a `notes` senza entrare nella coda.
- Creazione, rinomina ed eliminazione di una cartella dell'utente entrano nella coda di sincronizzazione (`entity_type` `folder`). Le cartelle ricevute dal cloud (tempo reale o sincronizzazione) seguono la stessa regola delle note: sostituiscono quelle locali salvo che il dispositivo abbia una modifica in attesa della stessa cartella strettamente più recente.

## note-browser
- Ordinamento note: prima le fissate, poi per data di ultima modifica decrescente.
- Vista: cestino → solo note nel cestino, di tutte le cartelle; "Tutte le note" → note non nel cestino di tutte le cartelle; cartella → note non nel cestino con quella cartella. Con almeno un tag selezionato la cartella viene ignorata e si guardano le note non nel cestino di tutte le cartelle.
- Selezionare un tag (anche in aggiunta) riporta la vista a "Tutte le note" filtrata da quel tag; un clic semplice sull'unico tag già selezionato lo toglie dalla selezione nella barra laterale, in un'etichetta di una nota o nell'editor, ma non nella schermata Cartelle su mobile, dove il filtro resta; selezionare una vista svuota la selezione dei tag; il testo di ricerca non viene mai azzerato da un cambio di vista.
- Normalizzazione del tag selezionato: si tolgono tutti i `#`, gli spazi agli estremi e si passa in minuscolo; un tag che diventa vuoto svuota la selezione.
- Corrispondenza tag: i tag selezionati si combinano in AND; una nota corrisponde a un tag solo se l'elenco dei suoi tag memorizzati, in minuscolo, contiene quel tag intero (`"tag"`); un tag più lungo che comincia con lo stesso testo non corrisponde (filtrando per `lav` non compaiono le note con `#lavoro`).
- Ricerca: testo ripulito dagli spazi agli estremi e in minuscolo; vuoto significa nessun filtro; la nota corrisponde se il titolo o il contenuto grezzo, in minuscolo, lo contengono come sottostringa; si combina in AND con vista e tag. La creazione o la duplicazione di una nota svuota il testo di ricerca.
- Estrazione dei tag dal contenuto: `#` seguito da lettere o cifre di qualunque alfabeto, `_` o `-`, preceduto da inizio testo, spazio o una tra `(`, `[`, `{`; in minuscolo, senza doppioni, in ordine alfabetico; nei documenti a blocchi si cercano nel testo di ogni blocco e nelle celle delle tabelle.
- Elenco dei tag: solo note non nel cestino; per ogni nota si uniscono i tag memorizzati (normalizzati) e quelli estratti dal contenuto; il conteggio è il numero di note che hanno il tag; ordinamento per nome.
- Conteggi: "Tutte le note" = note non nel cestino; ogni cartella, compresa "Note" = note non nel cestino in quella cartella; cestino = note nel cestino. Ricalcolati dopo ogni ricarica dell'elenco note o delle cartelle.

## note-selection
- Dopo ogni ricarica dell'elenco: se la nota selezionata non è più nell'elenco si seleziona la prima nota o nessuna se l'elenco è vuoto; se nessuna nota è selezionata e l'elenco non è vuoto si seleziona la prima.
- Spostamento nel cestino: si seleziona la nota che seguiva quella spostata, altrimenti la precedente, purché sia ancora nell'elenco ricaricato.
- Creazione e duplicazione selezionano la nuova nota.
