---
description: Usa quando converti una nota in Markdown, impagini il PDF di una nota o calcoli i nomi dei file esportati e del vault.
---
# Export rules

## export
- Conversione in Markdown di una nota usata da condivisione ed esportazione su file.
- Nota in testo semplice: a inizio riga, mantenendo il rientro, `○` diventa `- [ ] `, `●` diventa `- [x] `, `•` `◦` `▪` diventano `- `; il resto resta invariato.
- Nota a blocchi, un blocco per riga: titolo → `# testo` (riga vuota se il titolo è vuoto); h1/h2/h3 → `#`, `##`, `###`; checklist → `- [x] ` o `- [ ] `; elenco puntato → `- `; elenco numerato → sempre `1. `; citazione → `> `; divisore → `---`; immagine → `![](percorso)`; tabella → tabella Markdown con la prima riga come intestazione, una riga separatrice `---` per colonna, righe completate con celle vuote fino al numero massimo di colonne, seguita da una riga vuota (tabella vuota omessa).
- Altri blocchi (paragrafo, codice): stile per riga titolo/h1 → `# `, h2 → `## `, h3 → `### ` se la riga non inizia già con `#`; poi la stessa conversione dei simboli di lista del testo semplice.
- Formattazione in linea: grassetto `**x**`, poi corsivo `*x*`, poi barrato `~~x~~` (grassetto e corsivo insieme → `***x***`); il sottolineato non viene esportato.
- Il risultato è privo di spazi e righe vuote finali; se il documento a blocchi non è leggibile si restituisce il contenuto grezzo.

## export-markdown-share
- Testo condiviso: titolo, riga vuota, conversione Markdown della nota; oggetto della condivisione: il titolo.
- Se il sistema non riesce ad aprire il foglio di condivisione: messaggio «Nota non condivisa: impossibile aprire il foglio di condivisione.»; non viene condiviso nulla.

## export-markdown-file
- Nome proposto: titolo con `\ / : * ? " < > |` sostituiti da `_`, spazi agli estremi rimossi; se vuoto `Nota`; più `.md`.
- Contenuto: conversione Markdown della nota codificata in UTF-8, tipo `text/markdown`.

## export-pdf
- Pagina A4, margini di 40 punti su ogni lato, più pagine se il testo lo richiede; documento intitolato `<titolo>.pdf`.
- Intestazione: data dell'ultima modifica nel formato `d MMMM yyyy, HH:mm` in italiano (`it_IT`), grigio, 10 punti; poi titolo 22 punti grassetto, linea divisoria grigio chiaro spessa 0,5.
- Corpo dalla conversione in Markdown della nota (la stessa di condivisione ed esportazione su file), senza la riga o il blocco da cui nasce il titolo, anche se formattato o troncato; letto riga per riga: riga vuota → spazio di 8 punti; `# ` 18 punti, `## ` 15 punti, `### ` 13 punti, tutti in grassetto; `- [ ] `, `- [x] `, `- [X] ` → cerchio di 12 punti, pieno color ambra e testo grigio barrato se completato; `- ` o `* ` → punto elenco; ogni altra riga → paragrafo 11 punti. Un segno vuoto conserva il suo aspetto (una voce di checklist o di elenco vuota mostra il cerchio o il punto, un'intestazione vuota resta un'intestazione). Il rientro delle voci di elenco e di checklist sposta la voce a destra. La formattazione in linea non viene applicata: i segni di grassetto, corsivo e barrato, le citazioni, i divisori, le immagini e le tabelle compaiono come testo Markdown.

## vault-file
- Nome del file: titolo con `\ / : * ? " < > | { } [ ]` sostituiti da `_`, spazi consecutivi ridotti a uno, spazi agli estremi rimossi; oltre 50 caratteri si tengono i primi 50 (ripuliti dagli spazi finali); se il risultato è vuoto `nota_<primi 8 caratteri dell'id>.md`, altrimenti `<nome>.md`.
- Il nome viene ricalcolato dal titolo attuale a ogni scrittura; la nota ricorda il percorso dell'ultimo file scritto.
- Un file del vault si cancella solo se nessun'altra nota, anche nel cestino, ricorda lo stesso percorso; le note rimosse nella stessa operazione non contano. Vale per l'eliminazione definitiva, per le note eliminate dal cloud, per il cambio di account e per le note di benvenuto scartate.
