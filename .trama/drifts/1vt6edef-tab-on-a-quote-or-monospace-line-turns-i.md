---
status: resolved
resolution: fix-code
refs:
  - text-line/Quote
  - text-line/Monospace
proposal: null
task: ajhf64up
origin: null
critical: false
option: 1
note: null
resolvedBy: m16unv7j
created: 2026-10-12T11:25:58.802Z
---
# Tab on a quote or monospace line turns it into body text

## What happens

Dare un Tab a una riga citazione o monospazio la rientra di due spazi, e la riga smette di essere citazione o monospazio nei dati: il suo tipo diventa corpo. Lo schermo però continua a mostrarla come citazione o come monospazio, quindi il tipo salvato non corrisponde a ciò che si vede.

## What should happen

Il Modello non descrive nessun Tab su una citazione o su un monospazio. Una citazione o un monospazio è una riga che comincia con il suo segno, e il Modello non dice cosa succede quando un rientro sposta il segno. I Requisiti dicono che il Tab aggiunge due spazi alle righe normali, ma non dicono se il tipo resta.

## Fix options

### Il tipo resta con il rientro

Il Tab rientra la riga e la lascia citazione o monospazio, come già succede per elenchi e checklist. Il tipo viene riconosciuto anche dopo gli spazi di rientro, e il Modello dice che il rientro non cambia il tipo. Costo: una regola in più nel riconoscimento del tipo, e il Modello va aggiornato per il Tab.

### Il Tab non rientra citazioni e monospazi

Il Tab su una citazione o su un monospazio non fa nulla: tipo e testo restano come sono, e il Modello non cambia. Costo: una citazione o un blocco monospazio non si possono rientrare, e i Requisiti vanno precisati su questo.

### Il corpo è il tipo dopo il Tab

Il Tab rientra la riga e la riga diventa corpo, come oggi, ma il Modello lo dice esplicitamente con una transizione dalla citazione e dal monospazio. Costo: un Tab fa perdere il tipo citazione o monospazio senza che l'aspetto cambi, e la differenza tra tipo e aspetto va spiegata nel Modello.

## Where in the code

lib/ui/editor/rich_text_editing_controller.dart: Tab sulle righe normali e ricalcolo del tipo di riga dopo ogni modifica; la visualizzazione riconosce citazione e monospazio anche dopo il rientro.
