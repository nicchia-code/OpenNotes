---
status: resolved
resolution: dismissed
refs:
  - text-line/Checked
  - requirements/rules#text-line
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: 7qmreh1i
created: 2026-10-17T08:02:42.082Z
---
# Enter in a checked item: Model and Requirement disagree on the new item

## What happens

Premendo Invio in una voce fatta con testo, la nuova riga è una voce da fare con il cerchio vuoto «○ ».

## What should happen

Il Model indica che la nuova voce resta fatta (Checked), mentre la descrizione e il Requirement dicono che la nuova riga è una voce da fare (○).

## Fix options

### Mantenere la voce da fare e correggere il Model

La nuova riga resta «○ » come dicono la descrizione e il Requirement; la freccia del Model su Checked va corretta a Unchecked.

### Far creare una voce fatta

La nuova riga diventa «● », come indica la freccia del Model; vanno aggiornati descrizione e Requirement.

## Where in the code

lib/ui/editor/rich_text_editing_controller.dart: handleEnterKey, ramo delle voci checklist
