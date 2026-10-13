---
status: resolved
resolution: proposal
refs:
  - note-browser/Browsing
proposal: null
task: null
origin: nq6ewm51
previous: 7ndlrnrr
critical: false
option: null
note: null
resolvedBy: dbeofb0j
created: 2026-10-13T05:52:39.634Z
---
# Duplicate clears the search but the Model still says only creation does

## What happens

Duplicando una nota la ricerca viene svuotata, come alla creazione; il Model dice ancora che solo la creazione la svuota. La decisione scelta nel Drift 7ndlrnrr non è stata riportata nel Model e nei Requirement.

## What should happen

Il Model della vista elenco e della nota, e i Requirement delle regole, dicono che solo la creazione svuota il testo di ricerca. La decisione scelta (svuotare la ricerca anche alla duplicazione) richiede di aggiornarli, e il codice già si comporta così; il Task chiede invece di allineare il codice al Model attuale, cioè di non svuotarla.

## Fix options

### Keep the search cleared on duplicate

La duplicazione svuota la ricerca come la creazione, così la copia compare nell'elenco ed è selezionata. Il codice resta com'è e il Model e i Requirement vengono aggiornati con la Proposal allegata. Costo: dopo ogni duplicazione l'utente perde il filtro di ricerca.

### Stop clearing the search on duplicate

Il codice smette di svuotare la ricerca alla duplicazione, come dice il Model attuale. La copia può restare nascosta dietro la ricerca e non viene mostrata, e la decisione scelta nel Drift 7ndlrnrr va rivista. Costo: la copia non compare subito nell'elenco quando una ricerca è attiva.

## Where in the code

lib/core/state/notes_provider.dart (duplicateNote)
