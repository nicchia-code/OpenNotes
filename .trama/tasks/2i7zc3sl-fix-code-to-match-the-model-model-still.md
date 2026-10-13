---
column: done
technical: false
refs:
  - mobile-navigation/Folders/user.SELECT_TAG
drift: 9wkbxzx4
proposal: null
agent: false
created: 2026-10-12T11:44:40.875Z
finished: 2026-10-12T16:27:28.510Z
---
# Fix code to match the Model: Model still describes double tag application in Folders after its Drift was resolved

## What happens

Su mobile, toccando un tag nella schermata Cartelle, il filtro viene applicato una sola volta: la lista mostra le note con quel tag. Il Model dice invece che il tag viene applicato due volte di seguito e il filtro si annulla. La decisione registrata nel Drift precedente (pztqr8es, risolto con il Task 1yah5xzy) è applicare il filtro una volta, ma la descrizione del Model non è stata riscritta.

## What should happen

Il Requirement dell'organizzazione dice che selezionare un tag riporta la vista a Tutte le note filtrata da quel tag. Il Model di Cartelle e le transizioni di note-browser collegate descrivono il doppio passaggio, che annulla il filtro. Il Model dovrebbe descrivere una sola decisione, coerente con il Requirement e con il Drift risolto.

## Chosen option

**Describe a single application in the Model**

Riscrivere nel Model la transizione da Cartelle verso la lista e le transizioni di note-browser che parlano del doppio passaggio, descrivendo un solo passaggio: il tocco su un tag mostra le note con quel tag. È coerente con la decisione già presa e con il Requirement, e il codice già lo segue. Costo: una Proposal che riscrive il Model di navigazione e di note-browser per questo caso.

## Where in the code

Schermata Cartelle su mobile: il tocco su un tag.
