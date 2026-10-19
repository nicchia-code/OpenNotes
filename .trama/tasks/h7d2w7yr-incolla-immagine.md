---
column: done
technical: false
refs:
  - note-editor
  - user.PASTE_IMAGE
  - requirements/rules#note-editor
  - requirements/data#note-editor
  - requirements/ui#note-editor
drift: null
proposal: sdhwy7m7
agent: false
created: 2026-10-19T15:28:11.378Z
finished: 2026-10-19T16:38:53.966Z
---
# Incolla immagine nell'editor

Quando il lavoro è finito, nell'editor della nota aperta (`note-editor/Open`):

- Ctrl/Cmd+V e la voce «Incolla» del menu contestuale (tasto destro su desktop, pressione prolungata su mobile) in una sezione di testo incollano il testo semplice degli appunti, se c'è, anche quando c'è anche un'immagine; altrimenti, se gli appunti contengono un'immagine, emettono `user.PASTE_IMAGE`. La voce «Incolla» compare anche quando gli appunti contengono solo un'immagine.
- In una cella di tabella si incolla solo testo e un'immagine negli appunti viene ignorata. I file copiati nel Finder o in Esplora risorse non si incollano come immagini; le immagini inserite dalla tastiera di Android non sono gestite.
- `note-editor/Open/user.PASTE_IMAGE` → Idle: se l'immagine degli appunti viene salvata tra gli allegati del vault, rimpicciolita se troppo grande, la inserisce dopo la parte attiva, come per una foto: subito dopo aggiunge una nuova sezione di testo vuota, che riceve il focus. Salva subito, anche se c'erano modifiche di testo in attesa.
- `note-editor/Open/Idle/user.PASTE_IMAGE` → Idle e `note-editor/Open/Save pending/user.PASTE_IMAGE` → Save pending: se l'immagine non si può salvare, compare in basso la SnackBar «Immagine non incollata»; il documento non cambia e, in Save pending, l'attesa continua.
- Immagine salvata: PNG, JPEG, GIF e WebP restano nel loro formato, ogni altro formato (TIFF, BMP…) diventa PNG. Se il lato più lungo supera 2048 px viene rimpicciolita mantenendo le proporzioni fino a 2048 px, nello stesso formato (JPEG riscritto con qualità 85); una WebP rimpicciolita diventa PNG; le GIF non vengono mai rimpicciolite.
- L'allegato è `attachments/att_<millisecondi>.<estensione>` con estensione `png`, `jpg`, `gif` o `webp` secondo il formato salvato, e passa per lo stesso salvataggio degli allegati delle foto.
