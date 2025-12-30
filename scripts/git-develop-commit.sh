#!/usr/bin/env python3
"""Script para automatizar commits e pushes com agrupamento lógico de arquivos.

Detecta arquivos modificados, agrupa-os logicamente por diretório,
cria commits separados seguindo Conventional Commits e executa push.

Uso (formato com flags):
    ./scripts/git-develop-commit.sh --type feat --scope utils --description "Descrição" [--body "Detalhes"]
    ./scripts/git-develop-commit.sh -t feat -s utils -d "Descrição" -b "Detalhes adicionais"

    # Múltiplas descrições (uma por grupo):
    ./scripts/git-develop-commit.sh -t feat -s dag -d "Desc grupo 1|Desc grupo 2|Desc grupo 3"

Uso (formato posicional com vírgulas):
    ./scripts/git-develop-commit.sh "feat,utils,Descrição do commit"
    ./scripts/git-develop-commit.sh "feat,utils,Descrição,Corpo detalhado do commit"
    ./scripts/git-develop-commit.sh "feat,*,Agrupar todos os arquivos em um commit"
    ./scripts/git-develop-commit.sh "feat,dag,Desc grupo 1|Desc grupo 2"
"""

import argparse
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from collections import defaultdict


class Colors:
    """ANSI color codes para output colorido."""
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


def run_command(cmd: List[str], check: bool = True) -> Tuple[int, str, str]:
    """Executa comando shell e retorna (returncode, stdout, stderr)."""
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=False
        )
        return result.returncode, result.stdout.strip(), result.stderr.strip()
    except Exception as e:
        print(f"{Colors.RED}Erro ao executar comando: {e}{Colors.ENDC}")
        sys.exit(1)


def print_header(text: str) -> None:
    """Imprime header colorido."""
    print(f"\n{Colors.BOLD}{Colors.CYAN}{'='*70}{Colors.ENDC}")
    print(f"{Colors.BOLD}{Colors.CYAN}{text:^70}{Colors.ENDC}")
    print(f"{Colors.BOLD}{Colors.CYAN}{'='*70}{Colors.ENDC}\n")


def print_success(text: str) -> None:
    """Imprime mensagem de sucesso."""
    print(f"{Colors.GREEN}✓ {text}{Colors.ENDC}")


def print_error(text: str) -> None:
    """Imprime mensagem de erro."""
    print(f"{Colors.RED}✗ {text}{Colors.ENDC}")


def print_info(text: str) -> None:
    """Imprime mensagem informativa."""
    print(f"{Colors.BLUE}ℹ {text}{Colors.ENDC}")


def print_warning(text: str) -> None:
    """Imprime mensagem de aviso."""
    print(f"{Colors.YELLOW}⚠ {text}{Colors.ENDC}")


def check_and_switch_to_develop() -> bool:
    """Verifica se está na branch develop e oferece mudança automática se necessário."""
    # Verifica branch atual
    returncode, branch, _ = run_command(['git', 'rev-parse', '--abbrev-ref', 'HEAD'])
    if returncode != 0:
        print_error("Erro ao verificar branch atual")
        return False

    if branch != 'develop':
        print_warning(f"Você não está na branch 'develop'. Branch atual: {branch}")
        print_info("O script irá mudar para a branch 'develop' antes de executar os commits.")

        # Pergunta se deseja continuar
        response = input(f"{Colors.YELLOW}Deseja mudar para a branch 'develop'? (s/n): {Colors.ENDC}").strip().lower()
        if response not in ['s', 'sim', 'y', 'yes']:
            print_warning("Operação cancelada pelo usuário")
            return False

        # Muda para develop
        print_info("Mudando para a branch 'develop'...")
        returncode, _, stderr = run_command(['git', 'checkout', 'develop'])
        if returncode != 0:
            print_error(f"Erro ao mudar para a branch 'develop': {stderr}")
            return False

        print_success("Branch alterada para 'develop'")
    else:
        print_success(f"Branch atual: {branch}")

    return True


def check_git_status() -> bool:
    """Verifica se há mudanças no repositório."""
    # Verifica se há mudanças
    returncode, status, _ = run_command(['git', 'status', '--porcelain'])
    if returncode != 0:
        print_error("Erro ao verificar status do Git")
        return False

    if not status:
        print_warning("Nenhum arquivo modificado encontrado")
        return False

    print_success(f"Arquivos modificados encontrados")
    return True


