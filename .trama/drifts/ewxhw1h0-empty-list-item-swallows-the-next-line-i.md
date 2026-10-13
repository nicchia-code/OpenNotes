---
status: resolved
resolution: fix-code
refs:
  - export-markdown-file/Choosing destination
  - requirements/rules#export
proposal: null
task: vmuka7ps
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:25:21.250Z
---
# Empty list item swallows the next line in Markdown export

## What happens

Quando un elemento di lista non ha testo, cioè è solo il simbolo ○, ● o • seguito da un a capo, la conversione per il Markdown unisce a quel simbolo anche la riga successiva: la voce di elenco nel file esportato contiene il testo della riga seguente, e l'a capo tra le due righe sparisce. Succede sia nelle note in testo semplice sia nei paragrafi delle note a blocchi.

## What should happen

La regola dice che il simbolo cambia solo a inizio riga e che il resto della nota resta invariato: la riga successiva deve restare una riga a sé, con il suo testo intatto, anche quando la voce precedente è vuota.

## Fix options

### Consumare solo gli spazi dopo il simbolo

Il simbolo si converte senza prendere gli a capo che seguono: una voce vuota diventa solo `- [ ] ` (o `- `) e la riga successiva resta separata. Modifica piccola, in un solo punto di conversione per i tre simboli; il file esportato contiene una voce vuota in più dove la nota ne aveva una.

### Lasciare il simbolo vuoto così com'è

Una voce senza testo non viene convertita: il simbolo resta com'è nel file, e la riga successiva non cambia. Il file può contenere un simbolo che Markdown non riconosce, ma nessun testo viene toccato. Costa un controllo in più sul simbolo nudo e una riga di regola da aggiungere al requisito.

## Where in the code

lib/core/models/note_model.dart, Note.toMarkdown: l'espressione regolare per ○, ● e • nel ramo del testo semplice e nel ramo dei paragrafi a blocchi
