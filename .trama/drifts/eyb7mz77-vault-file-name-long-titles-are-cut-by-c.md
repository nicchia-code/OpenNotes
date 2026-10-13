---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#vault-file
  - vault-file/Written
proposal: null
task: 3k6ct68q
origin: null
critical: false
option: 1
note: null
resolvedBy: aq0a6puk
created: 2026-10-12T14:32:13.088Z
---
# Vault file name: long titles are cut by code units, the Requirement counts characters

## What happens

Quando il titolo di una nota è più lungo di 50 caratteri, il nome del file nel vault viene accorciato contando le unità di codice del testo. Un titolo con emoji o altri caratteri fuori dal piano base viene quindi accorciato prima dei 50 caratteri previsti, e il taglio può cadere a metà di un carattere, lasciando un nome con un carattere spezzato.

## What should happen

Il Requirement dice che, oltre 50 caratteri, il nome del file tiene i primi 50 caratteri (ripuliti dagli spazi finali). Un carattere fuori dal piano base conta come un solo carattere, e il nome non deve mai contenere un carattere spezzato.

## Fix options

### Contare i caratteri come nel Requirement

Il nome del file viene accorciato per caratteri interi, come scritto nel Requirement: un emoji conta come uno. Il codice cambia solo nel calcolo della lunghezza e nel taglio, senza effetti sulle note già salvate, che restano con il nome attuale fino alla prossima scrittura. Costo: poco, un test sui titoli con emoji.

### Cambiare il Requirement sul conteggio

Il codice resta com'è e il Requirement dice che il limite è di unità di codice. Nei titoli con caratteri fuori dal piano base il nome del file resta più corto dei caratteri visibili, e il taglio può ancora spezzare un carattere, quindi il problema resta da correggere comunque. Costo: il Requirement perde la sua chiarezza per l'utente finale, e il rischio di nomi non validi resta.

## Where in the code

lib/core/services/vault_service.dart, metodo saveNote (calcolo di sanitizedTitle.length e substring)
