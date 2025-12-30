#!/usr/bin/env bash
# Release workflow: merge develop into main and optionally create a semantic version tag.
# Steps:
#   1. Ensure working tree is clean
#   2. Update develop and main from origin
#   3. Merge develop into main with --no-ff (dynamic message built from argument + log)
#   4. Push main to origin
#   5. (Optional) Calculate and push the next annotated semantic version tag (vX.Y.Z)

set -euo pipefail

#
# Argument parsing (padrão alinhado com scripts/git-develop-commit.sh)
#

VALID_TYPES=("feat" "fix" "refactor" "chore" "docs" "test" "style" "perf")
VALID_SCOPES=("dag" "controle" "sql" "docs" "utils" "config" "operators" "monitoring" "scripts" "release")

# Cores ANSI (paleta semelhante à do git-develop-commit.sh)
COLOR_HEADER='\033[95m'
COLOR_BLUE='\033[94m'
COLOR_CYAN='\033[96m'
COLOR_GREEN='\033[92m'
COLOR_YELLOW='\033[93m'
COLOR_RED='\033[91m'
COLOR_END='\033[0m'
COLOR_BOLD='\033[1m'
COLOR_UNDERLINE='\033[4m'

print_header() {
  local text="$1"
  printf "\n%b%s%b\n" "${COLOR_BOLD}${COLOR_CYAN}" "======================================================================" "${COLOR_END}"
  printf "%b %s %b\n" "${COLOR_BOLD}${COLOR_CYAN}" "$text" "${COLOR_END}"
  printf "%b%s%b\n\n" "${COLOR_BOLD}${COLOR_CYAN}" "======================================================================" "${COLOR_END}"
}

print_success() {
  printf "%b✓ %s%b\n" "${COLOR_GREEN}" "$*" "${COLOR_END}"
}

print_error() {
  printf "%b✗ %s%b\n" "${COLOR_RED}" "$*" "${COLOR_END}" >&2
}

print_info() {
  printf "%bℹ %s%b\n" "${COLOR_BLUE}" "$*" "${COLOR_END}"
}

print_warning() {
  printf "%b⚠ %s%b\n" "${COLOR_YELLOW}" "$*" "${COLOR_END}"
}

show_help() {
  cat >&2 <<'EOF'
Uso:
  scripts/git-release.sh [OPÇÕES] [COMMIT_SPEC]

Formatos de uso (escolha UM):

  1) Flags explícitas (tipo/scope/descrição):
     scripts/git-release.sh --type TYPE --scope SCOPE --description "Descrição" [--body "Corpo"] [--no-tag]

  2) Formato posicional com vírgulas:
     scripts/git-release.sh "type,scope,Descrição[,Corpo]" [--no-tag]

  3) Mensagem já formatada (modo legado):
     scripts/git-release.sh "type(scope): Descrição" [--no-tag]

Opções:
  -t, --type TYPE           Tipo do commit (feat, fix, refactor, chore, docs, test, style, perf)
  -s, --scope SCOPE         Escopo do commit (ex: dag, controle, sql, docs, utils, config, operators, monitoring, scripts, release)
  -d, --description DESC    Descrição curta do commit
  -b, --body TEXT           Corpo detalhado (opcional, adicionado abaixo do título no merge commit)
      --no-tag              Não criar tag semântica vX.Y.Z
  -h, --help                Mostrar esta ajuda e sair

Exemplos:
  scripts/git-release.sh --type chore --scope release --description "integrar melhorias em producao"
  scripts/git-release.sh --no-tag "docs,docs,integrar atualizacoes de documentacao"
  scripts/git-release.sh --no-tag "docs(docs): integrar atualizacoes de documentacao"
EOF
}

