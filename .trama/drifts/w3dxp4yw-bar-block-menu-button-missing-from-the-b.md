---
status: resolved
resolution: fix-code
refs:
  - editor-suggestions/Block menu
proposal: null
task: 025ts5c9
origin: mye3y7ge
critical: false
option: 1
note: null
resolvedBy: 3tg049lq
created: 2026-10-12T14:04:30.654Z
---
# Bar block menu button missing from the Block menu Model

## What happens

Sul telefono la barra sopra la tastiera ha un pulsante «Menu blocchi» che apre il menu rapido sotto la sezione di testo corrente, con le sette voci. Il pulsante Aa apre invece il suo elenco di formati. Il Modello del Block menu non descrive questa apertura dalla barra: nessuna transizione la prevede, quindi il comportamento del pulsante non è coperto dal Modello.

## What should happen

Il Requisito di editor-suggestions vuole che sul telefono il menu rapido compaia toccando il suo pulsante sulla barra, con le sette voci Checklist, Intestazione, Sottointestazione, Elenco, Numerato, Citazione e Tabella. La proposta m16unv7j, che doveva risolvere il Drift 63qylj4f, non ha aggiunto la transizione. Senza una transizione nel Modello non si può dire quando il menu si apre dalla barra, né quando si chiude o cosa succede al testo.

## Fix options

### Completare il Modello con l'apertura dalla barra

Si aggiunge al Block menu una transizione: il pulsante della barra apre il menu sotto la sezione corrente, con le sette voci, e lo chiude come le altre aperture. Il codice resta com'è. Costo: una transizione nuova da mantenere e la necessità di distinguerla dal pulsante Aa, che apre già l'elenco dei formati.

### Togliere il pulsante dalla barra

Il menu si apre solo digitando una barra all'inizio della sezione, come sul computer. Il pulsante Menu blocchi sparisce dalla barra e il Requisito sul telefono va cambiato. Costo: sul telefono le sette voci si raggiungono solo digitando, e la barra perde una scorciatoia.

### Unire le voci nel pulsante Aa

Il pulsante Aa mostra sia i formati sia le sette voci del menu blocchi, e il pulsante Menu blocchi viene tolto. Il Modello va aggiornato per dire che Aa apre il menu con due sezioni. Costo: un solo elenco più lungo, con il rischio di confondere formato di testo e nuovi blocchi.

## Where in the code

lib/ui/mobile/mobile_keyboard_accessory_bar.dart; lib/ui/editor/notion_document_editor.dart
