---
status: approved
kind: import
requires:
  - eibfecxn
  - 4a0aesyv
base:
  export/feature.md: new
  export/export-markdown-share.md: new
  export/export-markdown-file.md: new
  export/export-pdf.md: new
  export/vault-file.md: new
  requirements/data/export.md: new
  requirements/rules/export.md: new
delete: []
created: 2026-10-12T06:57:42.672Z
---
# Import: Export

Importazione della Feature export dal codice: condivisione ed esportazione Markdown, esportazione PDF e copia Markdown di ogni nota nel vault. Fonti: lib/core/services/pdf_export_service.dart, vault_service.dart, lib/core/models/note_model.dart, lib/ui/notes_list/note_actions.dart, schermate mobile, test/vault_test.dart, test/markdown_render_test.dart.

## Doubts

- lib/core/services/pdf_export_service.dart:9 l'esportazione PDF non viene mai chiamata da nessuna parte dell'app: nessun pulsante o voce di menu la offre, quindi è codice morto (i pacchetti pdf/printing in pubspec.yaml:49-50 servono solo qui).
- lib/core/services/pdf_export_service.dart:49 il PDF usa il contenuto grezzo, non la conversione Markdown: le note a blocchi (formato dell'editor) uscirebbero come testo serializzato illeggibile e i marcatori `**`/`*` resterebbero letterali.
- lib/core/services/pdf_export_service.dart:59 il titolo viene saltato solo se una riga è identica al titolo; se il corpo lo ha come `# Titolo` il titolo compare due volte. Inoltre il PDF non chiede il PIN per le note protette, a differenza di condivisione ed esportazione.
- lib/core/state/notes_provider.dart:257,297,314,330,346,361,379,429 il percorso restituito dalla scrittura del vault (lib/core/services/vault_service.dart:161) non viene mai salvato nella nota, quindi la posizione del file resta sempre vuota nel database.
- lib/core/state/notes_provider.dart:442,455 e lib/core/services/sync_service.dart:182,314 per la conseguenza precedente i file del vault non vengono mai cancellati: né con l'eliminazione definitiva, né svuotando il cestino, né con eliminazione remota o pulizia delle note di benvenuto. CHANGELOG.md:5 cita "permanent deletions without a vault file" come caso normale.
- lib/core/services/vault_service.dart:144-156 il nome del file viene ricalcolato dal titolo a ogni salvataggio: rinominare una nota lascia il vecchio file orfano, e due note con lo stesso titolo si sovrascrivono a vicenda lo stesso file.
- lib/core/state/notes_provider.dart:346 le note nel cestino restano nel vault con `deleted: true`; la data di eliminazione non è scritta nell'intestazione (lib/core/services/vault_service.dart:120-130).
- lib/core/services/vault_service.dart:133 il corpo del file è il contenuto grezzo (per le note dell'editor il documento a blocchi serializzato), non Markdown, nonostante il vault sia descritto come Markdown; le note protette sono scritte in chiaro (nessuna cifratura in lib/).
- lib/core/services/vault_service.dart:178 `readNote` (e `parseMarkdownFile` in produzione) non è mai usato: il vault è di sola scrittura; il commento alla riga 12 "Synchronizing with disk changes" non è implementato.
- lib/main.dart:45 `init` è chiamato senza `customPath`: il percorso personalizzato del vault è usato solo nei test e il dialogo impostazioni (lib/ui/settings/supabase_settings_dialog.dart:133) lo mostra in sola lettura; il commento in lib/core/services/vault_service.dart:31 dice "OpenNotes" ma la cartella è `OpenNotes_Vault` (riga 38).
- lib/core/services/vault_service.dart:137 il parametro `folderPath` non è mai passato: nessuna struttura per cartelle, tutte le note nella radice del vault.
- lib/core/services/vault_service.dart:148 i controlli su titoli che iniziano con `{` o `_{` sono morti, perché `{` è già sostituito da `_` alla riga 145.
- lib/core/services/vault_service.dart:165 gli allegati non vengono mai cancellati, nemmeno quando l'immagine o la nota sono eliminate.
- lib/ui/notes_list/note_actions.dart:99 il testo condiviso antepone il titolo alla conversione Markdown, che per le note a blocchi inizia già con `# Titolo`: il titolo risulta duplicato.
- lib/core/models/note_model.dart:264-322 i blocchi di codice non hanno un caso proprio e sono esportati come paragrafi senza recinzione; il sottolineato viene perso; gli elenchi numerati sono sempre `1.`.
- lib/ui/notes_list/note_actions.dart:59-65 condivisione ed esportazione di una nota protetta chiedono il PIN ogni volta, anche se la nota è già sbloccata nella sessione (controllano solo che la nota sia protetta).
