---
column: done
technical: false
refs:
  - mobile-navigation/Folders/user.SELECT_TAG
drift: pztqr8es
proposal: null
agent: false
created: 2026-10-12T11:27:34.863Z
finished: 2026-10-12T11:28:53.671Z
---
# Fix code to match the Model: Tapping a tag in Folders applies the filter twice and cancels it

## What happens

Su mobile, toccando un tag nella schermata Cartelle, il tag viene applicato due volte di seguito: la seconda applicazione annulla la prima e la lista mostra tutte le note senza filtro. Il filtro resta attivo solo se quel tag era già l'unico selezionato.

## What should happen

Il Model della navigazione mobile (Cartelle, user.SELECT_TAG) descrive questo doppio passaggio come comportamento voluto. Il Requirement dell'organizzazione (regole delle viste) dice invece che selezionare un tag, anche in aggiunta, riporta la vista a Tutte le note filtrata da quel tag: toccare un tag è una selezione. Non si possono seguire entrambi: il tocco o applica il filtro o non lo applica.

## Chosen option

**Apply the tag filter once**

Il tocco su un tag dalla schermata Cartelle applica il filtro una sola volta: la lista mostra le note con quel tag. Allinea il codice e il Model al Requirement. Costo: si toglie una delle due applicazioni e il Model del navigatore va riscritto per questo caso.

## Where in the code

Schermata Cartelle su mobile: la selezione del tag è chiamata sia nella schermata Cartelle sia nella shell mobile.
