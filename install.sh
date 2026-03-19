#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# Albert Code — Script d'installation
# Installe Ollama + Qwen 3.5 + OpenCode
# 100% local, aucune donnée ne quitte la machine
# ─────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}▸${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }
error()   { echo -e "${RED}✗${NC} $1"; exit 1; }

# ─────────────────────────────────────────────
# Banner ASCII
# ─────────────────────────────────────────────

print_banner() {
  echo -e "${BOLD}"
  cat << 'BANNER'
    _    _ _               _      ____          _
   / \  | | |__   ___ _ __| |_   / ___|___   __| | ___
  / _ \ | | '_ \ / _ \ '__| __| | |   / _ \ / _` |/ _ \
 / ___ \| | |_) |  __/ |  | |_  | |__| (_) | (_| |  __/
/_/   \_\_|_.__/ \___|_|   \__|  \____\___/ \__,_|\___|
BANNER
  echo -e "${NC}"
  echo -e "  ${BLUE}100% local — Ollama + Qwen 3.5 + OpenCode${NC}"
  echo ""
}

# ─────────────────────────────────────────────
# Étape 1 : Vérifier macOS
# ─────────────────────────────────────────────

check_macos() {
  local os
  os="$(uname -s)"
  if [[ "$os" != "Darwin" ]]; then
    error "Albert Code ne fonctionne que sur macOS. Système détecté : $os"
  fi
  success "macOS détecté"
}

# ─────────────────────────────────────────────
# Étape 2 : Détecter la machine
# ─────────────────────────────────────────────

detect_machine() {
  # Architecture
  ARCH="$(uname -m)"
  if [[ "$ARCH" == "arm64" ]]; then
    ARCH_NAME="Apple Silicon"
  else
    ARCH_NAME="Intel"
  fi

  # RAM en Go
  local mem_bytes
  mem_bytes="$(sysctl -n hw.memsize)"
  RAM_GB=$((mem_bytes / 1073741824))

  # Espace disque disponible en Go
  DISK_FREE_GB="$(df -g / | awk 'NR==2 {print $4}')"

  info "Machine : $ARCH_NAME ($ARCH) — ${RAM_GB} Go RAM — ${DISK_FREE_GB} Go disque libre"

  # Avertissements
  if [[ "$RAM_GB" -lt 16 ]]; then
    warn "Moins de 16 Go de RAM détectés. L'expérience sera dégradée."
    warn "Albert Code fonctionne mieux avec 16 Go de RAM ou plus."
  fi

  if [[ "$DISK_FREE_GB" -lt 20 ]]; then
    warn "Moins de 20 Go d'espace disque disponible."
    warn "Le modèle Qwen 3.5 nécessite environ 16 Go d'espace."
    read -rp "  Continuer quand même ? [o/N] : " CONTINUE
    if [[ "$CONTINUE" != "o" && "$CONTINUE" != "O" ]]; then
      echo "Installation annulée."
      exit 0
    fi
  fi
}

# ─────────────────────────────────────────────
# Étape 3 : Sélectionner le modèle
# ─────────────────────────────────────────────

select_model() {
  if [[ "$RAM_GB" -ge 32 ]]; then
    MODEL_ID="qwen3.5:27b"
    MODEL_NAME="Qwen 3.5 27B (Q4)"
    MODEL_SIZE="~16 Go"
    info "32+ Go de RAM → modèle recommandé : ${BOLD}$MODEL_NAME${NC}"
  elif [[ "$RAM_GB" -ge 16 ]]; then
    MODEL_ID="qwen3.5:35b-a3b"
    MODEL_NAME="Qwen 3.5 35B-A3B (MoE léger)"
    MODEL_SIZE="~10 Go"
    info "16-31 Go de RAM → modèle léger : ${BOLD}$MODEL_NAME${NC}"
  else
    MODEL_ID="qwen3.5:35b-a3b"
    MODEL_NAME="Qwen 3.5 35B-A3B (MoE léger)"
    MODEL_SIZE="~10 Go"
    warn "Moins de 16 Go de RAM — le modèle sera lent."
    info "Modèle proposé : ${BOLD}$MODEL_NAME${NC}"
  fi

  echo ""
  info "Modèle sélectionné : ${BOLD}$MODEL_NAME${NC} ($MODEL_SIZE)"
  read -rp "  Confirmer ce choix ? [O/n] : " CONFIRM
  if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
    echo ""
    echo "  Modèles disponibles :"
    echo "    1) qwen3.5:27b      — Qwen 3.5 27B (~16 Go, meilleur score)"
    echo "    2) qwen3.5:35b-a3b  — Qwen 3.5 35B-A3B (~10 Go, léger MoE)"
    echo ""
    read -rp "  Ton choix [1/2] : " MODEL_CHOICE
    case "$MODEL_CHOICE" in
      1)
        MODEL_ID="qwen3.5:27b"
        MODEL_NAME="Qwen 3.5 27B (Q4)"
        MODEL_SIZE="~16 Go"
        ;;
      2)
        MODEL_ID="qwen3.5:35b-a3b"
        MODEL_NAME="Qwen 3.5 35B-A3B (MoE léger)"
        MODEL_SIZE="~10 Go"
        ;;
      *)
        error "Choix invalide"
        ;;
    esac
  fi

  success "Modèle : $MODEL_NAME"
}

# ─────────────────────────────────────────────
# Étape 4 : Installer Ollama
# ─────────────────────────────────────────────

install_ollama() {
  if command -v ollama &>/dev/null; then
    local version
    version="$(ollama --version 2>/dev/null || echo 'inconnue')"
    success "Ollama déjà installé ($version)"
    return
  fi

  info "Installation d'Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh

  if ! command -v ollama &>/dev/null; then
    error "Échec de l'installation d'Ollama. Essaie manuellement : https://ollama.com/download"
  fi

  # L'installeur lance automatiquement l'app GUI — on la ferme
  # pour piloter le serveur nous-mêmes (headless, sans icône menubar)
  if pgrep -x "Ollama" >/dev/null 2>&1; then
    osascript -e 'quit app "Ollama"' 2>/dev/null || true
    sleep 2
  fi

  success "Ollama installé"
}

# ─────────────────────────────────────────────
# Étape 5 : Démarrer Ollama
# ─────────────────────────────────────────────

start_ollama() {
  # Vérifier si Ollama est déjà en cours d'exécution
  if curl -sf http://localhost:11434/api/tags >/dev/null 2>&1; then
    success "Ollama est déjà en cours d'exécution"
    return
  fi

  info "Démarrage d'Ollama..."
  ollama serve &>/dev/null &

  # Attendre qu'Ollama soit prêt (max 30 secondes)
  local tries=0
  while ! curl -sf http://localhost:11434/api/tags >/dev/null 2>&1; do
    tries=$((tries + 1))
    if [[ "$tries" -ge 30 ]]; then
      error "Ollama ne démarre pas. Essaie de le lancer manuellement : ollama serve"
    fi
    sleep 1
  done

  success "Ollama démarré"
}

# ─────────────────────────────────────────────
# Étape 6 : Télécharger le modèle
# ─────────────────────────────────────────────

pull_model() {
  # Vérifier si le modèle est déjà téléchargé
  if ollama list 2>/dev/null | grep -q "$MODEL_ID"; then
    success "Modèle $MODEL_NAME déjà téléchargé"
    return
  fi

  # Attendre que la clé d'identité Ollama soit générée (premier lancement)
  local tries=0
  while [ ! -f "$HOME/.ollama/id_ed25519" ]; do
    tries=$((tries + 1))
    if [ "$tries" -ge 15 ]; then
      error "La clé Ollama n'a pas été générée. Relance le script."
    fi
    sleep 1
  done

  echo ""
  info "Téléchargement du modèle $MODEL_NAME ($MODEL_SIZE)..."
  info "C'est le plus long — ça peut prendre quelques minutes selon ta connexion."
  echo ""

  ollama pull "$MODEL_ID"

  if ollama list 2>/dev/null | grep -q "$MODEL_ID"; then
    success "Modèle $MODEL_NAME téléchargé"
  else
    error "Échec du téléchargement du modèle. Essaie manuellement : ollama pull $MODEL_ID"
  fi
}

# ─────────────────────────────────────────────
# Étape 7 : Installer OpenCode
# ─────────────────────────────────────────────

install_opencode() {
  if command -v opencode &>/dev/null; then
    success "OpenCode déjà installé ($(opencode --version 2>/dev/null || echo 'version inconnue'))"
    return
  fi

  info "Installation d'OpenCode..."
  curl -fsSL https://raw.githubusercontent.com/opencode-ai/opencode/refs/heads/main/install | bash

  if command -v opencode &>/dev/null; then
    success "OpenCode installé"
  else
    error "Échec de l'installation d'OpenCode"
  fi
}

# ─────────────────────────────────────────────
# Étape 8 : Configurer OpenCode pour Ollama
# ─────────────────────────────────────────────

configure_opencode() {
  local config_dir="$HOME/.config/opencode"
  local config_file="$config_dir/opencode.jsonc"

  mkdir -p "$config_dir"

  if [[ -f "$config_file" ]]; then
    if grep -q "ollama" "$config_file" 2>/dev/null; then
      success "Configuration OpenCode déjà en place (Ollama)"
      return
    else
      warn "Configuration OpenCode existante détectée"
      read -rp "  Écraser avec la config Ollama locale ? [o/N] : " OVERWRITE
      if [[ "$OVERWRITE" != "o" && "$OVERWRITE" != "O" ]]; then
        info "Configuration conservée"
        return
      fi
    fi
  fi

  # Copier le template et remplacer les placeholders
  sed -e "s/__MODEL_ID__/$MODEL_ID/g" -e "s/__MODEL_NAME__/$MODEL_NAME/g" \
    "$SCRIPT_DIR/config/opencode.template.jsonc" > "$config_file"

  success "Configuration créée : $config_file"
  info "  Provider : Ollama (localhost:11434)"
  info "  Modèle : $MODEL_NAME"

  # Copier AGENTS.md (instructions projet) dans la config globale
  if [[ -f "$SCRIPT_DIR/config/AGENTS.md" ]]; then
    cp "$SCRIPT_DIR/config/AGENTS.md" "$config_dir/AGENTS.md"
  fi
}

# ─────────────────────────────────────────────
# Étape 9 : Vérifier Node.js (requis pour MCP)
# ─────────────────────────────────────────────

check_nodejs() {
  if command -v node &>/dev/null; then
    local node_version
    node_version="$(node --version 2>/dev/null)"
    success "Node.js détecté ($node_version)"
    HAS_NODE=true
  else
    warn "Node.js non trouvé — le MCP Chrome DevTools ne sera pas disponible"
    info "Pour l'installer plus tard : https://nodejs.org/"
    HAS_NODE=false
  fi
}

# ─────────────────────────────────────────────
# Étape 10 : Installer les skills
# ─────────────────────────────────────────────

INSTALLED_SKILLS=""

install_skills() {
  local skills_dir="$HOME/.config/opencode/skills"
  mkdir -p "$skills_dir"

  # Initialiser les submodules si nécessaire (skills-etat)
  if [[ -f "$SCRIPT_DIR/.gitmodules" ]]; then
    if [[ ! -f "$SCRIPT_DIR/skills/skills-etat/react-dsfr/skill.md" ]]; then
      info "Récupération des skills (submodules git)..."
      git -C "$SCRIPT_DIR" submodule update --init --recursive 2>/dev/null || \
        warn "Impossible de récupérer les submodules git"
    fi
  fi

  info "Installation des skills..."

  for skill in react-dsfr rgaa securite-anssi; do
    local skill_src="$SCRIPT_DIR/skills/$skill"
    local skill_dst="$skills_dir/$skill"

    # Chercher aussi dans le sous-dossier skills-etat
    if [[ ! -d "$skill_src" ]] && [[ -d "$SCRIPT_DIR/skills/skills-etat/$skill" ]]; then
      skill_src="$SCRIPT_DIR/skills/skills-etat/$skill"
    fi

    if [[ ! -d "$skill_src" ]]; then
      warn "Skill '$skill' non trouvée dans le repo — ignorée"
      continue
    fi

    if [[ -d "$skill_dst" ]]; then
      warn "Skill '$skill' déjà installée — ignorée"
    else
      cp -r "$skill_src" "$skill_dst"
      rm -rf "$skill_dst/.git"
      success "Skill '$skill' installée"
    fi
    INSTALLED_SKILLS="${INSTALLED_SKILLS:+$INSTALLED_SKILLS, }$skill"
  done
}

# ─────────────────────────────────────────────
# Étape 10 : Créer l'alias/fonction albert-code
# ─────────────────────────────────────────────

create_alias() {
  local shell_name
  shell_name="$(basename "$SHELL")"
  local shell_rc
  case "$shell_name" in
    zsh)  shell_rc="$HOME/.zshrc" ;;
    bash) shell_rc="$HOME/.bashrc" ;;
    *)    shell_rc="$HOME/.profile" ;;
  esac

  # Nettoyer l'ancien alias simple s'il existe
  if grep -q "alias albert-code=" "$shell_rc" 2>/dev/null; then
    # On va le remplacer par la fonction
    sed -i.bak '/# Albert Code — alias/d' "$shell_rc"
    sed -i.bak '/alias albert-code=/d' "$shell_rc"
    rm -f "${shell_rc}.bak"
  fi

  # Supprimer l'ancienne fonction si elle existe (pour la mettre à jour)
  if grep -q "albert-code()" "$shell_rc" 2>/dev/null; then
    # Supprimer du commentaire jusqu'à la fermeture de la fonction
    sed -i.bak '/# Albert Code — fonction/,/^}/d' "$shell_rc"
    rm -f "${shell_rc}.bak"
  fi

  cat >> "$shell_rc" << 'FUNC'

# Albert Code — fonction ajoutée par l'installer
albert-code() {
  printf '\033[1m'
  cat << 'BANNER'
    _    _ _               _      ____          _
   / \  | | |__   ___ _ __| |_   / ___|___   __| | ___
  / _ \ | | '_ \ / _ \ '__| __| | |   / _ \ / _` |/ _ \
 / ___ \| | |_) |  __/ |  | |_  | |__| (_) | (_| |  __/
/_/   \_\_|_.__/ \___|_|   \__|  \____\___/ \__,_|\___|
BANNER
  printf '\033[0m\n'
  # Auto-start Ollama si nécessaire
  if ! curl -sf http://localhost:11434/api/tags >/dev/null 2>&1; then
    echo -e "\033[0;34m▸\033[0m Démarrage d'Ollama..."
    ollama serve &>/dev/null &
    local tries=0
    while ! curl -sf http://localhost:11434/api/tags >/dev/null 2>&1; do
      tries=$((tries + 1))
      if [ "$tries" -ge 15 ]; then
        echo -e "\033[0;31m✗\033[0m Ollama ne répond pas. Lance-le manuellement : ollama serve"
        return 1
      fi
      sleep 1
    done
    echo -e "\033[0;32m✓\033[0m Ollama prêt"
  fi
  # Vérifier les mises à jour OpenCode (non bloquant)
  if command -v npm >/dev/null 2>&1; then
    local latest
    latest="$(npm view opencode-ai version 2>/dev/null)"
    if [ -n "$latest" ]; then
      local current
      current="$(opencode --version 2>/dev/null)"
      if [ -n "$current" ] && [ "$current" != "$latest" ]; then
        echo -e "\033[1;33m⚠\033[0m OpenCode $current installé — version $latest disponible"
        echo -e "  Mise à jour : \033[0;34mopencode upgrade\033[0m"
      fi
    fi
  fi
  # Copier AGENTS.md dans le projet s'il n'existe pas
  if [ ! -f "AGENTS.md" ] && [ -f "$HOME/.config/opencode/AGENTS.md" ]; then
    cp "$HOME/.config/opencode/AGENTS.md" AGENTS.md
    echo -e "\033[0;32m✓\033[0m Instructions DSFR/RGAA/ANSSI ajoutées au projet"
  fi
  opencode "$@"
}
FUNC

  success "Fonction 'albert-code' ajoutée à $shell_rc"
  info "Ouvre un nouveau terminal ou lance : source $shell_rc"
}

