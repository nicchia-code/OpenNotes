---
status: resolved
resolution: proposal
refs:
  - note-access/Protected
proposal: null
task: null
origin: null
previous: o4es5ttq
critical: false
option: null
note: null
resolvedBy: famz2y49
created: 2026-10-18T18:28:02.296Z
---
# Permanent delete of an unlocked protected note skips the PIN, the Model and the Requirement ask it every time

## What happens

Eliminando definitivamente dal cestino una nota protetta che è già sbloccata per la sessione, l'app non chiede il PIN: dopo la conferma dell'eliminazione la nota viene cancellata subito. Per una nota protetta non ancora sbloccata il PIN viene chiesto come previsto. Questo comportamento è quello deciso con il Drift o4es5ttq, ma il Model dell'accesso e il Requirement delle regole dicono ancora il contrario, quindi per questo caso Model e codice non coincidono.

## What should happen

Il Model dell'accesso dice che eliminare definitivamente una nota chiede ogni volta il PIN corretto, anche se la nota è sbloccata per la sessione; il Requirement delle regole dell'accesso dice lo stesso, a prescindere dallo sblocco di sessione. Il Model della navigazione mobile, invece, dice che il PIN serve solo per una nota protetta non ancora sbloccata.

## Fix options

### Skip the PIN for notes already unlocked (recommended)

Si lascia il codice com'è: la nota già sbloccata in questa sessione si elimina dopo la sola conferma. Si cambia il Model dell'accesso (stato Protected) e il Requirement delle regole dell'accesso, così dicono che il PIN serve per le note protette non ancora sbloccate, come il Model della navigazione mobile. Costo: due frasi da aggiornare; nessun cambio di codice.

### Ask the PIN every time, even when unlocked

Si toglie il controllo sullo sblocco di sessione dalla conferma dell'eliminazione definitiva, così il PIN corretto va chiesto ogni volta per una nota protetta, anche se già sbloccata. Costo: una richiesta in più per l'utente; si cambia il Model della navigazione mobile e la sua Task già chiusa, perché il Drift o4es5ttq aveva scelto l'altra strada.

## Where in the code

lib/ui/notes_list/note_actions.dart: confirmPermanentDelete, controllo di sblocco di sessione prima di mostrare il dialogo PIN
