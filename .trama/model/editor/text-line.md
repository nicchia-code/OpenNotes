# Text line

Una riga di una sezione di testo del documento. Il suo tipo viene da uno stile memorizzato (corpo, titolo, intestazioni) oppure dal simbolo con cui la riga comincia (voce puntata, voce numerata, voce di checklist, citazione, monospazio). Il rientro è di due spazi per livello e sta prima del simbolo: una voce numerata, una citazione o una riga monospazio rientrate restano dello stesso tipo, anche quando la nota viene riaperta. Quando uno stile o il pulsante checklist tolgono i simboli iniziali, tolgono solo segni seguiti da uno spazio («# », «## », «### », «- », «* », «> », un numero con punto e spazio, i simboli di elenco e i cerchi di checklist) oppure i tre apici inversi insieme all'eventuale spazio che li segue; un segno senza spazio, come in «#lavoro», «-5 gradi» o «1.5 volte», fa parte del testo e resta. Le righe caricate da una nota esistente partono nel tipo dello stile salvato, oppure dei simboli di elenco e di checklist. Una riga che comincia con un numero e un punto, con il segno di citazione o con tre apici inversi e non ha uno stile salvato parte come corpo, con il segno nel testo, e diventa voce numerata, citazione o monospazio alla prima modifica del testo della sua sezione; intanto una citazione o una riga monospazio ne hanno già l'aspetto.

## States

### In document (initial)
- `user.SET_TEXT_STYLE` → Title: se si sceglie «Titolo». Prima toglie dalla riga qualunque simbolo iniziale.
- `user.SET_TEXT_STYLE` → Heading 1: se si sceglie «Intestazione». Prima toglie qualunque simbolo iniziale.
- `user.SET_TEXT_STYLE` → Heading 2: se si sceglie «Sottointestazione». Prima toglie qualunque simbolo iniziale.
- `user.SET_TEXT_STYLE` → Body: se si sceglie «Corpo». Toglie qualunque simbolo iniziale.
- `user.SET_TEXT_STYLE` → Bulleted item: se si sceglie l'elenco puntato. Toglie i simboli esistenti e mette davanti il simbolo del livello di rientro della riga.
- `user.SET_TEXT_STYLE` → Numbered item: se si sceglie l'elenco numerato. Toglie i simboli esistenti e mette davanti «1.».
- `user.SET_TEXT_STYLE` → Unchecked: se si sceglie «Checklist». Toglie i simboli esistenti e mette davanti un cerchio vuoto.
- `user.SET_TEXT_STYLE` → Quote: se si sceglie «Citazione». Toglie i simboli esistenti e mette davanti il segno di citazione.
- `user.SET_TEXT_STYLE` → Monospace: se si sceglie «Monospazio». Toglie i simboli esistenti e mette davanti il segno di monospazio.
- `user.PICK_BLOCK_MENU_ITEM` → Unchecked: se si sceglie «Checklist».
- `user.PICK_BLOCK_MENU_ITEM` → Heading 1: se si sceglie «Intestazione».
- `user.PICK_BLOCK_MENU_ITEM` → Heading 2: se si sceglie «Sottointestazione».
- `user.PICK_BLOCK_MENU_ITEM` → Bulleted item: se si sceglie «Elenco».
- `user.PICK_BLOCK_MENU_ITEM` → Numbered item: se si sceglie «Numerato».
- `user.PICK_BLOCK_MENU_ITEM` → Quote: se si sceglie «Citazione».
- `user.TOGGLE_CHECKLIST` → Unchecked: se il cursore è sulla riga e questa non è già una voce di checklist. Toglie l'eventuale simbolo e mette davanti un cerchio vuoto.
- `user.EDIT_NOTE_TEXT` → Removed: se la riga viene cancellata o unita a un'altra cancellando una selezione.
- `user.PRESS_BACKSPACE_IN_TEXT` → Removed: se il cursore è all'inizio della riga, prima di ogni simbolo. La riga si unisce alla precedente, anche se questa è l'ultima riga della sezione di testo precedente.

#### Body (initial)
Una riga di testo normale.
- `user.EDIT_NOTE_TEXT` → Heading 1: se la riga comincia con «# », senza rientro. Il prefisso viene tolto, anche sulla prima riga della nota.
- `user.EDIT_NOTE_TEXT` → Heading 2: se la riga comincia con «## », senza rientro. Il prefisso viene tolto.
- `user.EDIT_NOTE_TEXT` → Heading 3: se la riga comincia con «### », senza rientro. Il prefisso viene tolto.
- `user.EDIT_NOTE_TEXT` → Unchecked: se la riga comincia con una casella vuota tra parentesi quadre seguita da spazio, con davanti al più un trattino, un asterisco o un punto. Tutto questo diventa un cerchio vuoto.
- `user.EDIT_NOTE_TEXT` → Checked: se la riga comincia con una casella spuntata con «x» tra parentesi quadre seguita da spazio. Diventa un cerchio pieno.
- `user.EDIT_NOTE_TEXT` → Bulleted item: se la riga, anche rientrata, comincia con trattino o asterisco seguiti da spazio e poi non da una parentesi quadra o da un cerchio. Il segno diventa il simbolo del livello di rientro.
- `user.EDIT_NOTE_TEXT` → Numbered item: se la riga, anche rientrata, comincia con un numero seguito da un punto. Il testo resta com'è.
- `user.EDIT_NOTE_TEXT` → Quote: se la riga, anche rientrata, comincia con il segno di citazione seguito da spazio.
- `user.EDIT_NOTE_TEXT` → Monospace: se la riga, anche rientrata, comincia con tre apici inversi.
- `user.PRESS_TAB_IN_TEXT` → Body: aggiunge due spazi di rientro, o con Maiuscole ne toglie fino a due.

#### Heading
Una riga con stile di titolo o intestazione. Lo stile è memorizzato a parte dal testo.
- Invio a fine riga crea sotto una riga di corpo. Invio all'inizio di una riga che ha testo sposta lo stile insieme al testo e lascia sopra una riga di corpo vuota.

##### Title
Il titolo della nota. Lo ricevono al caricamento la prima riga di una sezione che comincia con «# » e la prima riga significativa di una nota in formato precedente.

##### Heading 1 (initial)

##### Heading 2

##### Heading 3

#### Bulleted item
Il simbolo dipende dal livello di rientro: punto pieno, cerchio vuoto, quadratino, poi si ricomincia.
- `user.PRESS_ENTER_IN_TEXT` → Bulleted item: se la voce ha testo. Crea sotto una nuova voce con lo stesso rientro.
- `user.PRESS_ENTER_IN_TEXT` → Bulleted item: se la voce è vuota e rientrata. Riduce il rientro di un livello.
- `user.PRESS_ENTER_IN_TEXT` → Body: se la voce è vuota e non rientrata. Toglie il simbolo.
- `user.PRESS_BACKSPACE_IN_TEXT` → Bulleted item: se il cursore è subito dopo il simbolo e la voce è rientrata. Riduce il rientro di un livello.
- `user.PRESS_BACKSPACE_IN_TEXT` → Body: se il cursore è subito dopo il simbolo e la voce non è rientrata. Toglie il simbolo e il testo resta.
- `user.PRESS_TAB_IN_TEXT` → Bulleted item: aumenta il rientro di un livello, o con Maiuscole lo riduce se c'è, e aggiorna il simbolo.
- `user.PRESS_TAB_IN_TEXT` → Body: con Maiuscole, se la voce non è rientrata. Toglie il simbolo.
- `user.EDIT_NOTE_TEXT` → Body: se il simbolo iniziale viene cancellato.

#### Numbered item
- `user.PRESS_ENTER_IN_TEXT` → Numbered item: se la voce ha testo. Crea sotto una nuova voce con il numero successivo e lo stesso rientro.
- `user.PRESS_ENTER_IN_TEXT` → Numbered item: se la voce è vuota e rientrata. Riduce il rientro di un livello e tiene lo stesso numero.
- `user.PRESS_ENTER_IN_TEXT` → Body: se la voce è vuota e non rientrata. Toglie il numero.
- `user.PRESS_TAB_IN_TEXT` → Numbered item: aumenta il rientro di un livello, o con Maiuscole lo riduce se c'è.
- `user.PRESS_TAB_IN_TEXT` → Body: con Maiuscole, se la voce non è rientrata. Toglie il numero.
- `user.EDIT_NOTE_TEXT` → Body: se il numero iniziale viene cancellato.

#### Checklist item
Una voce che comincia con un cerchio. Il testo di una voce fatta appare barrato e attenuato.
- `user.PRESS_ENTER_IN_TEXT` → Unchecked: se la voce è vuota e rientrata. Riduce il rientro di un livello e la voce torna da fare.
- `user.PRESS_ENTER_IN_TEXT` → Body: se la voce è vuota e non rientrata. Toglie il cerchio.
- `user.PRESS_BACKSPACE_IN_TEXT` → Unchecked: se il cursore è subito dopo il cerchio e la voce è rientrata. Riduce il rientro di un livello e la voce torna da fare.
- `user.PRESS_BACKSPACE_IN_TEXT` → Body: se il cursore è subito dopo il cerchio e la voce non è rientrata. Toglie il cerchio e il testo resta.
- `user.PRESS_TAB_IN_TEXT` → Body: con Maiuscole, se la voce non è rientrata. Toglie il cerchio.
- `user.EDIT_NOTE_TEXT` → Body: se il cerchio iniziale viene cancellato.

##### Unchecked (initial)
La voce è da fare (cerchio vuoto).
- `user.TAP_CHECKBOX` → Checked: se il tocco cade sul cerchio o sul carattere subito dopo, e sono passati almeno 250 ms dall'ultimo cambio fatto con un tocco su questa sezione.
- `user.TOGGLE_CHECKLIST` → Checked: se il cursore è sulla riga.
- `user.PRESS_ENTER_IN_TEXT` → Unchecked: se la voce ha testo. Crea sotto una nuova voce da fare con lo stesso rientro.
- `user.PRESS_TAB_IN_TEXT` → Unchecked: aumenta il rientro di un livello, o con Maiuscole lo riduce se c'è.

##### Checked
La voce è fatta (cerchio pieno).
- `user.TAP_CHECKBOX` → Unchecked: se il tocco cade sul cerchio o sul carattere subito dopo, e sono passati almeno 250 ms dall'ultimo cambio fatto con un tocco su questa sezione.
- `user.TOGGLE_CHECKLIST` → Unchecked: se il cursore è sulla riga.
- `user.PRESS_ENTER_IN_TEXT` → Checked: se la voce ha testo. Crea sotto una nuova voce da fare con lo stesso rientro.
- `user.PRESS_TAB_IN_TEXT` → Checked: aumenta il rientro di un livello, o con Maiuscole lo riduce se c'è.

#### Quote
Una riga che comincia con il segno di citazione.
- `user.EDIT_NOTE_TEXT` → Body: se il segno iniziale viene cancellato.
- `user.PRESS_TAB_IN_TEXT` → Quote: aggiunge due spazi di rientro prima del segno, o con Maiuscole ne toglie fino a due; la riga resta una citazione.

#### Monospace
Una riga che comincia con tre apici inversi, mostrata in carattere a spaziatura fissa.
- `user.EDIT_NOTE_TEXT` → Body: se gli apici iniziali vengono cancellati.
- `user.PRESS_TAB_IN_TEXT` → Monospace: aggiunge due spazi di rientro prima degli apici, o con Maiuscole ne toglie fino a due; la riga resta monospazio.

### Removed (final)
La riga non esiste più nel documento.
