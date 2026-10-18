---
status: resolved
resolution: proposal
refs:
  - text-line/Numbered item
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: famz2y49
created: 2026-10-18T18:31:37.704Z
---
# Plain-text and block lines with a number, quote or fence sign load as body text

## What happens

Una riga che comincia con un numero e un punto, con una citazione o con tre apici inversi, ma senza uno stile di riga salvato, si apre come riga di corpo con il segno nel testo. Diventa voce numerata, citazione o monospazio solo alla prima modifica del testo della sezione.

## What should happen

Il Model dice che il tipo di una riga viene anche dal simbolo con cui comincia e che la voce numerata, la citazione e il monospazio restano dello stesso tipo quando la nota viene riaperta. Il Requirement dice che al caricamento vale lo stile salvato, in mancanza il tipo del blocco per la prima riga, e che il testo semplice converte solo intestazioni, caselle ed elenchi puntati.

## Fix options

### Riconoscere il tipo dal segno al caricamento

Al caricamento, anche per il testo semplice e per i blocchi senza stile salvato, una riga che comincia con numero e punto, con una citazione o con tre apici inversi prende il tipo corrispondente e il segno esce dal testo come alla digitazione. Il Model resta invariato. Il Requirement sul caricamento va aggiornato per dire che il segno determina il tipo anche senza stile salvato. Costo: note scritte da altre versioni dell'app possono cambiare aspetto alla prima apertura.

### Caricare come corpo finché non si modifica

Al caricamento queste righe restano di corpo con il segno nel testo, come oggi, e il Requirement resta invariato. Il Model va corretto per dire che il segno determina il tipo solo alla digitazione, non al caricamento. Costo: una nota riaperta mostra le voci numerate, le citazioni e i monospazi come testo semplice finché l'utente non modifica la sezione, e cambia aspetto alla prima modifica.

## Where in the code

lib/ui/editor/notion_document_editor.dart: _parseContentToBlocks (block-format and plain-text branches); lib/ui/editor/rich_text_editing_controller.dart: _convertMarkdownShortcuts, which runs only after a text change
