---
status: resolved
resolution: proposal
refs:
  - editor-suggestions/Tag suggestions
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: xiy2hxml
created: 2026-10-12T14:32:23.618Z
---
# Create-tag entry hidden when only letter case differs

## What happens

Se si scrive un tag con lettere maiuscole, per esempio «#Lavoro», e nelle note esiste già il tag «lavoro», il menu mostra il tag esistente ma non la voce «Crea #Lavoro». Il confronto ignora maiuscole e minuscole, quindi basta un tag uguale a meno delle maiuscole per nascondere la voce.

## What should happen

Il Modello dice che la voce «Crea #testo» compare quando nessun tag ha esattamente quel nome. Con un tag che differisce solo per maiuscole, quindi, la voce dovrebbe comparire comunque. I tag si salvano in minuscolo, quindi scegliere «Crea #Lavoro» non crea un tag nuovo, ma aggiunge solo una voce che sembra diversa.

## Fix options

### Il confronto ignora le maiuscole (consigliato)

Il menu nasconde «Crea» quando un tag esistente corrisponde al testo anche solo per le maiuscole, come oggi. Il Modello va aggiornato per dire «senza distinguere maiuscole e minuscole», come già scritto per l'elenco dei tag. Costo: un solo ritocco al testo del Modello; non si può più proporre una voce che, dopo il salvataggio in minuscolo, coinciderebbe con un tag esistente, che è proprio ciò che si vuole evitare.

### Il confronto è esatto, come scritto nel Modello

La voce «Crea» compare anche quando il tag esistente differisce solo per le maiuscole, per esempio «Crea #Lavoro» accanto a «#lavoro». Scegliendola il tag salvato resta lo stesso, quindi il menu propone una voce che non cambia nulla. Costo: una modifica piccola al menu e nessuna modifica al Modello, ma la lista può mostrare due voci che sembrano diverse e portano allo stesso tag.

## Where in the code

lib/ui/editor/notion_document_editor.dart, costruzione del menu dei tag (condizione della voce «Crea»)
