---
status: resolved
resolution: fix-code
refs:
  - editor-suggestions/Hidden/user.OPEN_BLOCK_MENU
  - requirements/rules#editor-suggestions
proposal: null
task: eu7oflx7
origin: null
critical: false
option: 1
note: null
resolvedBy: psazi867
created: 2026-10-12T16:47:14.370Z
---
# Block menu opened from the toolbar with no text section focused

## What happens

Sul telefono il pulsante **Menu blocchi** apre il menu anche quando nessuna sezione di testo ha il focus, cioè con la tastiera chiusa: il menu compare sotto l'ultima sezione usata e resta aperto quando si tocca un'altra sezione, perché la sua chiusura dipende dal focus che quella sezione non ha mai avuto. Con il cursore in una tabella il pulsante non fa nulla.

## What should happen

Il Modello apre il menu **sotto la sezione di testo che ha il focus**, e il Requisito lo chiude quando il focus **lascia** la sezione sotto cui è aperto. Il Modello non dice cosa succede se nessuna sezione di testo ha il focus, né quando il cursore è in una tabella.

## Fix options

### Portare il focus sull'ultima sezione

Il pulsante mette il focus sull'ultima sezione di testo usata, così compare la tastiera e il menu si apre sotto di essa. Da lì vale la regola già prevista: il menu si chiude quando il focus lascia la sezione. Con il cursore in una tabella il menu si apre sotto l'ultima sezione di testo. Costo: la tastiera compare anche quando l'utente voleva solo il menu.

### Non aprire il menu senza focus

Se nessuna sezione di testo ha il focus, il pulsante non fa nulla. Il Modello resta com'è, con una regola in più scritta esplicitamente. Costo: il pulsante sembra rotto finché l'utente non tocca un testo, e con il cursore in una tabella resta muto.

### Aprire il menu senza focus

Il menu si apre sotto l'ultima sezione usata anche senza focus e si chiude al primo tocco su un'altra sezione. Il Modello va completato con questa transizione. Costo: un menu aperto senza cursore, uno stato in più da descrivere e da provare.

## Where in the code

lib/ui/editor/notion_document_editor.dart (openBlockMenu, _currentActiveBlock); lib/ui/mobile/mobile_keyboard_accessory_bar.dart