def get_modified_files() -> List[str]:
    """Retorna lista de arquivos modificados."""
    returncode, output, _ = run_command(['git', 'status', '--porcelain'])
    if returncode != 0:
        print_error("Erro ao obter arquivos modificados")
        sys.exit(1)

    files = []
    for line in output.split('\n'):
        if line.strip():
            # Formato git status --porcelain: "XY filename"
            # X = index status, Y = worktree status (2 chars total)
            # Seguido de espaço(s) e o caminho do arquivo
            status = line[:2]
            filepath = line[2:].strip()  # Pega do índice 2 em diante e remove espaços
            if status.strip() and filepath:  # Ignora linhas vazias
                files.append(filepath)

    return files


def group_files_by_directory(files: List[str], use_wildcard: bool = False) -> Dict[str, List[str]]:
    """Agrupa arquivos dinamicamente pelo diretório pai ou em um único grupo (wildcard).

    Em vez de assumir uma estrutura fixa (ex: ``dags/etl_estoque``),
    o agrupamento passa a ser totalmente baseado no diretório pai real
    de cada arquivo, funcionando para N DAGs e qualquer layout de pastas
    no repositório.

    Args:
        files: Lista de caminhos de arquivos modificados.
        use_wildcard: Se True, agrupa todos os arquivos em um único grupo "*".
    """

    if use_wildcard:
        # Quando scope é "*", todos os arquivos vão em um único grupo
        return {"*": files}

    groups = defaultdict(list)

    for filepath in files:
        path = Path(filepath)
        parent = path.parent

        # Arquivos na raiz do repo ficam em um grupo explícito
        if str(parent) in ("", "."):
            group_key = "root"
        else:
            group_key = str(parent)

        groups[group_key].append(filepath)

    return dict(groups)


def display_file_groups(groups: Dict[str, List[str]]) -> None:
    """Exibe os grupos de arquivos de forma organizada."""
    print_info("Arquivos agrupados por diretório:")
    for group, files in sorted(groups.items()):
        print(f"\n  {Colors.BOLD}{group}/{Colors.ENDC}")
        for filepath in sorted(files):
            print(f"    • {filepath}")


def confirm_action(message: str) -> bool:
    """Solicita confirmação do usuário."""
    response = input(f"\n{Colors.YELLOW}{message} (s/n): {Colors.ENDC}").strip().lower()
    return response == 's'


def parse_comma_separated_format(
    positional_arg: str,
    valid_types: List[str],
    valid_scopes: List[str]
) -> Tuple[str, str, List[str], Optional[str]]:
    """Analisa formato posicional com vírgulas: "type,scope,description[,body]".

    Args:
        positional_arg: String no formato "type,scope,description" ou "type,scope,description,body"
                        A description pode conter múltiplas descrições separadas por '|'
        valid_types: Lista de tipos válidos
        valid_scopes: Lista de escopos válidos

    Returns:
        Tupla (type, scope, descriptions, body) onde:
            - descriptions é uma lista de strings (split por '|')
            - body pode ser None

    Raises:
        ValueError: Se o formato for inválido ou valores não forem válidos
    """
    # Divide em no máximo 4 partes (type, scope, description, body)
    # Isso permite que o body contenha vírgulas
    parts = positional_arg.split(',', 3)

    if len(parts) < 3:
        raise ValueError(
            f"Formato inválido. Esperado: 'type,scope,description[,body]'. "
            f"Recebido: '{positional_arg}'"
        )

    commit_type = parts[0].strip()
    scope = parts[1].strip()
    description_raw = parts[2].strip()
    body = parts[3].strip() if len(parts) == 4 else None

    # Faz split das múltiplas descrições por '|'
    descriptions = [d.strip() for d in description_raw.split('|') if d.strip()]

    # Valida type
    if commit_type not in valid_types:
        raise ValueError(
            f"Tipo inválido: '{commit_type}'. "
            f"Valores válidos: {', '.join(valid_types)}"
        )

    # Valida scope
    if scope not in valid_scopes:
        raise ValueError(
            f"Escopo inválido: '{scope}'. "
            f"Valores válidos: {', '.join(valid_scopes)}"
        )

    # Valida description
    if not descriptions:
        raise ValueError("Descrição não pode estar vazia")

    return commit_type, scope, descriptions, body


def create_commit_message(commit_type: str, scope: str, description: str, body: Optional[str] = None) -> str:
    """Cria mensagem de commit seguindo Conventional Commits.

    Args:
        commit_type: Tipo do commit (feat, fix, etc)
        scope: Escopo do commit
        description: Descrição curta do commit
        body: Corpo detalhado do commit (opcional)

    Returns:
        Mensagem de commit formatada
    """
    display_scope = "all" if scope == "*" else scope
    message = f"{commit_type}({display_scope}): {description}"

    if body:
        # Adiciona linha em branco e o corpo do commit
        message += f"\n\n{body}"

    return message


