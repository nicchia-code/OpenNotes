---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#note-content-save
proposal: null
task: 1frtuffr
origin: null
critical: false
option: 1
note: null
resolvedBy: 2di39ebu
created: 2026-10-13T12:22:56.951Z
---
# Tags are not sorted alphabetically when they contain accented letters

## What happens

Quando una nota viene salvata, i suoi tag entrano nell'elenco in ordine di codice dei caratteri, non in ordine alfabetico. Con le lettere accentate il risultato è evidente: un tag come «caffè» finisce dopo «zen», e «città» dopo tutte le parole che iniziano con una lettera senza accento. Per i tag senza lettere accentate l'ordine è corretto, e i duplicati e le maiuscole sono già gestiti.

## What should happen

Il Requirement dice che i tag si salvano in minuscolo, senza duplicati e in ordine alfabetico. Con i tag che hanno lettere accentate l'ordine salvato non è alfabetico, quindi la regola non è rispettata. Non si può seguire la regola alla lettera con l'ordine attuale, perché il confronto usa il codice dei caratteri e non l'ordine che un lettore si aspetta.

## Fix options

### Ordinare i tag con un confronto alfabetico sensibile agli accenti

Il salvataggio ordina i tag come un lettore si aspetta: «caffè» viene prima di «zen» e «città» tra le parole in c. Le note già salvate si riordinano alla prossima consegna. Costo: un confronto un po' più costoso di quello attuale, trascurabile per le poche decine di tag di una nota.

### Precisare nel Requirement che l'ordine è quello dei caratteri Unicode

Il codice resta com'è e il Requirement dice esplicitamente che l'ordine è quello dei caratteri Unicode, con le lettere accentate dopo la z. Costo: la regola diventa meno leggibile per l'utente, e la scelta va presa e scritta nel Requirement.

## Where in the code

lib/core/models/note_model.dart (extractTagsFromContent, ordinamento finale dei tag)
