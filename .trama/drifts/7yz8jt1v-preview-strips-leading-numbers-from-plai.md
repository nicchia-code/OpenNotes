---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#note
proposal: null
task: n9a9kttv
origin: null
critical: false
option: 1
note: null
resolvedBy: p136jufl
created: 2026-10-12T08:02:11.235Z
---
# Preview strips leading numbers from plain-text lines

## What happens

Nelle note di testo semplice l'anteprima toglie anche i numeri che aprono una frase: «100 euro» diventa «euro», «2024 è l'anno» diventa «è l'anno», «2.5 kg» diventa «kg». Le note a blocchi non hanno questo problema e mostrano il testo intero.

## What should happen

La Requirement dice che l'anteprima toglie i marcatori iniziali di intestazione, elenco, citazione e numerazione. Il marcatore di numerazione è il numero di una voce di elenco, come «1.» o «1)», non un numero che fa parte del testo.

## Fix options

### Togliere solo i numeri di elenco

Dall'inizio della riga si tolgono solo i marcatori di elenco numerato, cioè un numero seguito da punto o parentesi e spazio, come «1.» o «1)». I numeri che aprono una frase restano. Costo: poche righe di codice da cambiare, nessun effetto sulle note a blocchi o sulla titolazione.

### Lasciare il numero nelle voci

L'anteprima di un elenco numerato mostra il numero: «1. Comprare il pane». Costo: anteprime un po' più lunghe e meno pulite per gli elenchi, e un marcatore in più da leggere; la Requirement resta com'è.

### Togliere ogni numero iniziale

Resta il comportamento attuale: ogni numero all'inizio della riga viene tolto. Costo: «100 euro» nell'anteprima diventa «euro»; la Requirement va riscritta per dire che il primo numero della riga è tolto.

## Where in the code

lib/core/models/note_model.dart (extractSnippet, ramo di testo semplice: la regex che toglie i marcatori iniziali)