def execute_commits(
    groups: Dict[str, List[str]],
    commit_type: str,
    scope: str,
    descriptions: List[str],
    body: Optional[str] = None
) -> List[Tuple[str, str]]:
    """Executa commits e pushes para cada grupo de arquivos.

    Args:
        groups: Dicionário de grupos de arquivos
        commit_type: Tipo do commit
        scope: Escopo do commit
        descriptions: Lista de descrições (uma por grupo, com fallback)
        body: Corpo opcional do commit
    """
    commits_executed = []

    for group_idx, (group, files) in enumerate(sorted(groups.items()), 1):
        print_info(f"Processando grupo {group_idx}/{len(groups)}: {group}")

        # 1) Stage de modificações e deleções de arquivos já rastreados (-u)
        #    Usa diretórios-pai como pathspec para evitar erros de pathspec em arquivos
        #    deletados ou ainda não rastreados. Isso garante que arquivos com status "D"
        #    sejam incluídos corretamente no commit, sem tentar adicionar diretamente
        #    um caminho que já não existe no working tree.
        if files:
            parent_dirs = sorted({str(Path(f).parent) or '.' for f in files})
            returncode, _, stderr = run_command(['git', 'add', '-u', '--'] + parent_dirs)
            if returncode != 0:
                print_error(f"Erro ao adicionar arquivos modificados/removidos: {stderr}")
                continue

            # 2) Stage de novos arquivos (não rastreados) e alterações existentes
            #    Filtra apenas caminhos que ainda existem no working tree para evitar
            #    erros de pathspec em arquivos já deletados.
            existing_files = [f for f in files if Path(f).exists()]
            if existing_files:
                returncode, _, stderr = run_command(['git', 'add', '--'] + existing_files)
                if returncode != 0:
                    print_error(f"Erro ao adicionar novos arquivos: {stderr}")
                    continue

        # Obtém a descrição para este grupo (fallback para última se não houver suficientes)
        desc_idx = min(group_idx - 1, len(descriptions) - 1)
        current_description = descriptions[desc_idx]

        # Cria mensagem de commit
        commit_msg = create_commit_message(commit_type, scope, current_description, body)

        # Executa commit
        returncode, output, stderr = run_command(['git', 'commit', '-m', commit_msg])
        if returncode != 0:
            print_error(f"Erro ao criar commit: {stderr}")
            continue

        print_success(f"Commit criado: {commit_msg}")

        # Executa push
        returncode, output, stderr = run_command(['git', 'push', 'origin', 'develop'])
        if returncode != 0:
            print_error(f"Erro ao fazer push: {stderr}")
            continue

        print_success(f"Push realizado para origin/develop")
        commits_executed.append((commit_msg, group))

    return commits_executed


def display_summary(commits: List[Tuple[str, str]]) -> None:
    """Exibe resumo dos commits realizados."""
    print_header("RESUMO DOS COMMITS REALIZADOS")

    if not commits:
        print_warning("Nenhum commit foi realizado")
        return

    for idx, (msg, group) in enumerate(commits, 1):
        print(f"{Colors.GREEN}{idx}. {msg}{Colors.ENDC}")
        print(f"   Grupo: {Colors.CYAN}{group}{Colors.ENDC}\n")

    print_success(f"Total de commits realizados: {len(commits)}")


