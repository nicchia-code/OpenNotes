---
status: resolved
resolution: fix-code
refs:
  - note-editor/Open/note-access.RELOCKED
proposal: null
task: 4v9nq4kk
origin: null
critical: false
option: 1
note: null
resolvedBy: uo2rau9q
created: 2026-10-17T12:49:59.201Z
---
# Waiting edit when a cloud lock hides the open note: the Model has no exit for it

## What happens

Se una versione arrivata dal cloud mette il lucchetto alla nota aperta mentre una modifica di testo è ancora in attesa, la nota si nasconde subito con il segnaposto, ma l'attesa non si ferma: dopo 300 ms il documento nascosto viene consegnato con quella modifica. Finché la modifica aspetta, una nuova versione remota non viene caricata, come nello stato Aperto. Il lucchetto del cloud non passa dai comandi della nota, quindi non c'è una consegna immediata prima di nascondere la nota.

## What should happen

Il Modello dice che il lucchetto arrivato dal cloud porta a Protetta, ma nello stato Protetta non descrive né la consegna della modifica in attesa né la condizione di attesa per la versione remota: lì la versione remota viene caricata senza eccezioni. Il Requisito fissa l'attesa di 300 ms e dice che una versione remota non si carica con modifiche in attesa, senza distinguere lo stato Aperto dallo stato Protetto. Quindi per questo caso il Modello non dice cosa succede al testo digitato.

## Fix options

### Deliver the waiting edit before hiding the note

Quando il cloud mette il lucchetto, la modifica in attesa viene consegnata subito, prima di nascondere la nota, come fanno i comandi sulla nota. Costo: il salvataggio avviene senza attesa solo in questo caso; per la versione remota non cambia nulla.

### Let the remote version replace the waiting edit

Quando il cloud mette il lucchetto, la modifica in attesa viene scartata e la versione remota viene caricata, come il Modello dice per la versione remota nello stato Protetto. Costo: il testo digitato nei 300 ms prima dell'arrivo della versione del cloud va perso senza avviso.

## Where in the code

lib/core/state/notes_provider.dart: ascoltatore delle modifiche remote, che chiama relockNote senza consegnare il testo in attesa; lib/ui/editor/notion_document_editor.dart: didUpdateWidget, ramo della versione remota che salta il caricamento quando c'è una modifica in attesa
