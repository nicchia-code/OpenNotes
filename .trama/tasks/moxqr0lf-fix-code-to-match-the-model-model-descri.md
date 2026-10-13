---
column: done
technical: false
refs:
  - mobile-navigation/Folders/user.SELECT_TAG
drift: sf0xiv1j
proposal: null
agent: false
created: 2026-10-12T11:53:12.025Z
finished: 2026-10-12T13:56:52.772Z
---
# Fix code to match the Model: Model describes double tag application in Folders, contrary to Requirement

## What happens

Toccando un tag nella schermata Cartelle su mobile, il filtro viene applicato una sola volta: la lista mostra le note con quel tag. Il codice segue la decisione del Drift precedente e il Requirement di organizzazione.

## What should happen

Il Model dice che il tag viene applicato due volte di seguito, quindi il filtro si annulla e la lista mostra tutte le note. Questo contraddice il Requirement, secondo cui selezionare un tag riporta la vista a Tutte le note filtrata da quel tag. Il Model non può essere implementato come scritto senza violare il Requirement.

## Chosen option

**Describe a single application**

Riscrivere nel Model la transizione da Cartelle verso la lista e le transizioni di note-browser che descrivono il doppio passaggio, lasciando un solo passaggio: il tocco su un tag mostra le note con quel tag. Coerente con il Requirement e con il codice attuale.

## Where in the code

lib/core/state/notes_provider.dart; lib/ui/mobile/mobile_folders_screen.dart
