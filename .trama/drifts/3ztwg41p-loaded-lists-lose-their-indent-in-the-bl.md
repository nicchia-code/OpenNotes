---
status: resolved
resolution: fix-code
refs:
  - text-line/Bulleted item
  - requirements/rules#text-line
proposal: null
task: b0usfty2
origin: null
critical: false
option: 1
note: null
resolvedBy: xnzq15fv
created: 2026-10-12T08:27:49.803Z
---
# Loaded lists lose their indent in the block format

## What happens

Una voce di elenco rientrata, salvata con il trattino o l'asterisco, si riapre senza rientro e con il simbolo del primo livello. Lo stesso vale per una checklist scritta con la casella tra parentesi quadre. Lo stesso contenuto in formato precedente mantiene il rientro e il simbolo del suo livello.

## What should happen

Il Model dice che il rientro è di due spazi per livello e che una riga caricata parte già nel tipo che ricava dal contenuto. I requisiti dicono che il simbolo di elenco dipende dal livello, cioè dal numero di spazi. Una voce rientrata deve quindi riaprirsi rientrata, con il simbolo del suo livello, in qualunque formato venga letta.

## Fix options

### Conservare il rientro anche nel formato a blocchi

Al caricamento, la voce puntata o la checklist scritta con trattino, asterisco o casella mantiene il rientro e riceve il simbolo del suo livello, come già avviene nel formato precedente. Costo: allineare la lettura a blocchi con quella del formato precedente; le note già salvate con i simboli di Trama non cambiano.

### Usare un'unica lettura per entrambi i formati

Il caricamento a blocchi passa per la stessa lettura riga per riga del formato precedente, così le due strade non possono più divergere. Costo: un lavoro più ampio per una correzione piccola, con il rischio di cambiare anche righe che oggi sono già corrette.

## Where in the code

lib/ui/editor/notion_document_editor.dart (caricamento a blocchi, _parseContentToBlocks, rami per trattino e casella)
