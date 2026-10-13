---
column: done
technical: false
refs:
  - text-line/Heading
  - requirements/rules#text-line
drift: 34jcqykq
proposal: null
agent: false
created: 2026-10-12T07:38:53.802Z
finished: 2026-10-12T07:42:59.890Z
---
# Fix code to match the Model: Enter on a heading line

## What happens

Premendo Invio su una riga di titolo o intestazione con testo, la nuova riga è in stile corpo e il cursore ci finisce, come richiesto. Se invece la riga è vuota (per esempio appena scritto «# »), il nuovo a capo lascia la riga vuota sopra in stile corpo e sposta lo stile di intestazione sulla riga dove si trova il cursore: l'utente continua a scrivere in grande.

## What should happen

Il Model non prevede nessuna transizione di Invio sulle righe di titolo o intestazione. I Requirements dicono che Invio su un titolo o un'intestazione va a capo con la nuova riga in stile corpo, anche quando il cursore è all'inizio di una riga. Quindi anche su una riga vuota il cursore deve finire su una riga in stile corpo.

## Chosen option

**Cursore in corpo anche su riga vuota**

Dopo Invio su una riga di titolo o intestazione il cursore finisce sempre su una riga in stile corpo, anche se la riga di partenza era vuota: la riga di partenza diventa corpo e la nuova riga resta corpo. Il Model non cambia, perché la regola è già scritta nei Requirements. Costo: si tocca solo il ramo della riga vuota e va provato con «# » seguito da Invio.

## Where in the code

lib/ui/editor/rich_text_editing_controller.dart, handleEnterKey (ramo dei titoli e delle intestazioni)