trim() {
  # Remove espaços em branco no início/fim
  local var="$1"
  var="${var#"${var%%[![:space:]]*}"}"
  var="${var%"${var##*[![:space:]]}"}"
  printf '%s' "$var"
}

is_in_list() {
  local value="$1"; shift
  local item
  for item in "$@"; do
    if [[ "$item" == "$value" ]]; then
      return 0
    fi
  done
  return 1
}

# Flags / argumentos
create_tag=true
commit_type=""
commit_scope=""
commit_description=""
commit_body=""
raw_spec=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    --no-tag)
      create_tag=false
      shift
      ;;
    -t|--type)
      if [[ $# -lt 2 ]]; then
        print_error "Faltando valor para $1"
        exit 1
      fi
      commit_type="$2"
      shift 2
      ;;
    -s|--scope)
      if [[ $# -lt 2 ]]; then
        print_error "Faltando valor para $1"
        exit 1
      fi
      commit_scope="$2"
      shift 2
      ;;
    -d|--description)
      if [[ $# -lt 2 ]]; then
        print_error "Faltando valor para $1"
        exit 1
      fi
      commit_description="$2"
      shift 2
      ;;
    -b|--body)
      if [[ $# -lt 2 ]]; then
        print_error "Faltando valor para $1"
        exit 1
      fi
      commit_body="$2"
      shift 2
      ;;
    --*)
      print_error "Opção desconhecida: $1"
      show_help
      exit 1
      ;;
    *)
      if [[ -n "$raw_spec" ]]; then
        print_error "Apenas um argumento posicional é permitido (COMMIT_SPEC)."
        show_help
        exit 1
      fi
      raw_spec="$1"
      shift
      ;;
  esac
done

has_flags=false
if [[ -n "$commit_type" || -n "$commit_scope" || -n "$commit_description" || -n "$commit_body" ]]; then
  has_flags=true
fi

has_positional=false
if [[ -n "$raw_spec" ]]; then
  has_positional=true
fi

if $has_flags && $has_positional; then
  print_error "Não use simultaneamente flags (--type/--scope/--description) e formato posicional."
  show_help
  exit 1
fi

if ! $has_flags && ! $has_positional; then
  print_error "Nenhuma especificação de commit fornecida."
  show_help
  exit 1
fi

merge_title=""

if $has_positional; then
  if [[ "$raw_spec" == *","* ]]; then
    # Formato "type,scope,description[,body]"
    p1="" p2="" p3="" p4=""
    IFS=',' read -r p1 p2 p3 p4 <<< "$raw_spec"
    p1="$(trim "${p1:-}")"
    p2="$(trim "${p2:-}")"
    p3="$(trim "${p3:-}")"
    p4="$(trim "${p4:-}")"

    if [[ -z "$p1" || -z "$p2" || -z "$p3" ]]; then
      print_error "Formato inválido. Esperado: 'type,scope,description[,body]'. Recebido: '$raw_spec'"
      exit 1
    fi

    commit_type="$p1"
    commit_scope="$p2"
    commit_description="$p3"
    commit_body="$p4"
  else
    # Modo legado: string já está no formato Conventional Commit completo
    merge_title="$raw_spec"
  fi
fi

if $has_flags; then
  # Valida flags obrigatórias
  if [[ -z "$commit_type" || -z "$commit_scope" || -z "$commit_description" ]]; then
    print_error "Quando usando flags, é obrigatório informar --type, --scope e --description"
    show_help
    exit 1
  fi
fi

# Se vieram type/scope/description (por flags ou posicional com vírgulas), validar e montar merge_title
if [[ -n "$commit_type" ]]; then
  if ! is_in_list "$commit_type" "${VALID_TYPES[@]}"; then
    print_error "Tipo inválido: '$commit_type'. Valores válidos: ${VALID_TYPES[*]}"
    exit 1
  fi

  if ! is_in_list "$commit_scope" "${VALID_SCOPES[@]}"; then
    print_error "Escopo inválido: '$commit_scope'. Valores válidos: ${VALID_SCOPES[*]}"
    exit 1
  fi

  if [[ -z "$merge_title" ]]; then
    merge_title="${commit_type}(${commit_scope}): ${commit_description}"
  fi
fi

if [[ -z "$merge_title" ]]; then
  print_error "Não foi possível determinar o título do merge commit. Verifique os argumentos."
  show_help
  exit 1
fi

# Validação de Conventional Commits (mantida)
if ! [[ $merge_title =~ ^(feat|fix|refactor|chore|docs|test|style|perf)(\([a-z0-9\-]+\))?:\ .+ ]]; then
  print_error "merge commit title deve seguir Conventional Commits: <type>(<scope>): <descrição>"
  print_error "Recebido: '$merge_title'"
  exit 1
fi

print_header "GIT RELEASE - develop → main"
print_info "Título do merge commit: $merge_title"
if $create_tag; then
  print_info "Modo de release: com tag semântica automática (vX.Y.Z)."
else
  print_warning "Modo de release: sem criação de tag semântica (--no-tag)."
fi

current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" != "develop" ]]; then
  print_warning "Recomendado iniciar o release a partir de 'develop' (branch atual: $current_branch)"
fi

# Ensure working tree is clean
if ! git diff --quiet || ! git diff --cached --quiet; then
  print_error "Working tree não está limpo. Faça commit, stash ou descarte as mudanças antes de rodar o release."
  exit 1
fi

print_info "Buscando últimas alterações de origin..."
git fetch --quiet origin

print_info "Atualizando branch local 'develop' a partir de origin/develop..."
git checkout develop >/dev/null
git pull --quiet origin develop

print_info "Atualizando branch local 'main' a partir de origin/main..."
git checkout main >/dev/null
git pull --quiet origin main



# Generate commit message using provided title and list of commits
print_info "Gerando mensagem de merge com histórico de commits..."
msg_file=$(mktemp)
echo "$merge_title" > "$msg_file"

if [[ -n "$commit_body" ]]; then
  echo "" >> "$msg_file"
  echo "$commit_body" >> "$msg_file"
fi

echo "" >> "$msg_file"
git log main..develop --pretty=format:"- %s" >> "$msg_file"

print_info "Realizando merge de 'develop' em 'main' com --no-ff..."
# Optional: print message to stdout for visibility
# cat "$msg_file"

git merge --no-ff --quiet develop -F "$msg_file"
rm "$msg_file"

print_info "Enviando branch 'main' para origin..."
git push --quiet origin main

if [[ "$create_tag" == true ]]; then
	print_info "Preparando tag semântica para o release..."

  # Semantic version tag: vX.Y.Z
  #    - Find latest semantic tag matching ^v[0-9]+\.[0-9]+\.[0-9]+$
  last_semver_tag=""
  while IFS= read -r tag; do
    if [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      last_semver_tag="$tag"
      break
    fi
  done < <(git tag --list 'v*' --sort=-version:refname)

  if [[ -z "$last_semver_tag" ]]; then
    # No semantic tags yet; start from v0.0.1
    major=0
    minor=0
    patch=1
	  else
	    if [[ $last_semver_tag =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
      major="${BASH_REMATCH[1]}"
      minor="${BASH_REMATCH[2]}"
      patch="${BASH_REMATCH[3]}"
      patch=$((patch + 1))
	      else
	        print_error "Última tag semântica '$last_semver_tag' não segue o padrão esperado vX.Y.Z"
	        exit 1
	      fi
  fi

	  semver_tag="v${major}.${minor}.${patch}"

	  print_info "Próxima versão semântica: $semver_tag (última: ${last_semver_tag:-none})"

	  # Ensure that the semantic version tag does not already exist
	  if git rev-parse -q --verify "refs/tags/$semver_tag" >/dev/null; then
	    print_error "Tag semântica $semver_tag já existe. Abortando."
	    exit 1
	  fi

	  print_info "Criando tag anotada $semver_tag..."
  git tag -a "$semver_tag" -m "Release $semver_tag - $merge_title"

	  print_info "Enviando tag semântica $semver_tag para origin..."
	  git push --quiet origin "$semver_tag"
else
	  print_warning "Criação de tag semântica ignorada (--no-tag)."
fi

print_info "Garantindo que as branches 'main' e 'develop' estão atualizadas localmente..."
git checkout main >/dev/null
git pull --quiet origin main

git checkout develop >/dev/null
git pull --quiet origin develop

print_header "RELEASE CONCLUÍDO"
print_success "Release finalizado com sucesso (develop → main)."
