---
status: rejected
base:
  requirements/tech/general.md: 7c6879eff992aee0270d7ca31275691b3e6ac75498147a4e832fbdce96976898
delete: []
created: 2026-10-17T17:10:58.331Z
---
# Full-bleed icon size fits the source

Il requisito tech#General chiede OpenNotes-full-bleed.png come quadrato 1024×1024 ritagliato dall'interno del riquadro. Il riquadro di OpenNotes.png è alto circa 995 px, quindi nessun quadrato di 1024 px ci sta. Decisioni:
- Il file full-bleed diventa il quadrato pieno più grande che sta dentro il riquadro, centrato, circa 876×876 px, senza angoli, bordo, ombra né trasparenza.
- Le icone che richiedono 1024 px (iOS, Android) si generano da questo ritaglio, ingrandito dal generatore.
Assunzioni da verificare:
- La dimensione esatta del ritaglio è quella del quadrato pieno più grande; il developer può preferire un altro compromesso.

## Feedback

Drift 84ymfebe resolved by Proposal tqf85in9
