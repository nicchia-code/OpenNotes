---
column: done
technical: true
refs:
  - requirements/rules#note
drift: 7yz8jt1v
proposal: null
agent: false
created: 2026-10-12T08:09:28.378Z
finished: 2026-10-12T08:10:37.683Z
---
# Fix code to match the Requirements: Preview strips leading numbers from plain-text lines

## What happens

Nelle note di testo semplice l'anteprima toglie anche i numeri che aprono una frase: «100 euro» diventa «euro», «2024 è l'anno» diventa «è l'anno», «2.5 kg» diventa «kg». Le note a blocchi non hanno questo problema e mostrano il testo intero.

## What should happen

La Requirement dice che l'anteprima toglie i marcatori iniziali di intestazione, elenco, citazione e numerazione. Il marcatore di numerazione è il numero di una voce di elenco, come «1.» o «1)», non un numero che fa parte del testo.

## Chosen option

**Togliere solo i numeri di elenco**

Dall'inizio della riga si tolgono solo i marcatori di elenco numerato, cioè un numero seguito da punto o parentesi e spazio, come «1.» o «1)». I numeri che aprono una frase restano. Costo: poche righe di codice da cambiare, nessun effetto sulle note a blocchi o sulla titolazione.

## Where in the code

lib/core/models/note_model.dart (extractSnippet, ramo di testo semplice: la regex che toglie i marcatori iniziali)
