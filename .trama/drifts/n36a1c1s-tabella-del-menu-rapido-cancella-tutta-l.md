---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#editor-suggestions
  - editor-suggestions/Block menu
proposal: null
task: 97mlqhcy
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:25:28.740Z
---
# Tabella del menu rapido cancella tutta la sezione

## What happens

Scegliendo **Tabella** dal menu rapido, il sistema elimina l'intera sezione di testo in cui il menu è aperto, comprese le righe scritte dopo la «/», e poi inserisce la tabella. Le altre voci del menu, invece, tolgono soltanto la «/» dalla riga corrente e lasciano il resto del testo.

## What should happen

La regola dice che scegliere una voce **toglie soltanto la «/»** seguita da lettere, cifre e spazi dalla riga corrente. Il testo già scritto nella sezione deve restare. La voce Tabella deve comportarsi come le altre.

## Fix options

### Togliere solo la «/» anche per la Tabella

La voce **Tabella** toglie la «/» dalla riga corrente come le altre, e la tabella viene inserita dopo la sezione. Nessun testo scritto va perso. Costo: la tabella non compare esattamente nel punto del cursore quando la sezione ha altre righe.

### Dividere la sezione al punto della «/»

Il testo prima della riga con la «/» resta sopra, la tabella compare al suo posto e le righe successive restano sotto, in una nuova sezione di testo. Nessun testo va perso e la tabella è nel punto giusto. Costo: più lavoro sulla divisione delle sezioni e più casi da controllare.

## Where in the code

lib/ui/editor/notion_document_editor.dart, _buildSlashMenu: la voce Tabella (onTap).
