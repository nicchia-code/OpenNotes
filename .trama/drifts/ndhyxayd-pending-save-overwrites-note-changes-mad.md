---
status: resolved
resolution: fix-code
refs:
  - note-content-save/Waiting
proposal: null
task: temjetjp
origin: null
critical: false
option: 1
note: null
resolvedBy: p136jufl
created: 2026-10-12T08:02:11.094Z
---
# Pending save overwrites note changes made during the wait

## What happens

Se mentre la modifica di una nota è in attesa di essere scritta la nota viene fissata, spostata, messa nel cestino o ripristinata, protetta o sbloccata, la scrittura finale riporta la nota com'era prima di quel comando: il cambiamento sparisce circa mezzo secondo dopo. Una nota già nel cestino torna nell'elenco, e una nota eliminata definitivamente in quella finestra ricompare.

## What should happen

Il Modello dice che la scrittura salva la nota con il nuovo contenuto e non dice cosa accade agli altri cambiamenti fatti nel frattempo. I comandi dell'elenco (fissaggio, spostamento, cestino, protezione, eliminazione) hanno un effetto proprio nel Modello, quindi la scrittura pendente non dovrebbe annullarlo. Il Modello non dice quale dei due deve valere.

## Fix options

### Scrivere solo il contenuto

La scrittura finale aggiorna solo contenuto, titolo, tag, anteprima e data di modifica sulla nota com'è salvata in quel momento; fissaggio, cartella, cestino e protezione restano come l'ultimo comando li ha lasciati. Costo: una lettura della nota prima della scrittura, e nel Modello va scritto che la scrittura non riporta i campi della nota.

### Consegnare prima la modifica in attesa

Ogni comando dell'elenco su una nota con una modifica in attesa scrive prima quella modifica, poi esegue il comando. Costo: lo stato di attesa riceve queste uscite verso Inattivo, come già previsto per i comandi dell'editor, e la scrittura può avvenire prima dei 400 ms previsti.

### Lasciare il comportamento attuale

La scrittura riscrive la nota com'era alla consegna del contenuto. Costo: un comando dato entro circa 700 ms dall'ultima battuta viene perso, e una nota appena protetta può tornare sbloccata senza che nessuno lo noti.

## Where in the code

lib/core/state/notes_provider.dart (updateNoteContent, il timer salva la nota catturata alla consegna); lib/core/services/database_service.dart (upsertNote sostituisce la riga intera)
