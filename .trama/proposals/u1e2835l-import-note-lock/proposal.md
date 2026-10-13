---
status: approved
kind: import
requires:
  - eibfecxn
base:
  note-lock/feature.md: new
  note-lock/master-pin.md: new
  note-lock/note-access.md: new
  requirements/data/note-lock.md: new
  requirements/rules/note-lock.md: new
delete: []
created: 2026-10-12T06:57:35.207Z
---
# Import: Note lock

Importazione della Feature note-lock dal codice: PIN principale e accesso alle note protette, sbloccate per la sessione. Fonti: lib/core/services/security_service.dart, lib/ui/security/lock_note_dialog.dart, lib/ui/notes_list/note_actions.dart, note_card.dart, schermate dell'editor, lib/core/models/note_model.dart.

## Doubts

- Il commento dice che le note si riproteggono quando l'app va in secondo piano, ma il metodo di riblocco generale non è mai chiamato e non c'è alcun osservatore del ciclo di vita dell'app: lo sblocco dura fino alla chiusura (lib/core/services/security_service.dart:51-55; nessun uso in lib/).
- Il commento dice "Sets or updates the master PIN", ma la creazione del PIN si apre solo quando il PIN non esiste: il PIN non si può cambiare né rimuovere dall'app (lib/core/services/security_service.dart:28; lib/ui/notes_list/note_actions.dart:79-80; lib/ui/mobile/mobile_note_editor_screen.dart:84-86).
- Il contenuto delle note protette è salvato e sincronizzato in chiaro: database locale, file Markdown del vault (solo il flag `locked` nel front matter) e Supabase; la protezione è solo nell'interfaccia (lib/core/services/vault_service.dart:126; supabase/schema.sql:30; lib/core/state/notes_provider.dart:329-331).
- L'impronta del PIN resta solo nelle preferenze locali: una nota protetta che arriva da un altro dispositivo o dal vault su un dispositivo senza PIN non può essere né aperta né sprotetta (la verifica fallisce sempre) finché l'utente non crea un PIN proteggendo un'altra nota; con PIN diversi per dispositivo vale il PIN locale (lib/core/services/security_service.dart:38-42).
- Se una nota sbloccata nella sessione viene sprotetta e poi riprotetta, resta nell'insieme degli sblocchi e il contenuto resta visibile senza PIN (lib/core/state/notes_provider.dart:320-333 non tocca gli sblocchi; lib/core/services/security_service.dart:46-49).
- Duplicare, condividere, esportare ed eliminare definitivamente chiedono il PIN anche se la nota è già sbloccata per la sessione, perché il controllo guarda solo il flag della nota (lib/ui/notes_list/note_actions.dart:59-65, 151-156): non è chiaro se sia voluto.
- Svuota cestino chiede il PIN solo se una nota protetta è nell'elenco mostrato (filtrato dalla ricerca), ma poi elimina tutte le note nel cestino: con una ricerca attiva le note protette nascoste vengono eliminate senza PIN (lib/ui/notes_list/notes_list_view.dart:353; lib/ui/mobile/mobile_notes_list_screen.dart:85; lib/core/state/notes_provider.dart:452-453; filtro ricerca in lib/core/state/notes_provider.dart:144).
- La ricerca confronta anche il contenuto delle note protette e ne mostra il titolo nei risultati, rivelando cosa contengono (lib/core/services/database_service.dart:161-165); il titolo è sempre visibile nell'elenco (lib/ui/notes_list/note_card.dart:95).
- I comandi della barra degli strumenti (tabella, immagine, disegno) restano attivi e modificano il contenuto di una nota protetta non sbloccata, che viene salvato anche se nascosto [INFERENCE: lo stato dell'editor esiste anche dietro l'avviso] (lib/ui/editor/notion_document_editor.dart:793-823, 837-855, 868; lib/ui/shell/mac_title_bar.dart:480-493).
- Il messaggio dice "almeno 4 cifre" ma la regola conta caratteri qualsiasi dopo il trim (lib/ui/security/lock_note_dialog.dart:136-142); nessun limite ai tentativi di PIN e impronta SHA-256 senza sale di un PIN corto (lib/core/services/security_service.dart:23-26; lib/ui/security/lock_note_dialog.dart:60-70).
- Su desktop il pulsante lucchetto della barra del titolo agisce sulla nota selezionata anche quando è nel cestino, mentre il menu della nota nel cestino non offre il lucchetto (lib/ui/shell/adaptive_app_shell.dart:119-124; lib/ui/notes_list/note_action_menu.dart:18-23) [INFERENCE: non verificato se il pulsante sia nascosto nella vista cestino].
- Il codice per esportare in PDF non controlla il lucchetto, ma non risulta chiamato da nessuna parte (lib/core/services/pdf_export_service.dart:9).
