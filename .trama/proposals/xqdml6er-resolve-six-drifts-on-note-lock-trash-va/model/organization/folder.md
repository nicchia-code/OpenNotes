# Folder

Una cartella in cui l'utente raccoglie le note. Ci sono le cartelle create dall'utente e la cartella di sistema "Note", che accoglie le note senza altra collocazione. "Tutte le note", "Eliminati di recente" e "Note rapide" non sono cartelle memorizzate ma viste del navigatore delle note. Le cartelle non hanno sottocartelle nella barra laterale e nelle liste: tutte compaiono allo stesso livello; solo il selettore «Sposta in…» le mostra ad albero, secondo la cartella superiore.

## States

### New (initial)
La cartella non esiste ancora sul dispositivo.
- `operating-system.APP_LAUNCHED` → System: solo al primo avvio, quando l'archivio locale viene creato; nasce la cartella di sistema "Note", che esiste solo sul dispositivo.
- `user.CREATE_FOLDER` → User folder: solo con un nome non vuoto, ripulito dagli spazi agli estremi; non c'è controllo sui nomi doppi; la cartella nasce senza cartella superiore, viene messa in coda per l'invio al cloud e, se un utente è connesso, parte una sincronizzazione.
- `supabase.REMOTE_FOLDER_CHANGED` → User folder: una cartella creata altrove arriva in tempo reale e viene salvata così com'è.
- `sync-run.FINISHED` → User folder: solo se la sincronizzazione ha scaricato dal cloud una cartella non eliminata che sul dispositivo non c'era.

### User folder
La cartella compare nella barra laterale e nella schermata Cartelle e può contenere note.
- `user.RENAME_FOLDER` → User folder: solo su mobile, dal menu della pressione prolungata; il nuovo nome non può essere vuoto ed è ripulito dagli spazi agli estremi; aggiorna la data di modifica; la modifica viene messa in coda per il cloud e, se un utente è connesso, parte una sincronizzazione.
- `supabase.REMOTE_FOLDER_CHANGED` → User folder: la versione remota sostituisce quella locale, salvo che il dispositivo abbia una modifica della cartella in attesa successiva a quella del cloud: vince l'ultima modifica.
- `sync-run.FINISHED` → User folder: se la sincronizzazione ha scaricato una nuova versione della cartella, questa sostituisce quella locale alle stesse condizioni della modifica ricevuta in tempo reale.
- `user.DELETE_FOLDER` → Deleted: su desktop dal menu della cartella, senza conferma; su mobile scorrendo la riga o dal menu della pressione prolungata, dopo una conferma che avvisa che le note verranno eliminate; in realtà tutte le note contenute, anche quelle nel cestino, passano nella cartella "Note" senza cambiare la data di modifica, e ognuna viene messa in coda per il cloud; anche l'eliminazione della cartella viene messa in coda e, se un utente è connesso, parte una sincronizzazione; emette DELETED. Se il cloud ha modificato la cartella dopo l'eliminazione, l'eliminazione viene scartata e la cartella torna con il download.
- `supabase.REMOTE_FOLDER_DELETED` → Deleted: la cartella è stata eliminata altrove, salvo che il dispositivo ne abbia una modifica in attesa successiva all'eliminazione, nel qual caso resta e rinascerà sul cloud; le sue note, anche quelle nel cestino, passano nella cartella "Note" senza essere messe in coda; non emette DELETED, quindi una vista aperta su questa cartella resta su di essa.
- `sync-run.CLOUD_FOLDER_REMOVED` → Deleted: la sincronizzazione ha scaricato l'eliminazione della cartella fatta altrove, alle stesse condizioni dell'eliminazione ricevuta in tempo reale, oppure il controllo completo ha trovato che il cloud non la ha più; le sue note passano nella cartella "Note" senza essere messe in coda; non emette DELETED.

### System
La cartella "Note": compare come voce fissa sotto "Tutte le note", non si può eliminare né rinominare e non viene mai inviata al cloud.

### Deleted (final)

## Events

### DELETED
Emesso quando l'utente elimina una cartella sul dispositivo, dopo che le sue note sono passate nella cartella "Note".
