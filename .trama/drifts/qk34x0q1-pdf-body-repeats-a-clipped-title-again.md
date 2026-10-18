---
status: resolved
resolution: proposal
refs:
  - requirements/rules#export-pdf
proposal: null
task: null
origin: null
previous: 1wrjlxwa
critical: false
option: null
note: null
resolvedBy: r3ka8qvl
created: 2026-10-18T20:12:14.581Z
---
# PDF body repeats a clipped title again

## What happens

Quando il titolo della nota è più lungo di 60 caratteri, il PDF lo stampa due volte: una volta come titolo in cima alla pagina e una volta come prima riga del corpo, con l'intero testo della prima riga in grassetto a 18 punti. Vale anche per le note con la prima riga in grassetto o corsivo.

## What should happen

Il PDF salta la riga da cui nasce il titolo anche quando il titolo è troncato o formattato, così il titolo compare una sola volta nel documento. La condivisione, invece, deve conservare la prima riga intera: le due regole sono diverse.

## Fix options

### Ricavare il corpo del PDF senza la prima riga, separatamente dalla condivisione

Il PDF toglie sempre la riga da cui nasce il titolo, anche se troncata o formattata, mentre la condivisione mantiene la prima riga intera come deciso prima. Il corpo condiviso e il corpo stampato hanno così due regole separate. Costo: piccolo, un percorso in più nella conversione della nota, da coprire con un test sul titolo lungo.

### Confrontare il titolo senza formattazione e senza troncamento

Il PDF salta la prima riga quando, ignorati grassetto, corsivo, simboli di intestazione e il troncamento a 60 caratteri, coincide con il titolo. Il titolo resta in cima come oggi e il corpo non lo ripete. Costo: piccolo, ma il confronto resta fragile per le righe che non rientrano nei casi previsti, e una riga diversa dal titolo può comparire due volte.

## Where in the code

lib/core/services/pdf_export_service.dart (_buildDocument, toMarkdownBody); lib/core/models/note_model.dart (toMarkdownBody, _titleIsClipped)
