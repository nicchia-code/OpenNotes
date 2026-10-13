---
status: resolved
resolution: fix-code
refs:
  - note-editor/Open/user.PICK_BLOCK_MENU_ITEM
  - requirements/rules#editor-suggestions
proposal: null
task: 4yq7xbae
origin: null
critical: false
option: 1
note: null
resolvedBy: fz9axufm
created: 2026-10-12T10:48:44.886Z
---
# Table entry of the block menu: the Model deletes the whole section

## What happens

Scegliendo **Tabella** dal menu rapido, il sistema toglie soltanto la «/» dalla riga corrente e inserisce la tabella dopo la sezione. Il testo già scritto nella sezione resta dov'è, come per le altre voci del menu.

## What should happen

Il Modello dice che scegliendo **Tabella** viene eliminata **l'intera sezione di testo**, comprese le righe scritte dopo la «/», e poi inserita la tabella. Le regole dei Requisiti dicono invece che una voce toglie soltanto la «/» dalla riga corrente. La correzione precedente di questo punto (Drift n36a1c1s, risolta con la Proposal 3pikg137) ha scelto il comportamento del codice, ma la transizione del Modello non è stata aggiornata.

## Fix options

### Aggiornare il Modello al comportamento attuale

La transizione di **Tabella** diventa: la voce toglie solo la «/» dalla riga corrente e inserisce la tabella dopo la sezione, come già deciso e come dicono i Requisiti. Nessun testo viene perso e il codice resta com'è. Costo: una piccola modifica del Modello, da fare con una Proposal; la tabella non compare esattamente nel punto del cursore se la sezione ha altre righe.

### Eliminare la sezione come dice il Modello

Quando si sceglie **Tabella** il codice torna a eliminare l'intera sezione di testo, comprese le righe scritte dopo la «/». Il Modello resta com'è. Costo: si perde il testo già scritto nella sezione, come segnalato nella correzione precedente, e la regola dei Requisiti non viene più seguita.

### Dividere la sezione alla «/»

Il testo prima della riga con la «/» resta sopra, la tabella compare nel punto giusto e le righe successive passano in una nuova sezione di testo. Il Modello va aggiornato in questo senso. Costo: più lavoro sulla divisione delle sezioni e più casi da controllare, ma nessun testo viene perso.

## Where in the code

lib/ui/editor/notion_document_editor.dart, _buildSlashMenu: la voce Tabella (onTap), che chiama la rimozione della «/» e poi insertTable
