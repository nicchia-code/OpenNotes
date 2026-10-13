---
status: resolved
resolution: fix-code
refs:
  - requirements/data#note-editor
proposal: null
task: ee36v6x5
origin: null
critical: false
option: 1
note: null
resolvedBy: psazi867
created: 2026-10-12T17:03:28.890Z
---
# Saved quote, monospace and numbered line styles: the Requirement still forbids them

## What happens

L'editor tiene la citazione, il monospazio e la voce numerata come tipi di riga: una riga che ha già il segno mantiene il suo tipo, il tipo viene salvato insieme al testo e riaprendo la nota la riga resta com'è. Il contenuto salvato contiene quindi stili di riga che il Requirement non elenca.

## What should happen

Il Requirement dice che l'editor salva come stili di riga solo titolo, intestazioni e corpo, e che citazione, monospazio, voce puntata e voce numerata arrivano solo da contenuti precedenti e vengono convertiti al caricamento. Il Drift risolto dalla Task d80f2efr ha scelto di salvare anche questi tipi di riga e di riscrivere il Requirement, ma il Requirement non è ancora stato riscritto e nessuna Proposal è aperta per farlo.

## Fix options

### Update the Requirement to the chosen resolution

Il Requirement dell'editor viene riscritto perché gli stili di riga salvati includano anche citazione, monospazio e voce numerata, come scelto nel Drift risolto. Il formato dei dati e l'aspetto restano quelli di oggi. Costa: una Proposal che riscrive il Requirement e tre stili in più nei dati salvati.

### Convert these lines to body text when a note loads

Al caricamento citazione, monospazio e voce numerata diventano righe di corpo con il loro segno, come dice il Requirement, e il loro tipo non viene più salvato. Anche il Model delle righe di testo, che oggi dice che questi tipi restano alla riapertura, va cambiato. Costa: la riga perde il suo tipo a ogni apertura e due descrizioni vanno riscritte.

## Where in the code

lib/ui/editor/notion_document_editor.dart (caricamento dei blocchi di testo: rami per citazione, monospazio e voce numerata, che tengono il tipo se il segno è già presente).
