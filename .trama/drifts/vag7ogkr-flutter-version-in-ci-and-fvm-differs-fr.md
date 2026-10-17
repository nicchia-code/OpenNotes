---
status: resolved
resolution: proposal
refs:
  - requirements/tech#General
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: hp4kwvga
created: 2026-10-17T12:21:51.010Z
---
# Flutter version in CI and FVM differs from the Requirement

## What happens

Le build automatiche compilano e verificano l'app con Flutter 3.41.6, mentre lo sviluppo locale con FVM usa Flutter 3.47.7. Nessuna delle due è la versione che il progetto fissa.

## What should happen

Le regole tecniche del progetto fissano Flutter alla versione 3.41.2 del canale stable, sia per la compilazione sia per lo sviluppo.

## Fix options

### Pin CI and FVM to 3.41.2

Portare sia la versione della CI sia quella del file FVM a 3.41.2. Build e sviluppo locale usano la versione richiesta. Chi aggiorna Flutter deve cambiare ancora due punti, come oggi.

### Read the version from the FVM file

Far leggere alla CI la versione dal file FVM e portare quel file a 3.41.2. La versione si cambia in un solo punto, ma la compilazione dipende dal file di configurazione locale, che oggi nessun job usa.

## Where in the code

Il valore FLUTTER_VERSION del workflow desktop-build.yml; il file .fvmrc alla radice.
