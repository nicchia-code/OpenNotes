---
status: resolved
resolution: fix-code
refs:
  - text-line/Heading
  - requirements/rules#text-line
proposal: null
task: nes6ispf
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:30:33.150Z
---
# Enter on a heading line

## What happens

Premendo Invio su una riga di titolo o intestazione con testo, la nuova riga è in stile corpo e il cursore ci finisce, come richiesto. Se invece la riga è vuota (per esempio appena scritto «# »), il nuovo a capo lascia la riga vuota sopra in stile corpo e sposta lo stile di intestazione sulla riga dove si trova il cursore: l'utente continua a scrivere in grande.

## What should happen

Il Model non prevede nessuna transizione di Invio sulle righe di titolo o intestazione. I Requirements dicono che Invio su un titolo o un'intestazione va a capo con la nuova riga in stile corpo, anche quando il cursore è all'inizio di una riga. Quindi anche su una riga vuota il cursore deve finire su una riga in stile corpo.

## Fix options

### Cursore in corpo anche su riga vuota

Dopo Invio su una riga di titolo o intestazione il cursore finisce sempre su una riga in stile corpo, anche se la riga di partenza era vuota: la riga di partenza diventa corpo e la nuova riga resta corpo. Il Model non cambia, perché la regola è già scritta nei Requirements. Costo: si tocca solo il ramo della riga vuota e va provato con «# » seguito da Invio.

### Descrivere Invio nel Model

Si aggiunge al Model che Invio su una riga di titolo o intestazione va a capo con la riga nuova in stile corpo, e si decide il caso della riga vuota. Il comportamento del codice non cambia per le righe con testo. Costo: una transizione in più nel Diagramma da mantenere, e la riga vuota va comunque corretta nel codice se si sceglie questa strada.

## Where in the code

lib/ui/editor/rich_text_editing_controller.dart, handleEnterKey (ramo dei titoli e delle intestazioni)
