---
column: done
technical: false
refs:
  - text-line/Body
drift: null
proposal: null
agent: false
created: 2026-10-12T14:53:31.353Z
finished: 2026-10-12T16:27:01.680Z
---
# Fix code to match the Requirements: Text such as «1.5 volte» is treated as a numbered item

Una riga di corpo che comincia con un numero seguito da un punto senza spazio («1.5 volte», «3.14») diventa una voce numerata. Effetti visibili: Invio alla fine di «3.14» aggiunge una riga «4. » sotto il testo; Tab su «1.5 volte» produce «  1. 5 volte», quindi cambia il testo scritto. I Requirements dicono che un segno senza spazio resta nel testo («1.5 volte»), e il Model descrive il simbolo come «un numero con punto e spazio». Il rilevamento in _convertMarkdownShortcuts, e le espressioni di numero in handleEnterKey e handleTabKey (rich_text_editing_controller.dart), devono richiedere il numero, il punto e lo spazio, come le voci puntate richiedono lo spazio. Le voci già in formato «N. » restano numerate.
