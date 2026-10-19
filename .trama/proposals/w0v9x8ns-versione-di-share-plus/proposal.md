---
status: rejected
base:
  requirements/tech/general.md: 280c9c3a66a97be6d7db71d9c1ae48aff8ffb18dd7eb8051f51c2b33584212dc
delete: []
created: 2026-10-19T15:33:53.722Z
---
# Versione di share_plus

Decisione dell'agente per la Task 88qqlucx: super_clipboard 0.9.1 (tramite super_native_extensions e device_info_plus) richiede win32 sotto la versione 6, mentre share_plus 13.3.0 richiede win32 ^6.0.1: pub non risolve le dipendenze. Scelta proposta: share_plus 12.0.2, che richiede win32 ^5.5.3 e resta compatibile con l'SDK del progetto. Alternativa: attendere una versione di super_clipboard che accetti win32 6. Il Requirement tech#General va aggiornato di conseguenza.

## Feedback

Drift q7e6k3gz resolved by Proposal p4wq4e4l
