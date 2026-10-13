---
status: resolved
resolution: fix-code
refs:
  - mobile-navigation/Folders/user.SELECT_TAG
proposal: null
task: 2i7zc3sl
origin: null
critical: false
option: 1
note: null
resolvedBy: 6dq6m1w3
created: 2026-10-12T11:38:34.183Z
---
# Model still describes double tag application in Folders after its Drift was resolved

## What happens

Su mobile, toccando un tag nella schermata Cartelle, il filtro viene applicato una sola volta: la lista mostra le note con quel tag. Il Model dice invece che il tag viene applicato due volte di seguito e il filtro si annulla. La decisione registrata nel Drift precedente (pztqr8es, risolto con il Task 1yah5xzy) è applicare il filtro una volta, ma la descrizione del Model non è stata riscritta.

## What should happen

Il Requirement dell'organizzazione dice che selezionare un tag riporta la vista a Tutte le note filtrata da quel tag. Il Model di Cartelle e le transizioni di note-browser collegate descrivono il doppio passaggio, che annulla il filtro. Il Model dovrebbe descrivere una sola decisione, coerente con il Requirement e con il Drift risolto.

## Fix options

### Describe a single application in the Model

Riscrivere nel Model la transizione da Cartelle verso la lista e le transizioni di note-browser che parlano del doppio passaggio, descrivendo un solo passaggio: il tocco su un tag mostra le note con quel tag. È coerente con la decisione già presa e con il Requirement, e il codice già lo segue. Costo: una Proposal che riscrive il Model di navigazione e di note-browser per questo caso.

### Restore the double application

Riportare il codice al doppio passaggio: il tocco su un tag annulla il filtro, salvo che il tag sia già l'unico selezionato. Coerente con il Model attuale, ma contraddice il Requirement dell'organizzazione, che tratta il tocco su un tag come una selezione, e riapre il comportamento che la decisione precedente aveva voluto correggere.

## Where in the code

Schermata Cartelle su mobile: il tocco su un tag.
