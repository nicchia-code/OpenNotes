---
column: done
technical: false
refs:
  - note/Unpinned/user.MOVE_NOTE_TO_FOLDER
drift: null
proposal: null
agent: false
created: 2026-10-12T14:52:05.992Z
finished: 2026-10-12T16:30:34.777Z
---
# Fix code to match the Requirements: Folder picker misplaces orphaned subfolders outside the tree

## What happens

Nel selettore «Sposta in…» le cartelle orfane, cioè quelle la cui cartella superiore non esiste più sul dispositivo (succede dopo un'eliminazione locale, finché la sincronizzazione non riallinea le sottocartelle, e anche da offline), non vengono messe in fondo come albero: ogni orfana viene aggiunta alla fine nell'ordine dell'archivio, e le sue sottocartelle restano in quell'ordine invece di seguire il loro genitore. Le sottocartelle e le orfane sono ordinate con il confronto binario di SQLite (maiuscole prima) invece che per nome senza distinzione tra maiuscole e minuscole. Inoltre ogni orfana viene rientrata di un livello, come se avesse un genitore visibile.

## What should happen

Il Requirement dice che il selettore mostra le cartelle ad albero secondo la cartella superiore, con i fratelli ordinati per nome senza distinzione tra maiuscole e minuscole e rientro proporzionale alla profondità, e che le cartelle orfane vanno in fondo. Quindi: le orfane, con il loro sottoalbero, stanno in fondo al selettore come albero; i fratelli di ogni livello, orfane comprese, sono ordinati per nome senza distinzione tra maiuscole e minuscole; un'orfana è mostrata come radice, senza rientro, e ogni sottocartella rientra in base alla sua profondità nell'albero mostrato.

## Where in the code

lib/ui/notes_list/folder_picker.dart (_orderedFolders, _depth)
