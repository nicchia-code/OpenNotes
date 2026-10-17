---
status: approved
kind: resolution
drifts:
  - drift: lteifbva
    decision: fix-code
    option: 1
  - drift: mh11qz2q
    decision: fix-code
    option: 1
  - drift: joch4ip2
    decision: fix-code
    option: 1
  - drift: lvsvdf7a
    decision: fix-code
    option: 1
  - drift: hs8vzsqq
    decision: proposal
  - drift: c23bbpp3
    decision: fix-code
    option: 1
base:
  cloud-sync/pending-change.md: e3bac409c906e8ce59c4071b84a8ea6a1c135cfb28b4f585d99757625c43a725
delete: []
created: 2026-10-17T14:45:25.621Z
---
# Resolve sync icons, revision checks, account switch queue, set-aside requeue and table reload Drifts

Questa risoluzione decide sei Drift tra codice e Model:
- lteifbva Sync status icons missing from CupertinoIcons: si corregge il codice, l'indicatore mostra la nuvola CupertinoIcons con un piccolo segno sovrapposto (spunta, esclamativo o barra).
- mh11qz2q Cloud folder change already seen by revision is applied again: si corregge il codice, la modifica di una cartella con revisione già nota viene ignorata come per le note, dal canale e nel giro di sincronizzazione.
- joch4ip2 Cloud delete with a known newer revision removes the note or folder: si corregge il codice, un'eliminazione con revisione più vecchia di quella nota viene ignorata come un'eco.
- lvsvdf7a Unsent changes of removed notes reach the new account again: si corregge il codice, al cambio di account le modifiche in coda delle note rimosse vengono scartate senza essere inviate.
- hs8vzsqq Set-aside change returns to the queue on save, the Model does not say so: si cambia il Model, un salvataggio o un'eliminazione definitiva rimette in coda la modifica messa da parte, come dicono già i Requirement.
- c23bbpp3 Table cells keep their old text after a remote reload: si corregge il codice, la tabella viene ricreata a ogni caricamento di una versione remota e il cursore torna nella stessa cella.
