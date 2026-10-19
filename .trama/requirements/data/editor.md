---
description: Usare quando si legge, si scrive o si converte il contenuto di una nota (documento a blocchi, formattazione, tabelle, immagini, disegni).
---
# Editor document

## note-editor
- Il contenuto della nota è un testo. Di norma è un elenco JSON di blocchi. Se non è un elenco JSON i cui elementi sono tutti oggetti (per esempio non comincia con «[», non è JSON valido oppure è `[1]`), viene letto come Markdown o testo semplice (il formato precedente). L'elenco vuoto `[]` è un documento a blocchi senza parti.
- Campi di ogni blocco:
  - `id`: UUID, generato se manca;
  - `type`;
  - `text`;
  - `isChecked`: booleano;
  - `spans`: elenco di intervalli di formattazione;
  - `lineStyles`: mappa da indice di riga (come stringa) a nome di tipo, scritta solo se non è vuota;
  - `tableData`: righe di celle di testo, scritte solo se presenti.
- Tipi di blocco: `title`, `h1`, `h2`, `h3`, `paragraph`, `code`, `bullet`, `numbered`, `checklist`, `quote`, `divider`, `table`, `image`. Un tipo sconosciuto viene letto come `paragraph`.
- L'editor salva ogni sezione di testo come `paragraph`, con gli stili di riga `title`, `h1`, `h2`, `h3` o `paragraph`. Gli altri tipi testuali arrivano solo da contenuti precedenti e vengono convertiti al caricamento.
- Intervallo di formattazione: `start` e `end` sono posizioni di carattere nel testo del blocco, con la fine esclusa. I flag sono `bold`, `italic`, `underline` e `strikethrough`; nel JSON si scrivono solo quelli veri.
- Convenzioni dentro il testo:
  - voce di checklist da fare «○ », fatta «● »;
  - voce puntata «• », «◦ » o «▪ » secondo il livello;
  - voce numerata «N. »;
  - citazione «> »;
  - monospazio «``` »;
  - rientro di due spazi per livello.
- Blocco immagine: `text` contiene il percorso relativo dell'allegato nel vault («attachments/…») oppure un percorso assoluto.
- Blocco tabella: una matrice di stringhe in cui la prima riga è l'intestazione. Le righe più corte vengono completate con celle vuote.
- Allegati: file nella cartella `attachments` del vault, con nome «att_<millisecondi>.<estensione>». L'estensione è quella del file scelto, oppure `png` se manca. Per un'immagine incollata è quella del formato salvato: `png`, `jpg`, `gif` o `webp`.

## drawing-canvas
- Il disegno esportato è un'immagine PNG di 800×600 pixel con sfondo bianco, salvata come allegato con estensione `png`.
