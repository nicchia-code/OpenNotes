---
column: done
technical: false
refs:
  - mobile-navigation/Folders/user.SELECT_TAG
drift: null
proposal: null
agent: false
created: 2026-10-12T11:38:29.857Z
finished: 2026-10-12T13:54:24.698Z
---
# Fix code to match the Model: Tapping the only selected tag in Folders clears the filter

## What happens

Su mobile, toccando nella schermata Cartelle un tag che è già l'unico tag selezionato, il filtro si annulla e la lista mostra tutte le note senza filtro.

## What should happen

Il Model (mobile-navigation, Cartelle, user.SELECT_TAG) dice che il filtro resta attivo quando quel tag era già l'unico selezionato: la lista deve mostrare le note con quel tag. Il Requirement dell'organizzazione dice che selezionare un tag riporta la vista a Tutte le note filtrata da quel tag. Questo vale qualunque sia la correzione scelta per il doppio passaggio (Drift collegato): con una sola applicazione o con due, il caso del tag già unico resta filtrato.

## Where in the code

Schermata Cartelle su mobile: il tocco sul tag usa la stessa selezione del tag della barra laterale desktop, che alterna il tag quando è l'unico selezionato. Il tocco da Cartelle non deve alternare; il comportamento della barra laterale desktop resta invariato.
