---
status: resolved
resolution: proposal
refs:
  - text-line/Unchecked/user.TAP_CHECKBOX
  - requirements/rules#text-line
proposal: null
task: null
origin: null
previous: wkoe92qh
critical: false
option: null
note: null
resolvedBy: 1mjjves7
created: 2026-10-17T09:49:49.501Z
---
# Requirement says a checklist tap counts up to the first letter of the item, the Model says the circle only

## What happens

Il tocco su una voce di checklist cambia la spunta solo se cade sul cerchio o sullo spazio che lo segue (offset del prefisso più uno, come da toggleChecklistAtOffset). Il tocco sulle lettere del testo sposta solo il cursore. Il Requirement invece dice che il tocco conta entro il prefisso più un carattere, cioè fino alla prima lettera del testo: il codice e il Requirement non coincidono.

## What should happen

Il Model (sezione Checklist item, TAP_CHECKBOX) dice che la spunta cambia solo se il tocco cade sul cerchio o sul carattere subito dopo. La decisione di wkoe92qh è la stessa: il tocco sul testo non deve cambiare la spunta. Il Requirement «requirements/rules#text-line» dice invece «entro il prefisso più un carattere», che include la prima lettera e quindi contraddice sia il Model sia wkoe92qh.

## Fix options

### Rewrite the Requirement to match the Model

Il Requirement dice che il tocco conta sul cerchio o sul carattere subito dopo, come il Model e il codice. Costo: una modifica al testo dei Requirements, nessun cambio di codice.

### Keep the Requirement and widen the tap area

Il tocco sulla prima lettera cambia la spunta come dice il Requirement. Costo: torna il problema di wkoe92qh, cioè modificare la voce tocando il testo per spostare il cursore.

## Where in the code

lib/ui/editor/rich_text_editing_controller.dart, toggleChecklistAtOffset (soglia circleAt..circleAt+1); lib/ui/editor/notion_document_editor.dart, onTap del campo di testo che chiama toggleChecklistAtOffset.
