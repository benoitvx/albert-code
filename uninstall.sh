#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# Albert Code — Désinstallation
# Supprime la config, les skills et l'alias.
# Ne désinstalle PAS Ollama ni OpenCode.
# ─────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}▸${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }

echo ""
echo -e "${BOLD}Albert Code — Désinstallation${NC}"
echo ""

# ─────────────────────────────────────────────
# Supprimer les skills globales
# ─────────────────────────────────────────────

GLOBAL_SKILLS="$HOME/.config/opencode/skills"
for skill in react-dsfr rgaa securite-anssi; do
  if [[ -d "$GLOBAL_SKILLS/$skill" ]]; then
    rm -rf "$GLOBAL_SKILLS/$skill"
    success "Skill '$skill' supprimée"
  fi
done

# ─────────────────────────────────────────────
# Supprimer la config OpenCode (si Ollama)
# ─────────────────────────────────────────────

GLOBAL_CONFIG="$HOME/.config/opencode/opencode.jsonc"
if [[ -f "$GLOBAL_CONFIG" ]] && grep -q "ollama" "$GLOBAL_CONFIG" 2>/dev/null; then
  warn "Configuration OpenCode détectée (Ollama) : $GLOBAL_CONFIG"
  read -rp "  Supprimer ? [o/N] : " DELETE_CONFIG
  if [[ "$DELETE_CONFIG" == "o" || "$DELETE_CONFIG" == "O" ]]; then
    rm "$GLOBAL_CONFIG"
    success "Configuration supprimée"
  fi
fi

# ─────────────────────────────────────────────
# Supprimer le modèle Ollama (optionnel)
# ─────────────────────────────────────────────

if command -v ollama &>/dev/null; then
  echo ""
  info "Modèles Ollama installés :"
  ollama list 2>/dev/null || true
  echo ""
  read -rp "  Supprimer les modèles Qwen 3.5 d'Ollama ? [o/N] : " DELETE_MODEL
  if [[ "$DELETE_MODEL" == "o" || "$DELETE_MODEL" == "O" ]]; then
    for model in "qwen3.5:27b" "qwen3.5:35b-a3b"; do
      if ollama list 2>/dev/null | grep -q "$model"; then
        ollama rm "$model"
        success "Modèle $model supprimé"
      fi
    done
  fi
fi

# ─────────────────────────────────────────────
# Supprimer la fonction/alias du shell RC
# ─────────────────────────────────────────────

SHELL_NAME="$(basename "$SHELL")"
case "$SHELL_NAME" in
  zsh)  SHELL_RC="$HOME/.zshrc" ;;
  bash) SHELL_RC="$HOME/.bashrc" ;;
  *)    SHELL_RC="$HOME/.profile" ;;
esac

if grep -q "albert-code()" "$SHELL_RC" 2>/dev/null; then
  # Supprimer le bloc de fonction (du commentaire jusqu'à la fermeture)
  sed -i.bak '/# Albert Code — fonction/,/^}/d' "$SHELL_RC"
  rm -f "${SHELL_RC}.bak"
  success "Fonction albert-code supprimée de $SHELL_RC"
elif grep -q "alias albert-code=" "$SHELL_RC" 2>/dev/null; then
  sed -i.bak '/# Albert Code — alias/d' "$SHELL_RC"
  sed -i.bak '/alias albert-code=/d' "$SHELL_RC"
  rm -f "${SHELL_RC}.bak"
  success "Alias albert-code supprimé de $SHELL_RC"
fi

echo ""
success "Désinstallation terminée"
info "Ollama et OpenCode n'ont pas été désinstallés."
info "  Pour désinstaller Ollama : https://ollama.com/download (bouton Uninstall)"
info "  Pour désinstaller OpenCode : rm \$(which opencode)"
echo ""
