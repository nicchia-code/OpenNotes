---
column: done
technical: false
refs:
  - export-markdown-file/Choosing destination
  - requirements/rules#export
drift: ewxhw1h0
proposal: null
agent: false
created: 2026-10-12T07:38:53.690Z
finished: 2026-10-12T07:46:33.826Z
---
# Fix code to match the Model: Empty list item swallows the next line in Markdown export

## What happens

Quando un elemento di lista non ha testo, cioè è solo il simbolo ○, ● o • seguito da un a capo, la conversione per il Markdown unisce a quel simbolo anche la riga successiva: la voce di elenco nel file esportato contiene il testo della riga seguente, e l'a capo tra le due righe sparisce. Succede sia nelle note in testo semplice sia nei paragrafi delle note a blocchi.

## What should happen

La regola dice che il simbolo cambia solo a inizio riga e che il resto della nota resta invariato: la riga successiva deve restare una riga a sé, con il suo testo intatto, anche quando la voce precedente è vuota.

## Chosen option

**Consumare solo gli spazi dopo il simbolo**

Il simbolo si converte senza prendere gli a capo che seguono: una voce vuota diventa solo `- [ ] ` (o `- `) e la riga successiva resta separata. Modifica piccola, in un solo punto di conversione per i tre simboli; il file esportato contiene una voce vuota in più dove la nota ne aveva una.

## Where in the code

lib/core/models/note_model.dart, Note.toMarkdown: l'espressione regolare per ○, ● e • nel ramo del testo semplice e nel ramo dei paragrafi a blocchi
