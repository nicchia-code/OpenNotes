---
status: resolved
resolution: fix-code
refs:
  - text-line/Title
proposal: null
task: qfmh606u
origin: null
critical: false
option: 1
note: null
resolvedBy: urunre8d
created: 2026-10-12T08:42:16.752Z
---
# Titolo di una nota in formato precedente: una prima riga con elenco o casella non lo riceve

## What happens

Quando si apre una nota in formato precedente, il titolo va alla prima riga con testo solo se questa è testo normale, un «# », un numerato, una citazione o un monospazio. Se la prima riga è un elenco puntato, un elenco con trattino o asterisco, o una casella da fare o fatta, nessuna riga della nota diventa titolo: la riga resta di corpo.

## What should happen

Il Model dice che la prima riga significativa di una nota in formato precedente riceve lo stile Titolo, senza eccezioni per il tipo di riga. Le righe «## » e «### » restano intestazioni.

## Fix options

### Ogni prima riga con testo diventa titolo

La prima riga con testo prende lo stile Titolo anche se è un elenco, una casella, una citazione o un monospazio: il simbolo resta visibile e il testo è in grande. Le righe «# » restano titolo come ora, le «## » e «### » restano intestazioni. Costo: un elenco come primo elemento di una nota vecchia appare come titolo, cosa che può sembrare strana.

### Titolo solo per testo normale e «# »

Il titolo va solo alla prima riga di testo normale o « # », come ora; se la prima riga è un elenco o una casella, nessuna riga diventa titolo. Il Model viene corretto per dire questo. Costo: la regola del Model si restringe e una nota che comincia con un elenco resta senza titolo.

## Where in the code

_parseContentToBlocks, ramo di caricamento del formato precedente in notion_document_editor.dart
