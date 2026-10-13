---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#export
  - export-markdown-file/Idle/user.EXPORT_NOTE_AS_MARKDOWN
proposal: null
task: am3wfofl
origin: null
critical: false
option: 1
note: null
resolvedBy: fiomlg7l
created: 2026-10-13T05:21:15.941Z
---
# Inline bold, italic and strikethrough split by other styles

## What happens

Quando una nota viene esportata, il grassetto, il corsivo o il barrato che coprono più tratti viene spezzato in pezzi, ognuno con i propri asterischi. Succede ogni volta che un altro stile (per esempio il sottolineato, che non viene esportato) cade dentro lo stesso tratto. Il risultato è una sequenza come **ciao ****mondo**: marcatori vicini che il Markdown non legge come un unico grassetto, con spazi dentro i marcatori.

## What should happen

Il Requirement dice che il grassetto è **x**, il corsivo *x* e il barrato ~~x~~, e che il sottolineato non viene esportato. Un tratto in grassetto deve quindi restare un solo blocco di asterischi, anche se parte del testo è sottolineato, e gli spazi non devono stare dentro i marcatori. Il Model non dice nulla di questo dettaglio.

## Fix options

### Unire i tratti con lo stesso stile

Prima di applicare i marcatori, i tratti adiacenti che hanno gli stessi stili vengono uniti, e il sottolineato non conta come confine. Ogni grassetto, corsivo o barrato esce come un solo blocco, come descrive il Requirement. Costo: una modifica piccola alla conversione in Markdown del testo a blocchi, senza cambiare nient'altro.

### Esportare solo gli stili che coprono tutto il tratto

Il grassetto, il corsivo e il barrato vengono scritti solo quando coprono un intero tratto senza confini intermedi; il testo parzialmente in stile esce senza marcatori. Il file è sempre valido Markdown, ma la parte di testo in grassetto o corsivo si perde. Costo: l'esportazione perde parte della formattazione che l'utente vede nell'editor.

## Where in the code

lib/core/models/note_model.dart, Note.toMarkdown: ciclo sui tratti di ogni blocco che applica i marcatori a ciascun tratto separato
