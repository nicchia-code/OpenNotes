---
column: done
technical: false
refs:
  - drawing-canvas/Drawing/user.SAVE_DRAWING
drift: null
proposal: null
agent: false
created: 2026-10-12T11:19:38.162Z
finished: 2026-10-12T13:55:43.959Z
---
# Fix code to match the Model: Tapping Fine twice saves the drawing twice

Il comando «Fine» deve salvare il disegno una sola volta: il passaggio SAVE_DRAWING porta a Closed. Oggi, se l'utente tocca «Fine» due volte prima che la tela si chiuda, l'immagine viene esportata e salvata due volte tra gli allegati e inserita due volte nella nota. Serve una protezione perché un secondo tocco durante il salvataggio non ripeta l'esportazione né l'inserimento.

# Acceptance
- Toccare «Fine» più volte durante lo stesso salvataggio produce un solo allegato e una sola immagine inserita nella nota.
