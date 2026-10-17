---
status: approved
base:
  actors/user.md: 768b357e83fbe9d6468fa0f05b675568e7ff8cd36743fb838c596462c641b2bb
  navigation/app-window.md: 93dcade486759b9ca3314885bf6ba502fad809304593997ecee9eb96b1ddff54
  navigation/feature.md: c95a535f2d48a0ffb099c845b44ec4516f684b4be30e23850dcaff83d1bea597
  requirements/rules/navigation.md: ad8651230d7e0a94abb1a6ed67271f9e52ddc7c3ffd408fe084f3f198c0dea6a
  requirements/tech/general.md: a58194a1c0b0924cd75988c4f80c83f7d0fea342dfc6e9bb0193d9c5226bd7cd
delete: []
created: 2026-10-17T07:23:02.764Z
---
# Hide the system title bar on every verified Linux desktop

Su COSMIC compare la barra del titolo disegnata dal compositore, mentre il Model prevede che sui sistemi desktop la finestra non abbia la barra del titolo di sistema (su Hyprland non si vede perché il compositore non disegna barre). La Proposal rende il requisito esplicito per gli ambienti Linux verificati e aggiunge il ridimensionamento dai bordi, che senza cornice di sistema altrimenti manca sui desktop flottanti.

Decisioni prese:
- Ambienti garantiti: COSMIC, Hyprland, GNOME e KDE su Wayland; la barra del titolo di sistema non deve mai comparire. Altri ambienti senza garanzia.
- Ridimensionamento su Linux: fascia invisibile dell'app lungo i bordi (6 px) e negli angoli (12 px), con cursore di ridimensionamento.
- La fascia è disattivata quando la finestra è ingrandita, a schermo intero o a tassello secondo il sistema.
- Aspetto dei bordi: l'app non disegna angoli arrotondati, bordo o ombra; restano solo quelli aggiunti dal compositore.
- Se un sistema disegna comunque la propria barra del titolo, l'app non fa nulla: la sua barra superiore resta invariata.
