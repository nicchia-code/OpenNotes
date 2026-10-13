---
status: resolved
resolution: fix-code
refs:
  - editor-suggestions/Block menu
proposal: null
task: mye3y7ge
origin: m6nz5jde
critical: false
option: 1
note: null
resolvedBy: 6dq6m1w3
created: 2026-10-12T11:28:47.433Z
---
# Toolbar button opens Block menu missing from the Model

## What happens

Il pulsante Aa della barra sopra la tastiera del telefono apre ancora il suo elenco di formati, e il menu rapido dei blocchi compare solo quando la sezione comincia con una barra digitata a mano. Il Modello di Block menu non ha una transizione che apra il menu dalla barra, quindi non c'è nulla da implementare sul pulsante. La Proposal m16unv7j, indicata come risoluzione del Drift 63qylj4f, non ha aggiunto questa transizione.

## What should happen

Il Requisito di editor-suggestions vuole che sul telefono il menu rapido compaia toccando il suo pulsante sulla barra, con le sette voci Checklist, Intestazione, Sottointestazione, Elenco, Numerato, Citazione e Tabella. Il Modello non definisce questa apertura, quindi il comportamento non può essere seguito senza inventarlo. Serve una decisione su come la barra apre il menu, visto che il pulsante Aa apre già un altro elenco.

## Fix options

### Completare il Modello con l'apertura dalla barra

Si aggiunge al Modello di Block menu una transizione: il pulsante della barra apre il menu rapido sotto la sezione corrente, con le sette voci. Poi si implementa il pulsante. Costo: un pulsante in più sulla barra e una transizione nuova da mantenere, con il rischio di sovrapporsi al pulsante Aa.

### Far aprire dalla barra il menu rapido al posto dell'elenco Aa

Il pulsante Aa apre direttamente le sette voci del menu rapido, e il Modello va completato con questa apertura. Costo: Titolo, Corpo e Sottolineato non sarebbero più raggiungibili dalla barra, cambiando un comportamento che l'utente conosce.

### Togliere l'apertura dalla barra dal Requisito

Il menu resta aperto solo digitando la barra all'inizio della sezione, e il Requisito sul pulsante viene rimosso o riformulato. Costo: sulla tastiera del telefono non c'è un modo rapido per raggiungere le sette voci.

## Where in the code

lib/ui/mobile/mobile_keyboard_accessory_bar.dart; lib/ui/editor/notion_document_editor.dart
