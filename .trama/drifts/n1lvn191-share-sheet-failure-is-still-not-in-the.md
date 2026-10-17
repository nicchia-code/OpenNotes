---
status: resolved
resolution: proposal
refs:
  - export-markdown-share/Share sheet open
proposal: null
task: null
origin: null
previous: ab2v1y1w
critical: false
option: null
note: null
resolvedBy: uo2rau9q
created: 2026-10-17T12:45:15.665Z
---
# Share sheet failure is still not in the Model after its Drift was resolved

## What happens

Se il sistema non riesce ad aprire il foglio di condivisione, l'app mostra un messaggio che dice che la nota non è stata condivisa e la condivisione si chiude senza esito. Il Model non descrive questo esito: conosce solo la chiusura del foglio, che porta a Idle.

## What should happen

Il Model dice solo che il foglio chiuso riporta a Idle, senza distinguere condivisione completata e annullata, e non dice cosa succede se il foglio non si apre. La Drift ab2v1y1w è stata risolta scegliendo di mostrare un messaggio e tornare a Idle, e la Proposal fiomlg7l è stata approvata, ma non ha modificato alcun file del Model: l'esito non è mai entrato nel Model.

## Fix options

### Mantenere il messaggio e allineare il Model

Il codice non cambia: il messaggio resta e la condivisione torna a Idle. Il Model va allineato con una Proposal che aggiunge l'esito «il foglio non si apre». Costo: una Proposal in più, e fino ad allora il Model resta incompleto.

### Tornare al silenzio descritto dal Model

Il messaggio viene tolto: se il foglio non si apre la condivisione finisce senza esito, come dice il Model. Costo: l'utente non sa perché la nota non è stata condivisa, mentre l'esportazione su file mostra un errore in un caso analogo.

## Where in the code

lib/ui/notes_list/note_actions.dart: ramo della condivisione, chiamata a SharePlus.instance.share, con il blocco catch che mostra la SnackBar «Nota non condivisa»
