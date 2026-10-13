---
column: done
technical: false
refs:
  - text-line/Quote
  - text-line/Monospace
drift: 1vt6edef
proposal: null
agent: false
created: 2026-10-12T11:27:34.890Z
finished: 2026-10-12T11:29:11.912Z
---
# Fix code to match the Model: Tab on a quote or monospace line turns it into body text

## What happens

Dare un Tab a una riga citazione o monospazio la rientra di due spazi, e la riga smette di essere citazione o monospazio nei dati: il suo tipo diventa corpo. Lo schermo però continua a mostrarla come citazione o come monospazio, quindi il tipo salvato non corrisponde a ciò che si vede.

## What should happen

Il Modello non descrive nessun Tab su una citazione o su un monospazio. Una citazione o un monospazio è una riga che comincia con il suo segno, e il Modello non dice cosa succede quando un rientro sposta il segno. I Requisiti dicono che il Tab aggiunge due spazi alle righe normali, ma non dicono se il tipo resta.

## Chosen option

**Il tipo resta con il rientro**

Il Tab rientra la riga e la lascia citazione o monospazio, come già succede per elenchi e checklist. Il tipo viene riconosciuto anche dopo gli spazi di rientro, e il Modello dice che il rientro non cambia il tipo. Costo: una regola in più nel riconoscimento del tipo, e il Modello va aggiornato per il Tab.

## Where in the code

lib/ui/editor/rich_text_editing_controller.dart: Tab sulle righe normali e ricalcolo del tipo di riga dopo ogni modifica; la visualizzazione riconosce citazione e monospazio anche dopo il rientro.
