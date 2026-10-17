---
description: Serve quando si ricavano titolo, anteprima o tag di una nota, quando si crea, duplica o sposta una nota, o quando si gestisce il cestino.
---
# Notes rules

## note
- Titolo predefinito: "Nuova nota", usato alla creazione e quando dal contenuto non si ricava alcun titolo.
- Alla creazione il titolo è quello assegnato (di solito "Nuova nota") e non viene ricavato dal contenuto; i tag sono quelli del filtro attivo uniti a quelli ricavati dal contenuto iniziale, come a ogni salvataggio del contenuto (vale anche per le note di benvenuto). Titolo e tag vengono ricavati dal contenuto a ogni salvataggio successivo del contenuto.
- Documento a blocchi: un contenuto che è un elenco JSON i cui elementi sono tutti oggetti (anche l'elenco vuoto `[]`, che non dà alcun titolo). Ogni altro contenuto, compreso un testo che comincia con `[` ma non è JSON valido o è un elenco con elementi che non sono oggetti (per esempio `[1]`), è testo Markdown.
- Riga utile di un blocco: una riga del testo del blocco che non è vuota, non è una riga di soli tag e ha ancora testo dopo aver tolto i `#` iniziali e gli spazi. Il testo di un blocco può avere più righe: l'editor salva ogni sezione di testo come un solo blocco.
- Titolo ricavato dal contenuto:
  - documento a blocchi: si scorrono i blocchi cercando in ciascuno la sua prima riga utile; il primo blocco Titolo che ne ha una, oppure il primo blocco che ne ha una e non sia immagine o tabella, dà il titolo, che è quella riga (la riga del titolo);
  - testo Markdown: la prima riga non vuota che non sia solo una sequenza di tag;
  - in entrambi i casi dalla riga si tolgono i `#` iniziali e gli spazi, e si tronca a 60 caratteri (togliendo gli spazi finali).
- Riga di soli tag: testo non vuoto i cui elementi separati da spazi sono tutti nella forma `#` seguito da lettere o cifre di qualunque alfabeto, `_` o `-`.
- Pulizia di una riga dell'anteprima: si tolgono i marcatori iniziali di intestazione, elenco, citazione e numerazione, i simboli di elenco `• ○ ● ◦ ▪`, le caselle `[ ]`/`[x]`, `**`, `*` e i backtick, poi gli spazi iniziali e finali.
- Anteprima:
  - nota protetta: sempre "Questa nota è protetta";
  - documento a blocchi: salta i blocchi immagine e tabella; scorre le righe del testo degli altri blocchi, nell'ordine dei blocchi, saltando le righe vuote, le righe di soli tag e la sola riga del titolo (le altre righe del blocco da cui viene preso il titolo restano); pulisce ogni riga e scarta quelle che restano vuote; unisce le righe con uno spazio fermandosi appena il testo supera 90 caratteri (non viene troncato);
  - testo Markdown: salta le righe vuote, le righe di soli tag e la prima riga rimanente (il titolo); pulisce ogni riga e scarta quelle che restano vuote; unisce le righe con uno spazio fermandosi appena il testo supera 90 caratteri;
  - se non resta testo: "Nessun testo aggiuntivo", anche per un documento a blocchi senza testo.
- Tag: `#` seguito da uno o più caratteri tra lettere e cifre di qualunque alfabeto, `_` e `-`, preceduto da inizio testo, spazio o una tra `(`, `[`, `{`; convertiti in minuscolo, senza duplicati, ordinati alfabeticamente. Nei documenti a blocchi si cercano nel testo di ogni blocco e nelle celle delle tabelle.
- Creazione con filtro per tag attivo: i tag selezionati, ciascuno preceduto da `#` e separati da uno spazio, vengono scritti in testa al contenuto seguiti da una riga vuota (o da un a capo se c'è già contenuto che non li contiene).
- Cartella di destinazione alla creazione: la cartella selezionata; la cartella `notes` ("Note") se la selezione è Tutte le note, Note rapide o nessuna. Nel Cestino non si crea una nota: il pulsante non c'è.
- Duplicazione:
  - consentita solo per note fuori dal cestino;
  - titolo della copia: titolo dell'originale seguito da " (copia)", senza troncamento;
  - nel documento a blocchi il testo del primo blocco Titolo diventa il nuovo titolo, o se manca viene inserito un blocco Titolo in testa; nel testo Markdown che inizia con un'intestazione `# ` la prima intestazione viene sostituita con `# ` e il nuovo titolo; altrimenti `# ` e il nuovo titolo vengono aggiunti come prima riga;
  - la copia ha nuovo identificativo, stessa cartella, stessi tag, stessa protezione, non è fissata, date di creazione e modifica nuove.
  - il testo di ricerca viene svuotato, come alla creazione;
- Fissaggio, protezione, spostamento in cartella, cestino, ripristino e salvataggio del contenuto aggiornano la data di modifica; lo spostamento nella cartella "Note" causato dall'eliminazione di una cartella no.
- Ordinamento degli elenchi: prima le note fissate, poi per data di modifica decrescente.
- Le modifiche al contenuto vengono salvate dopo 400 ms senza ulteriori modifiche, con un unico timer condiviso da tutte le note; quando l'app va in secondo piano o si chiude, e prima di fissare, proteggere o togliere la protezione, spostare nel cestino, ripristinare o spostare una nota, la scrittura in attesa parte subito.
- Note di benvenuto: create all'avvio solo se sul dispositivo non esiste nessuna nota fuori dal cestino, senza attendere la sincronizzazione; sono "Benvenuto in OpenNotes" (fissata) e "Pianificazione & Attività", nella cartella "Note". Finché non sono mai state sincronizzate i loro salvataggi non entrano in coda. Durante la sincronizzazione, una nota mai sincronizzata con uno di questi due titoli esatti viene eliminata dal dispositivo se il cloud contiene già delle note non eliminate.
- Protezione di una nota: richiede un PIN principale, che l'utente imposta al momento se manca; togliere la protezione, duplicare ed eliminare definitivamente una nota protetta richiedono il PIN corretto; spostarla nel cestino, ripristinarla, spostarla e fissarla no.

## note/In trash
- Spostare nel cestino imposta il flag di cestino e la data di eliminazione e conserva cartella di origine, fissaggio e protezione.
- Ripristinare toglie il flag e la data di eliminazione e riporta la nota nella cartella di origine; spostare in una cartella una nota del cestino la ripristina in quella cartella. L'annullamento dello spostamento nel cestino equivale al ripristino.
- Le note nel cestino sono escluse da Tutte le note, dai conteggi delle cartelle e dall'elenco dei tag; il Cestino mostra il proprio conteggio.
- Nessuna eliminazione automatica a tempo: una nota esce dal cestino solo per ripristino, spostamento o eliminazione definitiva.
- Eliminazione definitiva (singola o svuotando il cestino): richiede conferma esplicita; per ogni nota, nell'ordine, cancella il file dall'archivio Markdown, accoda la cancellazione nel cloud, poi elimina la nota dal database locale. Il file si cancella solo se nessun'altra nota, anche nel cestino, ha lo stesso percorso; le note eliminate nella stessa operazione non contano, così un file condiviso se ne va con l'ultima di esse.
