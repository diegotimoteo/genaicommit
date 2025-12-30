#!/usr/bin/env bash

# git-release-retag.sh
#
# Reescreve as tags de release garantindo:
# - Nenhuma tag "release-YYYY-MM-DD" permanece
# - Cada merge de release em main (first-parent, assunto/corpo contendo "release")
#   recebe exatamente uma tag semântica v0.0.N, em ordem cronológica.
#
# Uso:
#   ./scripts/git-release-retag.sh          # modo interativo (pede confirmação)
#   ./scripts/git-release-retag.sh --yes    # pula confirmação (uso consciente)

set -euo pipefail

SCRIPT_NAME="git-release-retag"
CONFIRM="no"

if [[ "${1-}" == "--yes" || "${1-}" == "-y" ]]; then
  CONFIRM="yes"
fi

log() {
  echo "[${SCRIPT_NAME}] $*"
}

# 1) Garantir que estamos em um repositório Git
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  log "Erro: este script deve ser executado dentro de um repositório Git."
  exit 1
fi

# 2) Garantir working tree limpo
if [[ -n "$(git status --porcelain)" ]]; then
  log "Erro: há mudanças não commitadas. Faça commit/stash antes de rodar este script."
  git status --short
  exit 1
fi

log "Atualizando branches main e develop a partir de origin..."

git fetch origin

if git rev-parse --verify main >/dev/null 2>&1; then
  git checkout main
  git pull origin main
else
  log "Erro: branch main não encontrada."
  exit 1
fi

if git rev-parse --verify develop >/dev/null 2>&1; then
  git checkout develop
  git pull origin develop || true
fi

# Volta para main para operar
git checkout main

log "Coletando tags existentes (release-* e v*)..."

release_tags=$(git tag -l 'release-*' || true)
semver_tags=$(git tag -l 'v*' || true)

log "Tags release-* encontradas:"
if [[ -n "${release_tags}" ]]; then
  echo "${release_tags}" | sed 's/^/  - /'
else
  echo "  (nenhuma)"
fi

log "Tags v* encontradas:"
if [[ -n "${semver_tags}" ]]; then
  echo "${semver_tags}" | sed 's/^/  - /'
else
  echo "  (nenhuma)"
fi

if [[ "${CONFIRM}" != "yes" ]]; then
  echo
  log "ATENÇÃO: as tags acima serão apagadas LOCALMENTE e em origin, e recriadas como v0.0.N."
  read -r -p "Deseja continuar? [y/N] " answer
  case "$answer" in
    y|Y) ;;
    *)
      log "Operação cancelada pelo usuário. Nenhuma tag foi alterada."
      exit 0
      ;;
  esac
fi

log "Removendo tags release-* locais e remotas..."
if [[ -n "${release_tags}" ]]; then
  while IFS= read -r t; do
    [[ -z "$t" ]] && continue
    log "  Deletando tag local $t"
    git tag -d "$t" || true
    log "  Deletando tag remota $t"
    git push origin ":refs/tags/$t" || true
  done <<< "${release_tags}"
fi

log "Removendo tags v* locais e remotas..."
if [[ -n "${semver_tags}" ]]; then
  while IFS= read -r t; do
    [[ -z "$t" ]] && continue
    log "  Deletando tag local $t"
    git tag -d "$t" || true
    log "  Deletando tag remota $t"
    git push origin ":refs/tags/$t" || true
  done <<< "${semver_tags}"
fi

log "Identificando commits de release em main (first-parent)..."

# Commits especiais de release que não contêm a palavra 'release' na mensagem,
# mas que devem ser considerados pontos de release iniciais.
SPECIAL_RELEASE_HASHES=(
  "0dab4c5a45cc07eddcbf4bd17519f48c43a0cc15"
  "dc393b3a49570ec5e9dc2e8759659392d77e7340"
  "54549ca55bd69301cd66c83c7cf6c226005fdd0c"
)

is_special_release() {
  local h="$1"
  local sh
  for sh in "${SPECIAL_RELEASE_HASHES[@]}"; do
    if [[ "$h" == "$sh" ]]; then
      return 0
    fi
  done
  return 1
}

release_commits=""

# Percorre o histórico de main (first-parent) em ordem cronológica e seleciona
# commits de release quando:
#   - a mensagem (subject) contém a palavra 'release', OU
#   - o hash está na lista SPECIAL_RELEASE_HASHES.
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  commit_hash="${line%% *}"
  subject="${line#* }"

  if [[ "$subject" == *release* ]] || is_special_release "$commit_hash"; then
    release_commits+="${commit_hash}
"
  fi
done < <(git log main --first-parent --reverse --format='%H %s')

if [[ -z "${release_commits}" ]]; then
  log "Nenhum commit de release encontrado em main. Abortando sem criar tags."
  exit 1
fi

log "Commits de release identificados (em ordem cronológica):"
idx=1
while IFS= read -r m; do
  [[ -z "$m" ]] && continue
  subj=$(git show -s --format='%s' "$m")
  log "  ${idx}: ${m}  ${subj}"
  idx=$((idx+1))
done <<< "${release_commits}"

log "Recriando tags semânticas v0.0.N para cada commit de release..."

idx=1
while IFS= read -r m; do
  [[ -z "$m" ]] && continue
  tag=$(printf 'v0.0.%d' "$idx")
  log "  Tagging ${m} como ${tag}"
  git tag -a "$tag" -m "Release $tag" "$m"
  idx=$((idx+1))
done <<< "${release_commits}"

log "Enviando tags para origin (push --force --tags)..."
git push origin --force --tags

log "Resumo final de tags (ordenadas):"
git tag --list --sort=refname || true

log "Commits de release em main com tags (first-parent):"
while IFS= read -r m; do
  [[ -z "$m" ]] && continue
  GIT_PAGER=cat git log -1 --oneline --decorate "$m" || true
done <<< "${release_commits}"

log "Concluído. Cada commit de release deve ter exatamente uma tag v0.0.N, sem tags release-*."
