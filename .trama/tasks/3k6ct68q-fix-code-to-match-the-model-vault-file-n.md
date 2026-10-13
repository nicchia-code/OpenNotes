---
column: done
technical: false
refs:
  - requirements/rules#vault-file
  - vault-file/Written
drift: eyb7mz77
proposal: null
agent: false
created: 2026-10-12T14:39:15.710Z
finished: 2026-10-12T14:40:20.138Z
---
# Fix code to match the Model: Vault file name: long titles are cut by code units, the Requirement counts characters

## What happens

Quando il titolo di una nota è più lungo di 50 caratteri, il nome del file nel vault viene accorciato contando le unità di codice del testo. Un titolo con emoji o altri caratteri fuori dal piano base viene quindi accorciato prima dei 50 caratteri previsti, e il taglio può cadere a metà di un carattere, lasciando un nome con un carattere spezzato.

## What should happen

Il Requirement dice che, oltre 50 caratteri, il nome del file tiene i primi 50 caratteri (ripuliti dagli spazi finali). Un carattere fuori dal piano base conta come un solo carattere, e il nome non deve mai contenere un carattere spezzato.

## Chosen option

**Contare i caratteri come nel Requirement**

Il nome del file viene accorciato per caratteri interi, come scritto nel Requirement: un emoji conta come uno. Il codice cambia solo nel calcolo della lunghezza e nel taglio, senza effetti sulle note già salvate, che restano con il nome attuale fino alla prossima scrittura. Costo: poco, un test sui titoli con emoji.

## Where in the code

lib/core/services/vault_service.dart, metodo saveNote (calcolo di sanitizedTitle.length e substring)
