---
column: done
technical: false
refs:
  - editor-suggestions/Hidden/user.OPEN_BLOCK_MENU
  - requirements/rules#editor-suggestions
drift: jzj06sro
proposal: null
agent: false
created: 2026-10-12T17:14:49.817Z
finished: 2026-10-12T17:38:57.390Z
---
# Fix code to match the Model: Block menu opened from the toolbar with no text section focused

## What happens

Sul telefono il pulsante **Menu blocchi** apre il menu anche quando nessuna sezione di testo ha il focus, cioè con la tastiera chiusa: il menu compare sotto l'ultima sezione usata e resta aperto quando si tocca un'altra sezione, perché la sua chiusura dipende dal focus che quella sezione non ha mai avuto. Con il cursore in una tabella il pulsante non fa nulla.

## What should happen

Il Modello apre il menu **sotto la sezione di testo che ha il focus**, e il Requisito lo chiude quando il focus **lascia** la sezione sotto cui è aperto. Il Modello non dice cosa succede se nessuna sezione di testo ha il focus, né quando il cursore è in una tabella.

## Chosen option

**Portare il focus sull'ultima sezione**

Il pulsante mette il focus sull'ultima sezione di testo usata, così compare la tastiera e il menu si apre sotto di essa. Da lì vale la regola già prevista: il menu si chiude quando il focus lascia la sezione. Con il cursore in una tabella il menu si apre sotto l'ultima sezione di testo. Costo: la tastiera compare anche quando l'utente voleva solo il menu.

## Where in the code

lib/ui/editor/notion_document_editor.dart (openBlockMenu, _currentActiveBlock); lib/ui/mobile/mobile_keyboard_accessory_bar.dart
