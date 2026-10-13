---
status: approved
kind: import
requires:
  - eibfecxn
base:
  navigation/feature.md: new
  navigation/desktop-layout.md: new
  navigation/mobile-navigation.md: new
  navigation/app-window.md: new
  requirements/rules/navigation.md: new
delete: []
created: 2026-10-12T06:57:35.655Z
---
# Import: Navigation

Importazione della Feature navigation dal codice: disposizione desktop con barra laterale e colonne, passaggio al layout mobile in base alla larghezza, pila di schermate mobile e controlli della finestra desktop senza cornice. Fonti: lib/ui/shell/adaptive_app_shell.dart, mac_title_bar.dart, lib/ui/mobile/, lib/ui/notes_list/notes_list_view.dart, lib/main.dart, test/mobile_ui_test.dart, test/widget_test.dart.

## Doubts

- La dimensione minima della finestra (640 px, lib/main.dart:26) è sotto la soglia desktop (680 px, lib/ui/shell/adaptive_app_shell.dart:79): una finestra desktop può finire in interfaccia mobile, dove non c'è la barra superiore e quindi, con la barra di sistema nascosta (lib/main.dart:30), nessun modo per spostare, ridurre o chiudere la finestra da Linux/Windows. Voluto?
- Ogni passaggio sotto 680 px crea una pila mobile nuova che riparte dalla lista note (lib/ui/shell/adaptive_app_shell.dart:196-232); tornando sopra la pila viene scartata: un editor aperto o un disegno non salvato su mobile vanno persi a ogni ridimensionamento/rotazione che attraversa la soglia.
- La scelta manuale della barra laterale non torna mai automatica nella sessione (lib/ui/shell/adaptive_app_shell.dart:29,100,110): dopo un solo clic la barra ignora la larghezza per sempre. Voluto?
- Bug: toccando un tag nelle Cartelle mobile il tag viene applicato due volte (lib/ui/mobile/mobile_folders_screen.dart:186 e lib/ui/shell/adaptive_app_shell.dart:213); la seconda volta lo toglie, quindi la lista mostra Tutte le note invece del tag. Anche cartelle, Tutte le note e cestino vengono selezionati due volte (mobile_folders_screen.dart:75-76,89-90,157-158,211-212 e adaptive_app_shell.dart:210), innocuo ma ridondante.
- Bug: con una nota protetta, se lo sblocco per Duplica viene annullato, il menu mobile chiama comunque il seguito della duplicazione con la nota selezionata (lib/ui/notes_list/note_actions.dart:26-29): dalla lista si apre l'editor dell'originale, dall'editor l'editor viene sostituito con sé stesso (lib/ui/mobile/mobile_note_editor_screen.dart:100-109).
- Codice morto: il parametro di ritorno dell'editor mobile `onBack` non viene mai passato dalla shell (lib/ui/mobile/mobile_note_editor_screen.dart:22; costruttori in lib/ui/shell/adaptive_app_shell.dart:222,255,271); idem `onNoteSelected` della lista desktop (lib/ui/notes_list/notes_list_view.dart:15, istanziata senza in adaptive_app_shell.dart:147) e `onFolderSelected` della barra laterale (lib/ui/sidebar/sidebar_view.dart:15, istanziata senza in adaptive_app_shell.dart:144).
- La ricerca resta attiva nella selezione quando le schermate vengono ricreate (lib/core/state/notes_provider.dart:208, non azzerata da selectFolder a :160), ma il campo di ricerca della lista mobile e di quella desktop riparte vuoto (lib/ui/mobile/mobile_notes_list_screen.dart:32, lib/ui/notes_list/notes_list_view.dart:24): dopo indietro e riapertura, o un cambio di interfaccia, la lista resta filtrata da un testo invisibile.
- L'etichetta di ritorno dall'editor aperto dalla lista dice "Note" anche per Tutte le note e per le cartelle dell'utente (lib/ui/shell/adaptive_app_shell.dart:257-261), mentre il titolo della lista usa il nome della cartella (lib/ui/mobile/mobile_notes_list_screen.dart:40-56).
- Soglie della barra superiore misurate sulla larghezza utile (finestra meno 28 px, lib/ui/shell/mac_title_bar.dart:68,80-81): poiché la barra esiste solo da 680 px, il menu "Inserisci" (sotto 660 px utili) compare solo per finestre larghe 680-687 px; quasi codice morto.
- [INFERENCE] La pila mobile è un navigatore annidato senza gestione del tasto indietro di sistema (lib/ui/shell/adaptive_app_shell.dart:196): su Android il tasto indietro probabilmente chiude l'app invece di tornare alla schermata precedente. Non verificato.
- Se la nota aperta nell'editor mobile sparisce dai dati (es. eliminata da un altro dispositivo) l'editor resta aperto sulla copia vecchia (lib/ui/mobile/mobile_note_editor_screen.dart:123-126) invece di chiudersi.
- Su macOS i pulsanti nativi di chiusura/riduzione non passano dall'app (lib/ui/shell/mac_title_bar.dart:88-89): il comportamento di chiusura su macOS (app che termina o resta attiva) non è determinabile dal codice.
- Nessun test copre la navigazione: test/widget_test.dart prova solo la scheda nota e test/mobile_ui_test.dart solo la barra strumenti sopra la tastiera.
