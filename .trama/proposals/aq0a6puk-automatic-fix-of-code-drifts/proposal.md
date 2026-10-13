---
status: approved
kind: resolution
automatic: true
drifts:
  - drift: t796620d
    decision: fix-code
    option: 1
  - drift: eyb7mz77
    decision: fix-code
    option: 1
  - drift: lqowf75n
    decision: fix-code
    option: 1
  - drift: eld1idb2
    decision: fix-code
    option: 1
base: {}
delete: []
created: 2026-10-12T14:39:07.931Z
---
# Automatic fix of code Drifts

Risoluzione automatica: ogni Drift viene corretto nel codice secondo la sua prima Fix option.

- D1 – Tag in altri alfabeti: Model e Requirement in conflitto → correzione del codice: i tag accettano solo lettere latine (accentate incluse), cifre, «_» e «-».
- D2 – Vault file name: long titles are cut by code units, the Requirement counts characters → correzione del codice: il nome del file si accorcia per caratteri interi.
- D7 – Deleted folder comes back on a remote change → correzione del codice: una modifica remota non riporta una cartella la cui eliminazione è in coda.
- D10 – Heading line with a typed number, quote or fence changes its style → correzione del codice: il segno digitato cambia il tipo solo delle righe di corpo.
