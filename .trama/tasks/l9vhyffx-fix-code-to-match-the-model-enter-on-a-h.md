---
column: done
technical: false
refs:
  - text-line/Heading
drift: null
proposal: null
agent: false
created: 2026-10-12T14:53:26.524Z
finished: 2026-10-12T16:26:51.339Z
---
# Fix code to match the Model: Enter on a heading line with a list or checklist symbol continues the list

Su una riga di titolo o intestazione che ha un simbolo di elenco («• », «◦ », «▪ ») o di checklist («○ », «● »), Invio crea una nuova voce puntata o da fare invece di una riga di corpo. Il Model dice che Invio su una riga di intestazione va a capo con una riga in stile corpo, e i Requirements dicono lo stesso («a capo con la nuova riga in stile corpo»). Su una riga di intestazione con solo il simbolo, Invio toglie il simbolo invece di andare a capo. Il ramo dei simboli di elenco e checklist in handleEnterKey (rich_text_editing_controller.dart) deve escludere le righe di titolo e intestazione, come già fa per le voci numerate con « !isHeading ».
