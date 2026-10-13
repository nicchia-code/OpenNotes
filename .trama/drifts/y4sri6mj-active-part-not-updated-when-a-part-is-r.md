---
status: resolved
resolution: fix-code
refs:
  - note-editor/Open/user.PICK_BLOCK_MENU_ITEM
proposal: null
task: alc5nkad
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:29:51.386Z
---
# Active part not updated when a part is removed

## What happens

La parte attiva è ricordata come posizione nell'elenco delle parti. Quando una parte viene tolta senza che il cursore passi a un'altra, la posizione resta la stessa e punta alla parte che ora sta in quel posto. Dal menu rapido, «Tabella» toglie la sezione e mette la tabella dopo la parte che seguiva, non al suo posto. Anche la rimozione di un'immagine lascia la posizione sbagliata: i comandi della barra agiscono poi sulla parte sbagliata.

## What should happen

Il Modello dice che la parte attiva è quella con il focus, altrimenti l'ultima che lo ha avuto. «Tabella» elimina la sezione di testo e inserisce una tabella; il Modello non dice dove. La tabella dovrebbe prendere il posto della sezione tolta, e dopo una rimozione la parte attiva deve restare quella giusta.

## Fix options

### Ricordare la parte attiva come riferimento

La parte attiva resta legata alla parte stessa, anche quando ne vengono tolte altre prima. «Tabella» mette la tabella dove era la sezione tolta. Costo: un riferimento alla parte al posto dell'indice, con qualche riga in più.

### Ricalcolare la posizione a ogni rimozione

Ogni volta che una parte viene tolta, la posizione attiva viene aggiornata. Stesso risultato con il codice attuale. Costo: va ricordato in ogni punto che toglie parti (immagine, unione di sezioni, tabella dal menu), ed è facile dimenticarne uno.

## Where in the code

lib/ui/editor/notion_document_editor.dart: _activeBlockIndex; rimozioni in _buildImageBlock (pulsante di rimozione) e _buildSlashMenu (voce «Tabella»); insertTable usa la posizione attiva.
