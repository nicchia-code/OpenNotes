---
column: done
technical: false
refs:
  - text-line/Title
drift: 6csmm45w
proposal: null
agent: false
created: 2026-10-12T08:51:57.687Z
finished: 2026-10-12T08:55:25.502Z
---
# Fix code to match the Model: Old-format title line keeps its list symbol and Enter below it makes a list item

## What happens

Dopo il caricamento, la prima riga significativa di una nota in formato precedente che era una voce puntata o una casella ha stile Titolo ma conserva il simbolo («• », «○ » o «● »). Se si preme Invio alla fine di quella riga, si crea una nuova voce di elenco e non una riga di corpo.

## What should happen

Il Modello dice che la prima riga significativa riceve lo stile Titolo, e che scegliere «Titolo» dal menu Aa toglie prima il simbolo iniziale. Un titolo quindi non ha simbolo. Invio a fine riga di un'intestazione crea una riga di corpo.

## Chosen option

**Togliere il simbolo quando la riga riceve il Titolo al caricamento**

Il simbolo iniziale della prima riga viene tolto al caricamento, come fa il menu Aa. Il testo resta e Invio sotto il titolo crea una riga di corpo, come nel Modello. Costo: nelle note vecchie la voce perde il simbolo.

## Where in the code

lib/ui/editor/notion_document_editor.dart, ramo di ripiego di _parseContentToBlocks (righe con voci e caselle che usano il primo stile di riga); lib/ui/editor/rich_text_editing_controller.dart, handleEnterKey.
