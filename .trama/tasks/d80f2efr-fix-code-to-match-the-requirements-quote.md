---
column: done
technical: true
refs:
  - requirements/data#note-editor
drift: aoebmujn
proposal: null
agent: false
created: 2026-10-12T14:57:05.788Z
finished: 2026-10-12T14:59:57.931Z
---
# Fix code to match the Requirements: Quote, monospace and numbered lines keep a saved line type the Requirements do not list

## What happens

Quando una riga di testo diventa citazione, monospazio o voce numerata, l'editor salva il tipo di quella riga insieme al testo, come fa per titoli e intestazioni. Riaprendo la nota la riga mantiene la sua forma perché quel tipo salvato viene riletto. Il segno resta visibile nel testo.

## What should happen

Il Requirement dice che l'editor salva come stili di riga solo titolo, intestazioni e corpo, e non prevede che al caricamento citazione, monospazio e voce numerata vengano riconosciuti dal segno. Il Model dice invece che il tipo di queste righe viene dal segno con cui la riga comincia e che resta anche alla riapertura della nota. Le due descrizioni non si possono rispettare entrambe così come sono scritte.

## Chosen option

**Salvare anche questi tipi di riga**

Il formato salvato resta quello attuale e il Requirement viene aggiornato: gli stili di riga salvati includono anche citazione, monospazio e voce numerata. Nell'aspetto non cambia nulla. Costo: tre stili in più nei dati e un Requirement da riscrivere.

## Where in the code

lib/ui/editor/notion_document_editor.dart (caricamento e salvataggio degli stili di riga); lib/ui/editor/rich_text_editing_controller.dart (tipi di riga dal segno iniziale)
