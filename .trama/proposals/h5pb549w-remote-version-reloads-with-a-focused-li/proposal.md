---
status: rejected
base:
  requirements/rules/editor.md: 003baa0e72ec7bfcc6203f3c10c0b7d6f55bc58891a1e39480c48c0ba14c9e6d
delete: []
created: 2026-10-17T10:35:39.309Z
---
# Remote version reloads with a focused line

Il Modello (Proposta 634nfp49, approvata) carica la versione remota anche con una riga a fuoco, purché non ci siano modifiche in attesa, e lascia il cursore dov'è. Il Requisito `rules/editor` diceva invece che la versione remota si carica solo se nessuna riga ha il focus: questa Proposta lo allinea al Modello. Decisione: nessuna altra variante (il focus non è più una condizione; il cursore resta nella stessa riga e posizione se esistono ancora, altrimenti va alla fine della riga più vicina).

## Feedback

Drift 124148nk resolved by Proposal rpuwm3sy
