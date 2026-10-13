---
column: done
technical: false
refs:
  - requirements/rules#note-content-save
  - note-content-save/Waiting
drift: 3lshictc
proposal: null
agent: false
created: 2026-10-12T07:38:53.727Z
finished: 2026-10-12T07:40:44.883Z
---
# Fix code to match the Model: Title block does not take precedence over earlier text blocks

## What happens

Il titolo della nota è la prima riga del primo blocco con testo, anche quando più sotto nella nota c'è un blocco di tipo **Titolo** con testo. Se una riga di testo normale sta sopra il Titolo, l'elenco delle note mostra quella riga e il Titolo viene ignorato.

## What should happen

Il blocco di tipo **Titolo** ha la precedenza: se la nota ne contiene uno con testo, il suo testo diventa il titolo, anche quando un blocco di testo normale viene prima. Solo se non c'è nessun Titolo con testo vale la prima riga del primo blocco con testo.

## Chosen option

**Dare precedenza al blocco Titolo**

Il titolo viene cercato prima nei blocchi Titolo con testo e solo dopo nel primo blocco con testo che non sia immagine o tabella. Le note con una riga normale in testa e un Titolo più sotto mostrano il Titolo, come richiesto. Costo: una scansione in più dei blocchi a ogni consegna, trascurabile.

## Where in the code

lib/core/models/note_model.dart, metodo extractTitle, ramo dei blocchi (JSON): il ciclo restituisce il primo blocco con testo senza cercare un blocco Titolo.
