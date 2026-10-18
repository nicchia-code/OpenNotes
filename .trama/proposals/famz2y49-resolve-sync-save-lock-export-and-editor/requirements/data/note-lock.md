---
description: Use when storing or reading the master PIN or the lock flag and session unlocks of notes.
---
# Note lock data

## master-pin
- Unico dato persistito: l'impronta del PIN principale, stringa esadecimale di 64 caratteri (SHA-256), salvata nelle preferenze locali del dispositivo sotto un'unica chiave (`user_master_pin_hash`).
- La presenza della chiave equivale a "PIN impostato"; non esiste un'entità PIN nel database locale, nel vault o su Supabase.

## note-access
- Il lucchetto è un attributo booleano della nota (predefinito: falso): intero 0/1 `is_locked` nel database locale, `locked` nel front matter del file Markdown del vault (solo scritto: l'app non rilegge il vault), booleano `is_locked` nella tabella delle note su Supabase.
- Gli sblocchi di sessione sono solo un insieme in memoria di identificativi di note, mai salvato.
- L'anteprima memorizzata di una nota protetta è il testo fisso "Questa nota è protetta"; il contenuto della nota protetta resta salvato per intero, non cifrato.
