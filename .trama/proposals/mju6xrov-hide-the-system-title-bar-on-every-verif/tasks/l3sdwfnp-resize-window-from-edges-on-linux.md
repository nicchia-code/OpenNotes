---
technical: false
refs:
  - navigation
  - user.RESIZE_WINDOW
  - app-window/Open/user.RESIZE_WINDOW
  - requirements/rules#app-window
---
# Resize the window from its edges on Linux

Senza la cornice di sistema, sui desktop Linux flottanti (COSMIC, GNOME, KDE) non resta nessun bordo da trascinare per ridimensionare la finestra. Su Linux l'app aggiunge una fascia invisibile di 6 px lungo i quattro bordi e zone di 12 × 12 px nei quattro angoli: al passaggio mostrano il cursore di ridimensionamento corrispondente e, trascinate, ridimensionano la finestra (in diagonale dagli angoli), senza scendere sotto la dimensione minima.

La fascia sta sopra il contenuto e non è attiva quando la finestra è ingrandita, a schermo intero o affiancata a tassello secondo quanto segnala il sistema. Su macOS, Windows, web, Android e iOS non c'è.

Verifica: su COSMIC in modalità flottante ridimensionare da ogni bordo e angolo; con la finestra ingrandita il cursore di ridimensionamento non compare.
