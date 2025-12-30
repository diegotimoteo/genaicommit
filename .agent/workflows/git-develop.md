---
description: Gera o comando de commit automático para desenvolvimento (scripts/git-develop-commit.sh).
---

description = "Gera o comando de commit automático para desenvolvimento (scripts/git-develop-commit.sh)."

prompt = """

<role>
Você é um desenvolvedor experiente utilizando o script de automação `scripts/git-develop-commit.sh`.
Seu objetivo é gerar o comando perfeito para commitar as alterações atuais no branch `develop`.
</role>

<context>
O script `scripts/git-develop-commit.sh` automatiza o `git add`, `git commit` e `git push` para o branch `develop`.
Ele agrupa arquivos por diretório se o escopo não for `*`.
Ele exige flags `--type`, `--scope`, `--description` (e opcionalmente `--body`).
</context>

<task>
Analise as alterações atuais (staged e unstaged) (`git diff HEAD`).
Determine o `type`, `scope` e `description` mais adequados.
Gere o comando para executar o script.
</task>

<rules>
    <allowed_types>
    Escolha um:
    *   **feat**: Novas funcionalidades.
    *   **fix**: Correções de bugs.
    *   **refactor**: Refatoração.
    *   **chore**: Tarefas gerais.
    *   **docs**: Documentação.
    *   **test**: Testes.
    *   **style**: Estilo.
    *   **perf**: Performance.
    </allowed_types>

    <allowed_scopes>
    Escolha um:
    *   **utils**, **controle**, **sql**, **dag**, **config**, **monitoring**, **scripts**, **docs**.
    *   **\*** (asterisco): Use este se as alterações tocarem em múltiplos componentes desconexos ou se você quiser agrupar TUDO em um único commit "geral".
    </allowed_scopes>

    <guidelines>
    *   Se as alterações forem focadas em um único componente (ex: apenas dags), use o escopo específico (ex: `dag`).
    *   Se forem alterações generalizadas, use `*`.
    *   A descrição deve ser concisa e no imperativo (ex: "Implementar x", "Corrigir y").
    </guidelines>

    <output_format>
    Gere APENAS o bloco de código com o comando:
    ```bash
    ./scripts/git-develop-commit.sh --type <TYPE> --scope <SCOPE> --description "<DESCRIÇÃO>"
    ```
    </output_format>
</rules>

<input_data>
```text
!{git diff HEAD --stat}
```
</input_data>

"""
