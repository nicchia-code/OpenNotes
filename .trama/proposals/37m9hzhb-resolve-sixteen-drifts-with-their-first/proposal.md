---
status: approved
kind: resolution
automatic: true
drifts:
  - drift: iduazsdz
    decision: fix-code
    option: 1
  - drift: x6qu112b
    decision: fix-code
    option: 1
  - drift: zdpfz6lm
    decision: fix-code
    option: 1
  - drift: hx8s6yah
    decision: fix-code
    option: 1
  - drift: 9kparaev
    decision: fix-code
    option: 1
  - drift: xmf395dk
    decision: fix-code
    option: 1
  - drift: jl4efif8
    decision: fix-code
    option: 1
  - drift: 7ndlrnrr
    decision: fix-code
    option: 1
  - drift: 3aekiavm
    decision: fix-code
    option: 1
  - drift: x85a0dr8
    decision: fix-code
    option: 1
  - drift: fz1pbdf5
    decision: fix-code
    option: 1
  - drift: 6toovbfp
    decision: fix-code
    option: 1
  - drift: 44fyr56m
    decision: fix-code
    option: 1
  - drift: i9ndys4i
    decision: fix-code
    option: 1
  - drift: ra8n29d2
    decision: fix-code
    option: 1
  - drift: zgd5ssrh
    decision: fix-code
    option: 1
base: {}
delete: []
created: 2026-10-13T05:48:51.893Z
---
# Resolve sixteen Drifts with their first fix

Risoluzione automatica: per ciascun Drift autorizzato si sceglie la prima opzione di correzione.

- D14 – Model still says the empty-trash PIN check covers only shown notes: correzione nel codice, opzione 1.
- D15 – Model still says protected notes arrive from the vault, which the app never reads: correzione nel codice, opzione 1.
- D16 – Lock toggle can save an older text over a newer one still being written: correzione nel codice, opzione 1.
- D2 – Model still starts a sync run on token renewal, the code only reopens the channel: correzione nel codice, opzione 1.
- D4 – Model and Requirement say a full sync never removes local folders, the code does: correzione nel codice, opzione 1.
- D5 – Model says the queued save of a never-synced note is sent, the code discards it when the note is deleted here: correzione nel codice, opzione 1.
- D6 – Empty trash asks PIN for hidden protected notes, the Model asks only for shown ones: correzione nel codice, opzione 1.
- D7 – Duplicate clears the search text, the Model says only creation does: correzione nel codice, opzione 1.
- D8 – Tags written in a new note's text are missing from the tag list and filter: correzione nel codice, opzione 1.
- D9 – Model does not describe folder delete dropping queued creation or rename: correzione nel codice, opzione 1.
- D12 – Lock of a never-synced welcome note stays local, the Model and Requirement say it is queued: correzione nel codice, opzione 1.
- D13 – Shared Markdown text drops the other lines of the title block: correzione nel codice, opzione 1.
- D17 – Attachment references with an absolute path are synced as vault paths: correzione nel codice, opzione 1.
- D18 – Model says edits to a note outside the loaded list are ignored, the code saves them: correzione nel codice, opzione 1.
- D21 – Aa style and checklist button strip any number of hash signs, not only # ## ###: correzione nel codice, opzione 1.
- D22 – Note whose content is an empty block list is titled with the raw text: correzione nel codice, opzione 1.
