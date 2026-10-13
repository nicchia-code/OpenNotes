---
column: done
technical: false
refs:
  - export-markdown-share/Share sheet open
drift: ab2v1y1w
proposal: null
agent: false
created: 2026-10-13T05:23:24.910Z
finished: 2026-10-13T05:26:21.278Z
---
# Fix code to match the Model: Share sheet failure is not in the Model

## What happens

Se il sistema non riesce ad aprire il foglio di condivisione, l'app non intercetta l'errore: non compare nessun messaggio e la condivisione finisce senza esito, come se la nota non fosse stata condivisa. Il codice non distingue questo caso dagli altri.

## What should happen

Il Model conosce solo due esiti: il foglio viene chiuso e si torna a Idle, senza distinguere tra condivisione completata e annullata. Non dice cosa succede se il foglio non si apre. Nello stesso gruppo di azioni, l'esportazione su file mostra un messaggio di errore quando il salvataggio fallisce, quindi ci si aspetterebbe un trattamento analogo.

## Chosen option

**Mostrare un messaggio e tornare a Idle**

Il Model aggiunge l'esito «il foglio non si apre»: si mostra un breve messaggio che dice che la nota non è stata condivisa e si torna a Idle. Costa un transition in più nel Diagram e un testo di messaggio da scrivere. L'utente sa che può riprovare.

## Where in the code

lib/ui/notes_list/note_actions.dart: ramo della condivisione, chiamata a SharePlus.instance.share, senza gestione dell'errore
