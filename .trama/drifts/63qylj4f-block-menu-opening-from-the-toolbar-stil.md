---
status: resolved
resolution: fix-code
refs:
  - editor-suggestions/Block menu
proposal: null
task: m6nz5jde
origin: g8zt4e2u
critical: false
option: 1
note: null
resolvedBy: m16unv7j
created: 2026-10-12T11:01:18.071Z
---
# Block menu opening from the toolbar still missing from the Model

## What happens

Il pulsante Aa della barra sopra la tastiera del telefono apre ancora il suo elenco di formati. Il menu rapido dei blocchi compare solo quando la sezione di testo comincia con una barra digitata a mano. La Proposal fz9axufm è approvata e risolve il Drift sohxd74z scegliendo di completare il Modello, ma non tocca alcun file: il Modello di Block menu non ha ancora nessuna transizione che apra il menu dalla barra.

## What should happen

Il Requisito di editor-suggestions dice che sul telefono il menu rapido compare quando si tocca il suo pulsante sulla barra sopra la tastiera, con le sette voci Checklist, Intestazione, Sottointestazione, Elenco, Numerato, Citazione e Tabella. Il Modello deve avere una transizione che apre il menu dalla barra, così il comportamento è definito e il codice può seguirlo. Senza di essa il Task dovrebbe inventare il comportamento, quindi resta fermo.

## Fix options

### Completare il Modello con l'apertura dalla barra

Si aggiunge al Modello di Block menu una transizione: il pulsante della barra apre il menu rapido sotto la sezione corrente, con le sette voci. Poi si implementa il pulsante. Costo: un pulsante in più sulla barra e una transizione nuova da mantenere, con il rischio di sovrapporsi al pulsante Aa, che oggi apre un altro elenco.

### Far aprire dalla barra il menu rapido al posto dell'elenco Aa

Il pulsante Aa apre direttamente le sette voci del menu rapido. Il Modello va completato con questa apertura. Costo: Titolo, Corpo e Sottolineato non sarebbero più raggiungibili dalla barra, cambiando un comportamento che l'utente conosce.

### Togliere l'apertura dalla barra dal Requisito

Il menu resta aperto solo digitando la barra all'inizio della sezione. Il Requisito sul pulsante della barra viene rimosso o riformulato. Costo: sulla tastiera del telefono non c'è un modo rapido per raggiungere le sette voci.

## Where in the code

lib/ui/editor/notion_document_editor.dart; lib/ui/mobile/mobile_keyboard_accessory_bar.dart
