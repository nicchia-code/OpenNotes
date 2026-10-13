---
status: resolved
resolution: fix-code
refs:
  - mobile-navigation/Folders/user.SELECT_TAG
proposal: null
task: 1yah5xzy
origin: null
critical: false
option: 1
note: null
resolvedBy: m16unv7j
created: 2026-10-12T11:22:17.604Z
---
# Tapping a tag in Folders applies the filter twice and cancels it

## What happens

Su mobile, toccando un tag nella schermata Cartelle, il tag viene applicato due volte di seguito: la seconda applicazione annulla la prima e la lista mostra tutte le note senza filtro. Il filtro resta attivo solo se quel tag era già l'unico selezionato.

## What should happen

Il Model della navigazione mobile (Cartelle, user.SELECT_TAG) descrive questo doppio passaggio come comportamento voluto. Il Requirement dell'organizzazione (regole delle viste) dice invece che selezionare un tag, anche in aggiunta, riporta la vista a Tutte le note filtrata da quel tag: toccare un tag è una selezione. Non si possono seguire entrambi: il tocco o applica il filtro o non lo applica.

## Fix options

### Apply the tag filter once

Il tocco su un tag dalla schermata Cartelle applica il filtro una sola volta: la lista mostra le note con quel tag. Allinea il codice e il Model al Requirement. Costo: si toglie una delle due applicazioni e il Model del navigatore va riscritto per questo caso.

### Keep the cancel and change the Requirement

Il tocco su un tag dalla schermata Cartelle continua ad annullare il filtro e la lista mostra tutte le note. Il Requirement dell'organizzazione va riscritto con un'eccezione per la schermata Cartelle. Costo: il tocco sul tag in quella schermata non serve a filtrare e resta un'eccezione da spiegare all'utente e agli sviluppatori.

### Open the list without the tag filter

Il tocco su un tag dalla schermata Cartelle apre la lista senza filtro, e il filtro si sceglie toccando il tag nella lista. Costo: un tocco in più per filtrare per tag da mobile; il Model e il Requirement restano da riscrivere in parte per la schermata Cartelle.

## Where in the code

Schermata Cartelle su mobile: la selezione del tag è chiamata sia nella schermata Cartelle sia nella shell mobile.
