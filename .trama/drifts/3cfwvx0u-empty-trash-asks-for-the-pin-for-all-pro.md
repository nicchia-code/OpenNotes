---
status: resolved
resolution: dismissed
refs:
  - note/In trash/user.EMPTY_TRASH
  - requirements/rules#note
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: null
created: 2026-10-12T18:44:37.646Z
---
# Empty trash asks for the PIN for all protected trashed notes, the Model only for the visible ones

## What happens

Svuotando il cestino, il sistema chiede il PIN se nel cestino c'è almeno una nota protetta, anche quando la ricerca o un filtro la nasconde. Una nota protetta non visibile non viene quindi eliminata senza PIN.

## What should happen

Il Model chiede il PIN solo se una delle note mostrate nella vista Cestino è protetta: una nota protetta nascosta dalla ricerca verrebbe eliminata senza PIN. Il Requirement sulle regole delle note dice invece che eliminare definitivamente una nota protetta richiede il PIN corretto, quindi le due fonti non coincidono.

## Fix options

### Ask the PIN for every protected note in the trash

Il PIN è richiesto ogni volta che nel cestino c'è una nota protetta, anche se la ricerca la nasconde. Rispetta il Requirement sulla cancellazione definitiva. Costo: l'utente può dover inserire il PIN per note che non vede, e nel Model la frase sulle note mostrate va cambiata in tutte le note nel cestino.

### Ask the PIN only for the notes shown

Il PIN è chiesto solo se la vista corrente mostra una nota protetta; le protette nascoste da ricerca o filtri vengono eliminate senza PIN. Segue il Model alla lettera, ma contraddice il Requirement sulla cancellazione definitiva di una nota protetta: il Requirement andrebbe cambiato o questa eccezione accettata esplicitamente.

## Where in the code

Svuotamento del cestino: controllo delle note protette nel provider delle note e nei due elenchi (desktop e mobile).
