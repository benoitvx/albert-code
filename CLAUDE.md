# CLAUDE.md — Albert Code

## Projet

**Albert Code** est un bundle d'installation pour coder avec l'IA en local sur un Mac d'agent public. Il installe et configure automatiquement un assistant IA de coding (OpenCode) alimenté par un modèle open-source (Qwen 3.5) qui tourne localement via Ollama. Les données ne quittent jamais la machine.

**Repo** : github.com/benoitvx/albert-code
**Licence** : MIT

## Stack

| Composant | Outil | Rôle |
|-----------|-------|------|
| CLI IA | OpenCode | Interface terminal pour coder avec l'IA |
| Runtime modèle | Ollama | Serveur d'inférence local |
| Modèle principal | Qwen 3.5 27B (Q4) | Dense, 72.4% SWE-bench, ~16 Go RAM |
| Modèle léger | Qwen 3.5 35B-A3B (Q4) | MoE 3B actifs, 69.2% SWE-bench, ~10 Go RAM |
| Skills | react-dsfr, rgaa, securite-anssi | Connaissances métier État |
| MCP (optionnel) | Chrome DevTools MCP | L'IA voit le navigateur (DOM, console) |

## ASCII Art

L'installeur et l'alias `albert-code` affichent ce banner au lancement :

```
    _    _ _               _      ____          _
   / \  | | |__   ___ _ __| |_   / ___|___   __| | ___
  / _ \ | | '_ \ / _ \ '__| __| | |   / _ \ / _` |/ _ \
 / ___ \| | |_) |  __/ |  | |_  | |__| (_) | (_| |  __/
/_/   \_\_|_.__/ \___|_|   \__|  \____\___/ \__,_|\___|
```

Le banner est défini une seule fois dans une fonction `print_banner()` réutilisée par `install.sh` et l'alias.

## Architecture du repo

```
albert-code/
├── install.sh                  # Script principal (point d'entrée unique)
├── uninstall.sh                # Désinstallation propre
├── CLAUDE.md                   # Ce fichier
├── README.md                   # Guide utilisateur (le livrable principal)
├── LICENSE                     # MIT
├── config/
│   ├── opencode.template.jsonc # Config OpenCode (provider Ollama local)
│   └── AGENTS.md               # Instructions génériques pour l'IA
├── skills/
│   ├── skills-etat/            # Submodule git
│   │   ├── react-dsfr/         # Skill composants DSFR
│   │   └── rgaa/               # Skill accessibilité (106 critères)
│   └── securite-anssi/
│       └── SKILL.md            # Skill sécurité ANSSI (12 règles)
└── templates/
    └── pull_request_template.md
```

## Conventions de développement

### Shell scripting (install.sh)

- **Bash 3.2** minimum (version livrée avec macOS)
- Toujours tester `$?` ou utiliser `set -e` pour échouer proprement
- Chaque étape affiche un message clair en français (pas de jargon)
- Utiliser des fonctions nommées : `install_ollama()`, `install_opencode()`, etc.
- Pas de dépendance à Homebrew — utiliser les installeurs standalone (curl)
- Couleurs : vert (succès), jaune (avertissement), rouge (erreur), bleu (info)
- Chaque étape potentiellement longue affiche un spinner ou une barre de progression
- Jamais de `sudo` sans explication à l'utilisateur
- Idempotent : relancer le script ne casse rien (vérifier avant d'installer)

### Messages utilisateur

- Français, tutoiement
- Phrases courtes, verbes d'action
- Pas de jargon technique sans explication
- Toujours dire ce qui se passe ET ce qui va se passer après
- En cas d'erreur : dire quoi faire, pas juste afficher l'erreur

Exemple :
```
✅ Ollama installé avec succès.
⏳ Téléchargement du modèle Qwen 3.5 (environ 16 Go, ça peut prendre quelques minutes)...
```

### Git

- Commits atomiques, en anglais
- Format : `type: description` (feat, fix, docs, refactor, test, chore)
- Pas de commits vides ou de WIP sur main

### Tests

- Tester le script sur un Mac vierge (ou quasi-vierge) avant de publier
- Documenter les prérequis réellement nécessaires
- Chaque commande du README doit être testée en copier-coller

## Modèles

### Sélection automatique

Le script détecte la RAM disponible et propose le bon modèle :

| RAM disponible | Modèle proposé | Justification |
|----------------|----------------|---------------|
| >= 32 Go | Qwen 3.5 27B (Q4_K_M) | Meilleur score, dense |
| 16-31 Go | Qwen 3.5 35B-A3B (Q4_K_M) | MoE léger, 3B actifs |
| < 16 Go | Avertissement + proposition 35B-A3B Q3 | Dégradé mais fonctionnel |

### Config OpenCode

OpenCode se connecte à Ollama via l'API OpenAI-compatible locale :
- Base URL : `http://localhost:11434/v1`
- Pas de clé API nécessaire
- Le modèle est référencé par son nom Ollama (ex: `qwen3.5:27b`)

## Skills

Les skills sont des fichiers Markdown chargés automatiquement par OpenCode. Elles donnent à l'IA la connaissance des conventions de l'État :

- **react-dsfr** : Composants du Design System de l'État, patterns d'import, layout
- **rgaa** : 106 critères d'accessibilité numérique (RGAA 4.1.2)
- **securite-anssi** : 12 règles essentielles de sécurité (TLS, secrets, headers, etc.)

Ne pas modifier les skills directement — elles sont en submodule git. Pour les mettre à jour : `git submodule update --remote`.

## Ce qu'il ne faut PAS faire

- Ne pas ajouter de dépendance à Albert API (le MVP est 100% local)
- Ne pas ajouter de VM ou de conteneur (approche simple d'abord)
- Ne pas supporter Windows ou Linux pour l'instant
- Ne pas ajouter de templates de projet (le modèle doit être assez bon pour créer from scratch avec les skills)
- Ne pas hardcoder des chemins absolus dans le script
- Ne pas utiliser de syntaxe bash > 3.2 (pas de `declare -A`, pas de `|&`, etc.)
- Ne pas dépendre de Homebrew (installeurs standalone uniquement)
