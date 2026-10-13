---
status: approved
kind: import
requires:
  - eibfecxn
  - bg03sfzb
  - u1e2835l
  - 3b5s3tbv
base:
  editor/feature.md: new
  editor/note-editor.md: new
  editor/text-line.md: new
  editor/editor-suggestions.md: new
  editor/drawing-canvas.md: new
  editor/note-content-save.md: new
  requirements/data/editor.md: new
  requirements/rules/editor.md: new
delete: []
created: 2026-10-12T06:57:41.547Z
---
# Import: Editor

Importazione della Feature editor dal codice: sessione di modifica della nota, righe di testo con stili e scorciatoie Markdown, suggerimenti di tag e menu rapido, tela da disegno, salvataggio rimandato del contenuto. Fonti: lib/ui/editor/, lib/core/models/style_span.dart, lib/core/models/note_model.dart, lib/ui/drawing/apple_pencil_canvas.dart, lib/ui/mobile/mobile_note_editor_screen.dart, mobile_keyboard_accessory_bar.dart, lib/ui/shell/, lib/core/state/notes_provider.dart, test/notion_editor_test.dart, test/rich_text_editor_test.dart, test/markdown_controller_test.dart, test/markdown_render_test.dart.

## Doubts

- lib/ui/editor/notion_document_editor.dart:166-176 e 192-198: quando si cambia nota o si chiude l'editor (indietro su mobile), l'attesa di 300 ms viene annullata senza salvare. Le modifiche digitate negli ultimi 300 ms vanno perse.
- lib/core/state/notes_provider.dart:294-300: il timer di 400 ms è unico per tutte le note. Se si modifica un'altra nota entro 400 ms, la versione in attesa della prima non viene mai scritta su database, vault e sincronizzazione: resta solo in memoria. Il salvataggio in attesa non viene forzato nemmeno alla chiusura o con l'app in background (dispose a 512 annulla il timer).
- lib/core/state/notes_provider.dart:271-275: un contenuto consegnato per una nota che non è nell'elenco filtrato corrente (cartella, tag o ricerca) viene ignorato in silenzio.
- lib/ui/editor/notion_document_editor.dart:177-189: se una riga ha il focus, una versione remota della nota aperta viene ignorata e il salvataggio locale successivo la sovrascrive. Non c'è nessuna gestione dei conflitti.
- lib/ui/shell/mac_title_bar.dart:173 e lib/ui/mobile/mobile_note_editor_screen.dart:193-204: la barra degli strumenti e quella sopra la tastiera restano attive anche quando la nota è protetta e nascosta. I comandi dell'editor (notion_document_editor.dart:583-859) non controllano la protezione: inserire tabelle, foto, disegni, checklist o cambiare stile modifica e salva il contenuto nascosto. Anche il grassetto senza testo mostrato salva e aggiorna la data di modifica.
- lib/ui/editor/notion_document_editor.dart:868: l'editor controlla solo la protezione. Una nota nel cestino resta modificabile (su desktop si nasconde solo la barra degli strumenti, mac_title_bar.dart:173).
- lib/ui/editor/notion_document_editor.dart:1416-1423: la voce «Tabella» del menu rapido elimina l'intera sezione di testo in cui è stata digitata la barra, quindi di solito tutto il testo della nota, prima di inserire la tabella. Sembra un bug grave.
- lib/ui/editor/notion_document_editor.dart:1562 e 1838-1846: il menu rapido compare solo se l'intera sezione di testo comincia con «/», cioè in pratica solo sulla prima riga della nota. Invece la trasformazione toglie «/parola» dalla riga del cursore.
- lib/ui/editor/notion_document_editor.dart:227-380 e 803-853: al caricamento tutto il testo consecutivo si fonde in una sola sezione, quindi tabelle e immagini vengono inserite dopo l'intera sezione attiva e non nel punto del cursore.
- lib/ui/editor/notion_document_editor.dart:2047-2051: non c'è nessun modo di eliminare una tabella. Backspace dopo una tabella o un'immagine non fa nulla, perché tabelle e immagini non hanno un focus.
- lib/ui/editor/notion_document_editor.dart:1129-1136, 1205-1296, 1255-1263, 1854-1881, 1981-2003: questo codice gestisce blocchi testuali tipizzati (checklist con cerchio separato, elenco numerato contato per blocchi, Backspace su un blocco tipizzato vuoto, trasformazione di un blocco senza controller). Dato che al caricamento ogni sezione di testo diventa paragraph, sembra codice morto [INFERENCE].
- Codice morto o non collegato:
  - lib/ui/editor/markdown_editing_controller.dart è usato solo da test/markdown_controller_test.dart;
  - la modalità anteprima (notion_document_editor.dart:130-155) non viene mai attivata;
  - insertHeading, indent e outdent (742-790) non hanno chiamanti;
  - i separatori (divider) vengono solo letti, nessun comando li crea;
  - test/markdown_render_test.dart prova solo lo stylesheet di flutter_markdown, non il codice dell'app.
- lib/ui/editor/rich_text_editing_controller.dart:470 e 799: con Invio su una voce fatta vuota e rientrata, o con Backspace dopo il cerchio di una voce fatta rientrata, il rientro si riduce ma la voce torna da fare («○»). Non è chiaro se sia voluto.
- lib/ui/editor/rich_text_editing_controller.dart:776-862: Backspace subito dopo il numero di una voce numerata non ha la gestione che hanno voci puntate e checklist. Potrebbe essere un caso mancante.
- lib/ui/editor/rich_text_editing_controller.dart:373 e notion_document_editor.dart:289-291, 478-480: «# » digitato produce sempre un'intestazione 1, anche sulla prima riga. Lo stesso prefisso al caricamento produce invece il titolo sulla prima riga della sezione.
- lib/ui/editor/notion_document_editor.dart:652 e rich_text_editing_controller.dart:890-891: «Aa» toglie i prefissi prima di applicarli, quindi la logica di applyLinePrefix che toglie il prefisso se è già presente non scatta mai. Scegliere due volte lo stesso elenco non lo toglie.
- lib/ui/editor/rich_text_editing_controller.dart:222-246, 753-766, 902-916: removeLinePrefixes, handleTabKey e applyLinePrefix spostano a mano gli intervalli di formattazione e poi impostano il valore. Il listener (250-269) potrebbe spostarli una seconda volta. Non è verificato [INFERENCE].
- lib/core/models/note_model.dart:90-98: ora tutto il testo è un solo blocco paragraph, quindi il titolo è la prima riga del blocco. Se la prima riga è vuota il titolo diventa vuoto. Il controllo «solo tag» guarda l'intero blocco e non la riga, e lo stile di riga `title` viene ignorato.
- lib/ui/drawing/apple_pencil_canvas.dart:49-73: «Fine» salva anche una tela vuota. La gomma usa la fusione «clear» anche nell'esportazione, quindi le zone cancellate potrebbero diventare trasparenti invece che bianche [INFERENCE]. Lo spessore della penna è fisso a 3 e non si può regolare.
- lib/core/services/security_service.dart:52-55: lockAll, che secondo il commento rinchiude le note quando l'app va in background, non ha chiamanti. Una nota sbloccata resta visibile nell'editor per tutta la sessione.
- lib/ui/editor/notion_document_editor.dart:1338-1344: rimuovere un'immagine lascia separate le sezioni di testo vicine fino al caricamento successivo, che poi le fonde. Il file allegato non viene mai cancellato dal vault.
