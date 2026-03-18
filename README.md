# Albert Code

```
    _    _ _               _      ____          _
   / \  | | |__   ___ _ __| |_   / ___|___   __| | ___
  / _ \ | | '_ \ / _ \ '__| __| | |   / _ \ / _` |/ _ \
 / ___ \| | |_) |  __/ |  | |_  | |__| (_) | (_| |  __/
/_/   \_\_|_.__/ \___|_|   \__|  \____\___/ \__,_|\___|
```

**Code avec l'IA, 100% en local sur ton Mac.** Aucune donnée ne quitte ta machine.

Albert Code installe et configure automatiquement un assistant de code IA dans le terminal, alimenté par un modèle open-source (Qwen 3.5) qui tourne localement via Ollama.

---

## Prérequis

| | Minimum | Recommandé |
|---|---|---|
| **Mac** | macOS 12+ | macOS 14+ |
| **RAM** | 16 Go | 32 Go |
| **Disque libre** | 20 Go | 30 Go |
| **Processeur** | Intel ou Apple Silicon | Apple Silicon (M1+) |

> Pas besoin de compte, pas besoin de clé API, pas besoin d'internet après l'installation.

---

## Installation

### 1. Ouvrir le Terminal

Appuie sur **Cmd + Espace**, tape **Terminal**, puis Entrée.

### 2. Télécharger Albert Code

```bash
git clone https://github.com/benoitvx/albert-code.git ~/Desktop/albert-code
cd ~/Desktop/albert-code
```

> **Premier `git clone` sur un Mac neuf ?** Une popup Apple va te proposer d'installer les "Command Line Tools". Clique **Installer**, attends la fin, puis relance la commande.

### 3. Lancer l'installation

```bash
./install.sh
```

Le script va :
1. Vérifier ta machine (RAM, disque, processeur)
2. Proposer le bon modèle IA selon ta config
3. Installer **Ollama** (moteur d'inférence local)
4. Télécharger le **modèle Qwen 3.5** (~10-16 Go selon le modèle)
5. Installer **OpenCode** (assistant IA terminal)
6. Configurer le tout
7. Installer les **skills** métier (DSFR, accessibilité, sécurité)

> Le téléchargement du modèle est l'étape la plus longue. Compte environ 5-15 minutes selon ta connexion.

---

## Premier lancement

Ouvre un **nouveau terminal** (important pour charger la commande), puis :

```bash
cd ton-projet
albert-code
```

La commande `albert-code` :
- Démarre Ollama automatiquement s'il ne tourne pas
- Lance OpenCode connecté au modèle local

### Scénario 1 — Hello World HTML

```
> Crée une page HTML simple avec un titre "Bonjour" et un paragraphe de bienvenue
```

### Scénario 2 — Page DSFR

```
> Crée une page React avec le header DSFR, un titre h1, et un bouton principal
```

L'IA connaît le Design System de l'État grâce à la skill `react-dsfr`.

### Scénario 3 — Audit accessibilité

```
> Vérifie l'accessibilité RGAA de ce composant et corrige les problèmes
```

L'IA connaît les 106 critères du RGAA 4.1.2 grâce à la skill `rgaa`.

---

## Skills intégrées

Albert Code embarque des connaissances métier de l'État :

| Skill | Contenu |
|-------|---------|
| **react-dsfr** | Composants DSFR, patterns d'import, layout |
| **rgaa** | 106 critères d'accessibilité RGAA 4.1.2 |
| **securite-anssi** | 12 règles de sécurité essentielles ANSSI |

Les skills sont chargées automatiquement. L'IA les utilise quand c'est pertinent.

---

## Modèles disponibles

| Modèle | RAM nécessaire | Taille | Score SWE-bench |
|--------|---------------|--------|-----------------|
| Qwen 3.5 27B (Q4) | 32+ Go | ~16 Go | 72.4% |
| Qwen 3.5 35B-A3B (Q4, MoE) | 16+ Go | ~10 Go | 69.2% |

Le script choisit automatiquement le meilleur modèle pour ta machine.

---

## Dépannage

### Ollama ne démarre pas

```bash
# Vérifier si Ollama tourne
curl http://localhost:11434/api/tags

# Le démarrer manuellement
ollama serve
```

### Le modèle est lent

- Ferme les applications gourmandes (navigateur avec beaucoup d'onglets, Docker, etc.)
- Sur Mac Intel, c'est normal que ce soit plus lent qu'Apple Silicon
- Si tu as 16 Go de RAM, le modèle 35B-A3B (MoE) sera plus fluide que le 27B

### Pas assez de RAM

Si le modèle plante ou freeze :
```bash
# Passer au modèle plus léger
ollama pull qwen3.5:35b-a3b
```
Puis modifie `~/.config/opencode/opencode.jsonc` pour changer le modèle.

### OpenCode ne se connecte pas à Ollama

```bash
# Vérifier la config
cat ~/.config/opencode/opencode.jsonc

# La baseURL doit être : http://localhost:11434/v1
# Le modèle doit correspondre à un modèle installé dans Ollama
ollama list
```

### « command not found: albert-code »

Ouvre un **nouveau terminal** pour charger la fonction, ou :
```bash
source ~/.zshrc   # ou ~/.bashrc
```

---

## Désinstallation

```bash
cd ~/Desktop/albert-code
./uninstall.sh
```

Le script supprime la config, les skills et la commande `albert-code`. Il ne désinstalle pas Ollama ni OpenCode (tu pourrais en avoir besoin pour autre chose).

---

## Comment ça marche

```
┌──────────────────────────────────────────────┐
│  Terminal                                    │
│  ┌────────────────────────────────────────┐  │
│  │  albert-code (alias)                   │  │
│  │  └─→ OpenCode (assistant IA terminal)  │  │
│  │       └─→ Ollama (localhost:11434)     │  │
│  │            └─→ Qwen 3.5 (local)       │  │
│  └────────────────────────────────────────┘  │
│  Tout tourne sur ta machine.                 │
│  Rien ne sort sur internet.                  │
└──────────────────────────────────────────────┘
```

---

## Licence

MIT — Benoit Vinceneux
