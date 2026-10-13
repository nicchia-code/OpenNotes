---
status: resolved
resolution: fix-code
refs:
  - folder
  - requirements/rules#folder
  - requirements/data#folder
proposal: null
task: 3mi1fnx3
origin: null
critical: false
option: 1
note: null
resolvedBy: fz9axufm
created: 2026-10-12T10:50:10.836Z
---
# Quick notes view is in the Model but never shown in the app

## What happens

Il navigatore delle note non ha nessuna voce "Note rapide": né la barra laterale né la schermata Cartelle la mostrano, e nessuna vista di questo nome viene mai selezionata. Quando la selezione non è una cartella, la nota nuova va comunque nella cartella "Note", e la vista non compare in nessun conteggio.

## What should happen

Il Model della cartella dice che "Note rapide" è una vista del navigatore delle note, come "Tutte le note" ed "Eliminati di recente", e la regola di creazione della nota la nomina tra le selezioni possibili. Il Requirement sulle viste dice invece che "Note rapide" non viene mai mostrata. Il Model del navigatore delle note non ha nessuno stato per questa vista, quindi non è chiaro se esista.

## Fix options

### Remove Note rapide from the Model

La vista esce dal Model: la descrizione della cartella e la regola di creazione della nota non la nominano più, e la nota nuova in qualunque selezione non cartella va nella cartella "Note", come oggi. Il comportamento dell'app non cambia; si tolgono il nome di vista e la gestione che lo riconosce, che non servono più. Costo: una Proposal sul Model della cartella e della nota, e una pulizia del codice.

### Show Note rapide in the navigator

La vista entra nel navigatore: una voce nella barra laterale e nella schermata Cartelle, con le note che contiene e il conteggio. Costo: il Model del navigatore delle note ha bisogno di uno stato nuovo, il Requirement "mai mostrata" va riscritto in una Proposal, e bisogna decidere quali note entrano nella vista e come si crea una nota dentro di essa.

## Where in the code

lib/core/models/folder_model.dart (quickNotesId); lib/core/state/notes_provider.dart (creazione della nota, ripiego su quickNotesId); lib/ui/sidebar/sidebar_view.dart e lib/ui/mobile/mobile_folders_screen.dart (nessuna voce).
