---
column: done
technical: false
refs:
  - editor-suggestions/Block menu
drift: w3dxp4yw
proposal: null
agent: false
created: 2026-10-12T14:20:57.116Z
finished: 2026-10-12T14:22:29.836Z
---
# Fix code to match the Model: Bar block menu button missing from the Block menu Model

## What happens

Sul telefono la barra sopra la tastiera ha un pulsante «Menu blocchi» che apre il menu rapido sotto la sezione di testo corrente, con le sette voci. Il pulsante Aa apre invece il suo elenco di formati. Il Modello del Block menu non descrive questa apertura dalla barra: nessuna transizione la prevede, quindi il comportamento del pulsante non è coperto dal Modello.

## What should happen

Il Requisito di editor-suggestions vuole che sul telefono il menu rapido compaia toccando il suo pulsante sulla barra, con le sette voci Checklist, Intestazione, Sottointestazione, Elenco, Numerato, Citazione e Tabella. La proposta m16unv7j, che doveva risolvere il Drift 63qylj4f, non ha aggiunto la transizione. Senza una transizione nel Modello non si può dire quando il menu si apre dalla barra, né quando si chiude o cosa succede al testo.

## Chosen option

**Completare il Modello con l'apertura dalla barra**

Si aggiunge al Block menu una transizione: il pulsante della barra apre il menu sotto la sezione corrente, con le sette voci, e lo chiude come le altre aperture. Il codice resta com'è. Costo: una transizione nuova da mantenere e la necessità di distinguerla dal pulsante Aa, che apre già l'elenco dei formati.

## Where in the code

lib/ui/mobile/mobile_keyboard_accessory_bar.dart; lib/ui/editor/notion_document_editor.dart
