---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#note-content-save
  - note-content-save/Waiting
proposal: null
task: x8a02jwp
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:25:57.155Z
---
# Title block does not take precedence over earlier text blocks

## What happens

Il titolo della nota è la prima riga del primo blocco con testo, anche quando più sotto nella nota c'è un blocco di tipo **Titolo** con testo. Se una riga di testo normale sta sopra il Titolo, l'elenco delle note mostra quella riga e il Titolo viene ignorato.

## What should happen

Il blocco di tipo **Titolo** ha la precedenza: se la nota ne contiene uno con testo, il suo testo diventa il titolo, anche quando un blocco di testo normale viene prima. Solo se non c'è nessun Titolo con testo vale la prima riga del primo blocco con testo.

## Fix options

### Dare precedenza al blocco Titolo

Il titolo viene cercato prima nei blocchi Titolo con testo e solo dopo nel primo blocco con testo che non sia immagine o tabella. Le note con una riga normale in testa e un Titolo più sotto mostrano il Titolo, come richiesto. Costo: una scansione in più dei blocchi a ogni consegna, trascurabile.

### Cambiare la regola: prima riga del primo blocco

Il titolo resta sempre la prima riga di testo e il blocco Titolo serve solo alla formattazione. Il codice non cambia, ma la regola nei Requisiti va riscritta: l'elenco continuerà a mostrare una riga normale anche quando l'utente ha scelto un altro Titolo. Costo: si cambia la regola scritta, non il comportamento.

## Where in the code

lib/core/models/note_model.dart, metodo extractTitle, ramo dei blocchi (JSON): il ciclo restituisce il primo blocco con testo senza cercare un blocco Titolo.
