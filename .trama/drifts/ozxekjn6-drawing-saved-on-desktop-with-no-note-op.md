---
status: resolved
resolution: proposal
refs:
  - drawing-canvas/Closed
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: hp4kwvga
created: 2026-10-17T12:42:19.353Z
---
# Drawing saved on desktop with no note open is lost

## What happens

Su desktop il pulsante Disegno della barra superiore e la voce del menu sono sempre attivi, anche quando nessuna nota è selezionata. La tela si apre, il disegno viene esportato e salvato tra gli allegati del vault, poi la tela si chiude come se fosse stato inserito. Nessun editor è presente a riceverlo: l'immagine non compare in nessuna nota e resta un file tra gli allegati collegato a nessuna nota.

## What should happen

Il Model dice che il disegno finito entra nella nota aperta e che la tela si apre dalla barra degli strumenti, ma non dice cosa succede quando non c'è nessuna nota aperta: lo stato note-editor/Closed non reagisce a drawing-canvas.DRAWING_SAVED, e drawing-canvas/Closed → Drawing non ha condizioni. Così com'è il comportamento non è realizzabile come descritto, perché il salvataggio tra gli allegati non ha una nota che lo riceva e l'utente perde il disegno senza avviso.

## Fix options

### Disattivare Disegno senza nota

Il pulsante Disegno della barra desktop e la sua voce di menu sono disattivati quando nessuna nota è selezionata, come gli altri comandi che richiedono una nota. Nessun file viene creato. Costa: il disegno non è disponibile finché non c'è una nota aperta, e il Model dovrà chiarire che il comando dipende dalla nota selezionata.

### Non salvare senza nota

La tela si apre anche senza nota, ma il pulsante Fine è disattivato e un avviso dice che il disegno richiede una nota aperta. Nessun file viene creato e il disegno resta sulla tela finché l'utente non annulla. Costa: l'utente può disegnare inutilmente senza poter salvare.

### Creare una nota per il disegno

Se nessuna nota è selezionata, Fine crea una nuova nota, vi inserisce il disegno e la seleziona. Costa: crea una nota che l'utente non ha chiesto, e il Model di note-selection dovrà descrivere questo caso.

## Where in the code

lib/ui/shell/mac_title_bar.dart: pulsante Disegno e voce 'drawing' del menu, sempre collegati a onDrawing. lib/ui/shell/adaptive_app_shell.dart: _onDrawing salva con _editorKey.currentState?.insertImage, che è null quando la colonna dell'editor mostra 'Nessuna nota selezionata'.