# ─────────────────────────────────────────────
# Étape 11 : Smoke test
# ─────────────────────────────────────────────

smoke_test() {
  info "Vérification..."

  # Test Ollama API
  if curl -sf http://localhost:11434/v1/models >/dev/null 2>&1; then
    success "API Ollama accessible (localhost:11434)"
  else
    warn "API Ollama non accessible — vérifie qu'Ollama tourne"
  fi

  # Test modèle présent
  if ollama list 2>/dev/null | grep -q "$MODEL_ID"; then
    success "Modèle $MODEL_ID disponible"
  else
    warn "Modèle $MODEL_ID non trouvé dans ollama list"
  fi

  # Test OpenCode
  if command -v opencode &>/dev/null; then
    success "OpenCode accessible"
  else
    warn "OpenCode non trouvé dans le PATH"
  fi

  # Test config
  if [[ -f "$HOME/.config/opencode/opencode.jsonc" ]]; then
    success "Configuration OpenCode présente"
  else
    warn "Configuration OpenCode manquante"
  fi
}

# ─────────────────────────────────────────────
# Étape 12 : Récapitulatif
# ─────────────────────────────────────────────

print_summary() {
  echo ""
  echo -e "${BOLD}╔══════════════════════════════════════╗${NC}"
  echo -e "${BOLD}║       Installation terminée !        ║${NC}"
  echo -e "${BOLD}╚══════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${GREEN}✓${NC} Ollama (inférence locale)"
  echo -e "  ${GREEN}✓${NC} Modèle ${BOLD}$MODEL_NAME${NC}"
  echo -e "  ${GREEN}✓${NC} OpenCode (assistant IA terminal)"
  if [[ -n "$INSTALLED_SKILLS" ]]; then
    echo -e "  ${GREEN}✓${NC} Skills : $INSTALLED_SKILLS"
  else
    echo -e "  ${YELLOW}⚠${NC} Aucune skill installée"
  fi
  if [[ "$HAS_NODE" == "true" ]]; then
    echo -e "  ${GREEN}✓${NC} MCP Chrome DevTools (l'IA voit ton navigateur)"
  else
    echo -e "  ${YELLOW}⚠${NC} MCP Chrome DevTools non disponible (Node.js requis)"
  fi
  echo -e "  ${GREEN}✓${NC} Commande ${BOLD}albert-code${NC} disponible"
  echo ""
  echo -e "  ${BOLD}100% local — tes données restent sur ta machine.${NC}"
  echo ""
  echo -e "  ${BOLD}Pour commencer :${NC}"
  echo ""
  echo -e "    ${BLUE}cd ton-projet${NC}"
  echo -e "    ${BLUE}albert-code${NC}"
  echo ""
  echo -e "  (Ouvre un nouveau terminal pour que la commande soit disponible)"
  echo ""
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

print_banner
check_macos
detect_machine
select_model
install_ollama
start_ollama
pull_model
install_opencode
configure_opencode
check_nodejs
install_skills
create_alias
smoke_test
print_summary
