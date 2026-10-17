---
status: resolved
resolution: proposal
refs:
  - folder
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: xqdml6er
created: 2026-10-17T11:34:53.547Z
---
# Folder picker shows subfolders as a tree, the Model says all folders share one level

## What happens

Il selettore "Sposta in…" mostra le cartelle ad albero secondo la cartella superiore, con rientri proporzionali alla profondità e le cartelle orfane in fondo. La creazione dall'interfaccia non assegna mai una cartella superiore, quindi l'albero compare solo con cartelle arrivate dal cloud.

## What should happen

Il Model della cartella dice che le cartelle non hanno sottocartelle nell'interfaccia e compaiono tutte allo stesso livello. Il Requirement rules di organization (selettore "Sposta in…") richiede invece l'albero con orfani in fondo. Model e Requirement sono in contrasto e vanno allineati.

## Fix options

### Keep the tree and fix the Model

Aggiornare il Model: il selettore "Sposta in…" mostra le cartelle ad albero secondo la cartella superiore, come il Requirement; la sidebar e le liste restano piatte.

### Flat picker

Mostrare le cartelle piatte nel selettore, ordinate per nome senza distinzione di maiuscole, e modificare il Requirement; togliere l'albero e il trattamento degli orfani dal selettore.

## Where in the code

lib/ui/notes_list/folder_picker.dart (_orderedFolders, usato dal selettore Sposta in…)
