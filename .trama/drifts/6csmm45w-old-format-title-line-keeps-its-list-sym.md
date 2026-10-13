---
status: resolved
resolution: fix-code
refs:
  - text-line/Title
proposal: null
task: 5yapmsqs
origin: null
critical: false
option: 1
note: null
resolvedBy: ytpmwbt8
created: 2026-10-12T08:50:17.272Z
---
# Old-format title line keeps its list symbol and Enter below it makes a list item

## What happens

Dopo il caricamento, la prima riga significativa di una nota in formato precedente che era una voce puntata o una casella ha stile Titolo ma conserva il simbolo («• », «○ » o «● »). Se si preme Invio alla fine di quella riga, si crea una nuova voce di elenco e non una riga di corpo.

## What should happen

Il Modello dice che la prima riga significativa riceve lo stile Titolo, e che scegliere «Titolo» dal menu Aa toglie prima il simbolo iniziale. Un titolo quindi non ha simbolo. Invio a fine riga di un'intestazione crea una riga di corpo.

## Fix options

### Togliere il simbolo quando la riga riceve il Titolo al caricamento

Il simbolo iniziale della prima riga viene tolto al caricamento, come fa il menu Aa. Il testo resta e Invio sotto il titolo crea una riga di corpo, come nel Modello. Costo: nelle note vecchie la voce perde il simbolo.

### Tenere il simbolo e far creare a Invio una riga di corpo

Il simbolo resta visibile nel titolo, ma Invio su una riga con stile Titolo crea sempre una riga di corpo, anche se la riga ha un simbolo di elenco. Costo: resta nel titolo un segno che il Modello non prevede.

### Lasciare com'è e precisare il Modello

Il Modello dichiara che il titolo caricato può avere un simbolo di elenco o una casella, e che Invio segue le regole degli elenchi. Nessun cambio al codice. Costo: il titolo mostra un simbolo, scelta da fissare nel Modello.

## Where in the code

lib/ui/editor/notion_document_editor.dart, ramo di ripiego di _parseContentToBlocks (righe con voci e caselle che usano il primo stile di riga); lib/ui/editor/rich_text_editing_controller.dart, handleEnterKey.
