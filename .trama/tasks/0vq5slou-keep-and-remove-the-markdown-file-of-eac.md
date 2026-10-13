---
column: done
technical: false
refs:
  - note/In trash/user.DELETE_NOTE_PERMANENTLY
  - note/In trash/user.EMPTY_TRASH
  - note/Active/realtime-channel.CLOUD_NOTE_REMOVED
  - note/Active/sync-run.SAMPLE_NOTE_DISCARDED
  - requirements/data#note
drift: null
proposal: null
agent: false
created: 2026-10-12T07:28:57.644Z
finished: 2026-10-12T10:24:55.402Z
---
# Keep and remove the Markdown file of each note

Ogni nota deve avere un solo file nell'archivio Markdown: ogni salvataggio riscrive quello stesso file anche se il titolo cambia, e il percorso del file viene ricordato insieme alla nota. Quando la nota viene eliminata definitivamente, quando il cestino viene svuotato, quando viene eliminata nel cloud o quando si scarta la nota di benvenuto mai sincronizzata, il suo file va rimosso. Oggi il percorso non viene mai salvato: il file resta nell'archivio e ogni cambio di titolo ne crea uno nuovo.
