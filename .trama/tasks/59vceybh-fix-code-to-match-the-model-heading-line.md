---
column: done
technical: false
refs:
  - text-line/Heading
  - text-line/Body/user.EDIT_NOTE_TEXT
drift: eld1idb2
proposal: null
agent: false
created: 2026-10-12T14:39:15.720Z
finished: 2026-10-12T14:41:34.412Z
---
# Fix code to match the Model: Heading line with a typed number, quote or fence changes its style

## What happens

Una riga con stile di titolo o intestazione cambia tipo se il suo testo comincia come un elenco numerato, una citazione o un monospazio: «1. Riunione» diventa una voce numerata, «> » una citazione, tre apici inversi un monospazio. Accade alla prima modifica di qualunque punto della sezione, quindi il titolo di una nota che comincia con un numero perde lo stile di titolo. Anche «# 1. Premessa» diventa un elenco invece di un'intestazione, e Invio su una riga di intestazione così fatta produce una nuova voce numerata invece di una riga di corpo.

## What should happen

Il Modello prevede che solo le righe di corpo reagiscano ai segni iniziali di elenco numerato, citazione e monospazio: una riga di titolo o intestazione resta tale, il segno resta nel testo, e Invio su di lei porta a una riga di corpo. Il Requisito vuole che le scorciatoie «# », «## » e «### » valgano su ogni riga, ma non prevede scorciatoie di elenco numerato, citazione o monospazio su righe di intestazione.

## Chosen option

**Le righe di intestazione restano tali**

Il segno digitato cambia il tipo solo delle righe di corpo, come nel Modello. Un titolo «1. Riunione» resta titolo, «1. » resta testo, e Invio su di lui va a una riga di corpo. Costo: per ottenere un elenco numerato la riga va prima portata a corpo dal menu Aa, poi si digita il segno. Il cambiamento tocca solo la regola che converte i segni digitati, non la gestione dei titoli.

## Where in the code

lib/ui/editor/rich_text_editing_controller.dart: conversione dei segni digitati dopo ogni modifica (ciclo sulle righe) e gestione di Invio
