---
status: resolved
resolution: proposal
refs:
  - requirements/tech#General
proposal: null
task: null
origin: 88qqlucx
critical: false
option: null
note: null
resolvedBy: p4wq4e4l
created: 2026-10-19T15:34:15.082Z
---
# Versione di share_plus in conflitto

## What happens

La libreria per gli appunti (**super_clipboard** 0.9.1) e la libreria di condivisione (**share_plus** 13.3.0) non si possono installare insieme: le dipendenze del progetto non si risolvono e l'app non si compila. Il progetto oggi non ha ancora la libreria per gli appunti, quindi nulla è stato modificato.

## What should happen

Il Requirement di tecnologia fissa entrambe le versioni, ma la libreria per gli appunti richiede una versione di **win32** precedente alla 6, mentre tutte le versioni di share_plus 13.x ne richiedono la 6. Nessuna scelta di codice rispetta entrambe le versioni fissate.

## Where in the code

pubspec.yaml: dipendenze super_clipboard e share_plus; requisito di tecnologia requirements/tech#General