def main():
    """Função principal."""
    # Definições de valores válidos
    VALID_TYPES = ['feat', 'fix', 'refactor', 'chore', 'docs', 'test', 'style', 'perf']
    VALID_SCOPES = ['utils', 'controle', 'sql', 'dag', 'config', 'monitoring', 'scripts', 'docs', '*']

    parser = argparse.ArgumentParser(
        description='Automatiza commits e pushes com agrupamento lógico de arquivos',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Exemplos (formato com flags):
  ./scripts/git-develop-commit.sh --type feat --scope utils --description "Implementar retry"
  ./scripts/git-develop-commit.sh -t fix -s controle -d "Corrigir hash MD5" -b "Detalhes da correção"
  ./scripts/git-develop-commit.sh --type docs --scope config --description "Documentar conexão SQL"
  ./scripts/git-develop-commit.sh -t feat -s "*" -d "Agrupar todos em um commit"

Exemplos (formato posicional com vírgulas):
  ./scripts/git-develop-commit.sh "feat,utils,Implementar retry"
  ./scripts/git-develop-commit.sh "fix,controle,Corrigir hash MD5,Detalhes da correção"
  ./scripts/git-develop-commit.sh "feat,*,Agrupar todos em um commit"

Nota: Use OU o formato com flags OU o formato posicional, não ambos.
      O parâmetro --body/-b é opcional e adiciona uma descrição detalhada ao commit.
      Múltiplas descrições podem ser separadas por '|' (ex: "Desc1|Desc2|Desc3").
        '''
    )

    # Argumentos com flags (--type, --scope, --description, --body)
    parser.add_argument(
        '-t', '--type',
        choices=VALID_TYPES,
        help='Tipo do commit (ex: feat, fix, docs)'
    )
    parser.add_argument(
        '-s', '--scope',
        choices=VALID_SCOPES,
        help='Escopo do commit (ex: utils, controle, docs, dag, *)'
    )
    parser.add_argument(
        '-d', '--description',
        help='Descrição(ões) do commit. Use "|" para múltiplas (ex: "Desc1|Desc2")'
    )
    parser.add_argument(
        '-b', '--body',
        default=None,
        help='Corpo detalhado do commit (opcional)'
    )

    # Argumento posicional para formato com vírgulas
    parser.add_argument(
        'commit_string',
        nargs='?',
        default=None,
        help='Formato posicional: "type,scope,description[,body]" (ex: "feat,utils,Descrição,Detalhes")'
    )

    args = parser.parse_args()

    # Valida que ambos os formatos não foram usados simultaneamente
    has_flags = args.type is not None or args.scope is not None or args.description is not None
    has_positional = args.commit_string is not None

    if has_flags and has_positional:
        print_error(
            "Não use ambos os formatos simultaneamente. "
            "Use OU flags (--type, --scope, --description) OU formato posicional (\"type,scope,description\")."
        )
        sys.exit(1)

    if not has_flags and not has_positional:
        print_error(
            "Nenhum argumento fornecido. "
            "Use --type, --scope, --description OU formato posicional \"type,scope,description\"."
        )
        parser.print_help()
        sys.exit(1)

    # Parse dos argumentos
    if has_positional:
        try:
            commit_type, scope, description, body = parse_comma_separated_format(
                args.commit_string,
                VALID_TYPES,
                VALID_SCOPES
            )
        except ValueError as e:
            print_error(str(e))
            sys.exit(1)
    else:
        # Valida que todos os flags obrigatórios foram fornecidos
        if args.type is None or args.scope is None or args.description is None:
            print_error(
                "Quando usando flags, os três argumentos obrigatórios são: "
                "--type, --scope, --description (--body é opcional)"
            )
            sys.exit(1)
        commit_type = args.type
        scope = args.scope
        # Faz split das múltiplas descrições por '|'
        descriptions = [d.strip() for d in args.description.split('|') if d.strip()]
        body = args.body

    print_header("GIT DEVELOP COMMIT - AUTOMATIZADOR")

    # Validações iniciais
    # 1. Verifica e muda para develop se necessário
    if not check_and_switch_to_develop():
        sys.exit(1)

    # 2. Verifica se há arquivos modificados
    if not check_git_status():
        sys.exit(1)

    # Obtém arquivos modificados
    files = get_modified_files()
    print_info(f"Total de arquivos modificados: {len(files)}")

    # Agrupa arquivos (usa wildcard se scope for "*")
    use_wildcard = scope == "*"
    groups = group_files_by_directory(files, use_wildcard=use_wildcard)
    display_file_groups(groups)

    # Preview dos commits
    print_header("PREVIEW DOS COMMITS")
    sorted_groups = sorted(groups.keys())
    for idx, group in enumerate(sorted_groups, 1):
        # Obtém a descrição para este grupo (fallback para última se não houver suficientes)
        desc_idx = min(idx - 1, len(descriptions) - 1)
        current_description = descriptions[desc_idx]
        commit_msg = create_commit_message(commit_type, scope, current_description, body)
        print(f"{Colors.CYAN}{idx}. {commit_msg.split(chr(10))[0]}{Colors.ENDC}")  # Mostra só a primeira linha
        if body:
            print(f"   {Colors.YELLOW}Body: {body[:50]}...{Colors.ENDC}" if len(body) > 50 else f"   {Colors.YELLOW}Body: {body}{Colors.ENDC}")
        print(f"   Grupo: {group}\n")

    # Confirmação
    if not confirm_action("Deseja prosseguir com os commits e pushes?"):
        print_warning("Operação cancelada pelo usuário")
        sys.exit(0)

    # Executa commits
    print_header("EXECUTANDO COMMITS E PUSHES")
    commits = execute_commits(groups, commit_type, scope, descriptions, body)

    # Exibe resumo
    display_summary(commits)


if __name__ == '__main__':
    main()

