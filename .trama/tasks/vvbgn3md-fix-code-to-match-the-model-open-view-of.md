---
column: done
technical: false
refs:
  - folder/User folder/supabase.REMOTE_FOLDER_DELETED
  - folder/User folder/sync-run.CLOUD_FOLDER_REMOVED
drift: wf86lafo
proposal: null
agent: false
created: 2026-10-17T13:41:35.366Z
finished: 2026-10-17T13:47:16.253Z
---
# Fix code to match the Model: Open view of a folder deleted elsewhere is titled as another view

## What happens

Quando una cartella aperta viene eliminata altrove, la vista resta su quella cartella ma il titolo della barra cambia: su desktop mostra «Tutte le note», su mobile mostra «Note». L'elenco è vuoto, perché le note sono passate alla cartella Note. Il titolo quindi indica un'altra vista.

## What should happen

Il Model dice che la vista resta su quella cartella e non emette DELETED, quindi non passa a «Tutte le note». Non dice però quale titolo deve mostrare una vista la cui cartella non esiste più. Il codice risolve il caso in modi diversi su desktop e mobile, e nessuno dei due corrisponde alla vista aperta.

## Chosen option

**Mantenere l'ultimo nome della cartella aperta**

Il titolo resta quello che la cartella aveva quando la vista è stata aperta, su entrambe le piattaforme. Costa: il provider deve ricordare il nome dell'ultima cartella aperta; l'utente vede un nome di cartella che non esiste più.

## Where in the code

lib/ui/shell/mac_title_bar.dart (titolo della barra su desktop, con fallback a «Tutte le note»); lib/ui/mobile/mobile_notes_list_screen.dart (titolo della schermata lista su mobile, con fallback a «Note»)
