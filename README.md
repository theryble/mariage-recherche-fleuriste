# Recherche fleuriste & décoratrice — JMPP

Fiche de présentation envoyée aux fleuristes et décoratrices pour le mariage du 22 août 2027 au Manoir des Lys.

Publiée sur GitHub Pages : https://theryble.github.io/mariage-recherche-fleuriste/

## Journal des visites

Chaque passage sur la fiche (date, adresse IP, navigateur, page d'origine) est enregistré dans la table `fiche_visites` du projet Supabase dédié à la fiche (le même que pour les cercles de présence).

Mise en place, une seule fois : Supabase → **SQL Editor** → **New query** → coller le contenu de `supabase/visites.sql` → **Run**.

Consultation : **Table Editor** → `fiche_visites_paris` (heure de Paris ; `fiche_visites` est en heure UTC), ou les requêtes en fin de `supabase/visites.sql`.
