---
column: done
technical: false
refs:
  - note-editor/Open/user.PICK_BLOCK_MENU_ITEM
  - requirements/rules#editor-suggestions
drift: e74gvobo
proposal: null
agent: false
created: 2026-10-12T10:59:40.580Z
finished: 2026-10-12T13:55:40.788Z
---
# Fix code to match the Model: Table entry of the block menu: the Model deletes the whole section

## What happens

Scegliendo **Tabella** dal menu rapido, il sistema toglie soltanto la «/» dalla riga corrente e inserisce la tabella dopo la sezione. Il testo già scritto nella sezione resta dov'è, come per le altre voci del menu.

## What should happen

Il Modello dice che scegliendo **Tabella** viene eliminata **l'intera sezione di testo**, comprese le righe scritte dopo la «/», e poi inserita la tabella. Le regole dei Requisiti dicono invece che una voce toglie soltanto la «/» dalla riga corrente. La correzione precedente di questo punto (Drift n36a1c1s, risolta con la Proposal 3pikg137) ha scelto il comportamento del codice, ma la transizione del Modello non è stata aggiornata.

## Chosen option

**Aggiornare il Modello al comportamento attuale**

La transizione di **Tabella** diventa: la voce toglie solo la «/» dalla riga corrente e inserisce la tabella dopo la sezione, come già deciso e come dicono i Requisiti. Nessun testo viene perso e il codice resta com'è. Costo: una piccola modifica del Modello, da fare con una Proposal; la tabella non compare esattamente nel punto del cursore se la sezione ha altre righe.

## Where in the code

lib/ui/editor/notion_document_editor.dart, _buildSlashMenu: la voce Tabella (onTap), che chiama la rimozione della «/» e poi insertTable
