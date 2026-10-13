---
status: resolved
resolution: fix-code
refs:
  - text-line/Bulleted item
  - text-line/Checklist item
  - requirements/rules#text-line
proposal: null
task: rnrmyd4r
origin: null
critical: false
option: 1
note: null
resolvedBy: psazi867
created: 2026-10-12T16:51:37.266Z
---
# Backspace right after an indented bullet or checklist symbol: Model and Requirement disagree on the caret position

## What happens

Con il cursore subito dopo il simbolo di una voce rientrata, ma prima dello spazio che lo segue, il Backspace cancella il simbolo: la riga resta rientrata ma diventa testo semplice, e il rientro non scende. Solo con il cursore dopo il simbolo e lo spazio il Backspace riduce il rientro di un livello e lascia la voce puntata o da fare.

## What should happen

Il Model dice che il Backspace subito dopo il simbolo, o il cerchio, di una voce rientrata riduce il rientro di un livello e lascia la voce com'è. Il Requirement dice invece «subito dopo il prefisso», cioè dopo il simbolo e lo spazio. Le due regole fissano posizioni diverse del cursore, e il codice segue il Requirement.

## Fix options

### Posizione del Model: dopo il simbolo

Il Backspace riduce il rientro anche quando il cursore è tra il simbolo e lo spazio, come scrive il Model, e la voce resta puntata o da fare. Il Requirement va riscritto con «subito dopo il simbolo». Costo: la regola del Requirement cambia e va provata con una voce rientrata, cursore dopo il simbolo.

### Posizione del Requirement: dopo il prefisso

Il Backspace riduce il rientro solo dopo il simbolo e lo spazio, come scrive il Requirement. Il Model va riscritto con «subito dopo il prefisso». Tra il simbolo e lo spazio il simbolo viene cancellato come oggi. Costo: si cambia solo il testo del Model, nessun codice.

### Entrambe le posizioni

Il Backspace riduce il rientro in ogni punto del prefisso, tra il simbolo e lo spazio compreso, così Model e Requirement sono entrambi rispettati. Costo: il Requirement va chiarito e il Backspace in quella posizione cambia comportamento in tutte le voci rientrate.

## Where in the code

lib/ui/editor/rich_text_editing_controller.dart, handleBackspaceKey (confronto con il prefisso intero)
