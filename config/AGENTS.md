# Instructions projet

## Skills obligatoires

Avant de coder, **toujours charger les skills suivantes** avec le tool `skill` :

- **react-dsfr** : À charger systématiquement avant de créer ou modifier une interface React. Contient les bons imports, composants et patterns du Design System de l'État.
- **rgaa** : À charger pour tout travail sur l'interface. Contient les 106 critères d'accessibilité RGAA 4.1.2 à respecter.
- **securite-anssi** : À charger pour tout code backend, API, configuration serveur ou déploiement. Contient les 12 règles essentielles de sécurité de l'ANSSI.

## Conventions générales

- Toute interface utilisateur doit respecter le **DSFR** (Design System de l'État)
- Accessibilité **RGAA 4.1.2 niveau AA** obligatoire
- Pas de secrets dans le code — utiliser des variables d'environnement
- Tests unitaires pour toute nouvelle fonctionnalité
- Commits atomiques avec messages clairs en français ou anglais

## Stack technique de référence

- **Frontend** : React + `@codegouvfr/react-dsfr`
- **CSS** : classes utilitaires DSFR uniquement, pas de CSS custom sauf exception justifiée
- **Tests** : Vitest (unit) + Playwright (e2e)
- **Linter** : ESLint + Prettier
- **Backend** : au choix du projet (Python/FastAPI, Node/Express, Go)

## Sécurité

- HTTPS obligatoire en production
- Headers de sécurité : CSP, HSTS, X-Frame-Options, X-Content-Type-Options
- Dépendances à jour (`npm audit` / `pip audit` régulièrement)
- Validation de toutes les entrées utilisateur côté serveur
- Pas de données sensibles dans les logs

## Accessibilité

- Navigation clavier complète sur tous les composants interactifs
- Contraste minimum AA (4.5:1 pour le texte, 3:1 pour les grands textes)
- Attributs `alt` sur toutes les images (vide si décorative)
- Structure sémantique HTML : `<header>`, `<nav>`, `<main>`, `<footer>`
- Hiérarchie des titres h1→h6 sans saut de niveau
- Formulaires : chaque champ a un `<label>` associé, messages d'erreur explicites

## Tests

- Toute nouvelle fonctionnalité doit être accompagnée de tests
- Avant de considérer une tâche terminée, lance les tests et vérifie qu'ils passent
- Si tu modifies du code existant, ajoute des tests s'il n'y en a pas déjà

## Déploiement

- Images Docker multi-stage (build + runtime séparés)
- Health checks obligatoires (`/health` ou `/api/health`)
- Variables d'environnement pour toute configuration
- Cible : infrastructure cloud souveraine (SecNumCloud si disponible)

## Conventions Git

- Branches : `feature/xxx`, `fix/xxx`, `refactor/xxx`
- PR obligatoire pour toute modification sur `main`
- Review par au moins 1 pair avant merge
