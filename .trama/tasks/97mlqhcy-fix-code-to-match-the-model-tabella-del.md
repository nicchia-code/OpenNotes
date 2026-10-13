---
column: done
technical: false
refs:
  - requirements/rules#editor-suggestions
  - editor-suggestions/Block menu
drift: n36a1c1s
proposal: null
agent: false
created: 2026-10-12T07:38:53.696Z
finished: 2026-10-12T10:24:15.861Z
---
# Fix code to match the Model: Tabella del menu rapido cancella tutta la sezione

## What happens

Scegliendo **Tabella** dal menu rapido, il sistema elimina l'intera sezione di testo in cui il menu è aperto, comprese le righe scritte dopo la «/», e poi inserisce la tabella. Le altre voci del menu, invece, tolgono soltanto la «/» dalla riga corrente e lasciano il resto del testo.

## What should happen

La regola dice che scegliere una voce **toglie soltanto la «/»** seguita da lettere, cifre e spazi dalla riga corrente. Il testo già scritto nella sezione deve restare. La voce Tabella deve comportarsi come le altre.

## Chosen option

**Togliere solo la «/» anche per la Tabella**

La voce **Tabella** toglie la «/» dalla riga corrente come le altre, e la tabella viene inserita dopo la sezione. Nessun testo scritto va perso. Costo: la tabella non compare esattamente nel punto del cursore quando la sezione ha altre righe.

## Where in the code

lib/ui/editor/notion_document_editor.dart, _buildSlashMenu: la voce Tabella (onTap).
