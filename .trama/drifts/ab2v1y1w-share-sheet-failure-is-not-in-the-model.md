---
status: resolved
resolution: fix-code
refs:
  - export-markdown-share/Share sheet open
proposal: null
task: 7mpt99bm
origin: null
critical: false
option: 1
note: null
resolvedBy: fiomlg7l
created: 2026-10-13T05:19:43.064Z
---
# Share sheet failure is not in the Model

## What happens

Se il sistema non riesce ad aprire il foglio di condivisione, l'app non intercetta l'errore: non compare nessun messaggio e la condivisione finisce senza esito, come se la nota non fosse stata condivisa. Il codice non distingue questo caso dagli altri.

## What should happen

Il Model conosce solo due esiti: il foglio viene chiuso e si torna a Idle, senza distinguere tra condivisione completata e annullata. Non dice cosa succede se il foglio non si apre. Nello stesso gruppo di azioni, l'esportazione su file mostra un messaggio di errore quando il salvataggio fallisce, quindi ci si aspetterebbe un trattamento analogo.

## Fix options

### Mostrare un messaggio e tornare a Idle

Il Model aggiunge l'esito «il foglio non si apre»: si mostra un breve messaggio che dice che la nota non è stata condivisa e si torna a Idle. Costa un transition in più nel Diagram e un testo di messaggio da scrivere. L'utente sa che può riprovare.

### Chiudere in silenzio, come ora

Il Model dichiara esplicitamente che se il foglio non si apre la condivisione finisce senza messaggio e torna a Idle. Non cambia il codice. Costo: l'utente non sa perché la nota non è stata condivisa, anche se il problema è raro.

## Where in the code

lib/ui/notes_list/note_actions.dart: ramo della condivisione, chiamata a SharePlus.instance.share, senza gestione dell'errore
