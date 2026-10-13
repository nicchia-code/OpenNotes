---
status: resolved
resolution: fix-code
refs:
  - app-window/Open
  - requirements/rules#app-window
proposal: null
task: dbqya90z
origin: null
critical: false
option: 1
note: null
resolvedBy: m16unv7j
created: 2026-10-12T11:21:35.336Z
---
# Desktop window narrower than 680 px has no top bar, window controls or drag area

## What happens

Sui sistemi desktop la finestra può essere ridotta fino a 640 px di larghezza. Sotto 680 px l'app passa all'interfaccia mobile, che non ha la barra superiore: non si può trascinare la finestra dalla barra, non ci sono i pulsanti chiudi, riduci e ingrandisci, e il doppio clic non fa nulla.

## What should happen

Il Requisito della finestra dice che la barra superiore è l'area di trascinamento su Linux, macOS e Windows e che la finestra può arrivare a 640 × 480 px. Il Modello dice che nell'interfaccia mobile la barra e i comandi della finestra non ci sono, e il Requisito di navigazione porta l'interfaccia mobile sotto 680 px. Le due regole non stanno insieme: tra 640 e 679 px la finestra non ha più modo di essere spostata o chiusa dall'app, e non si può seguire il Requisito della finestra senza cambiare la soglia o il minimo.

## Fix options

### Alzare la larghezza minima a 680 px

La finestra non può più essere ridotta sotto 680 px, quindi la barra e i comandi restano sempre visibili sui sistemi desktop. Costo: va aggiornato il Requisito della finestra (minimo 680 × 480 px); il Modello non cambia.

### Mostrare la barra anche sotto 680 px

Sui sistemi desktop la barra con i comandi resta anche sotto 680 px, senza colonne laterali. Costo: la barra va resa compatta fino a 640 px, e il Requisito di navigazione cambia per le finestre desktop.

### Accettare la finestra senza comandi sotto 680 px

Sotto 680 px la finestra non ha barra né comandi nell'app e si sposta e si chiude con i comandi del sistema. Costo: il Requisito della finestra va riscritto con questa eccezione; nessun cambio al codice.

## Where in the code

lib/main.dart (dimensione minima), lib/ui/shell/adaptive_app_shell.dart (soglia 680 px)
