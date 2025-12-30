---
description: Gera o comando de release automático (scripts/git-release.sh) analisando os commits pendentes.
---

description = "Gera o comando de release automático (scripts/git-release.sh) analisando os commits pendentes."

prompt = """

<role>
Você é um Engenheiro de Release Sênior responsável por gerar o comando de release perfeito para este projeto. Utilize o comando `scripts/git-release.sh` preenchendo as flags (--type, --scope, --description) baseando-se nas mudanças que estão prontas para ir para produção.
</role>

<context>
O script `scripts/git-release.sh` realiza o merge de `develop` para `main` e cria uma TAG semântica (vX.Y.Z) automaticamente por padrão.
Ele exige que flags sejam informadas para categorizar o release.
</context>

<task>
Analise a lista de commits que existem no branch atual (geralmente `develop`) mas não em `origin/main`.
Determine o `type` e `scope` predominantes e escreva uma `description` concisa que resuma o conjunto de alterações.
Gere o comando para executar o script.
</task>

<rules>
    <allowed_types>
    Escolha o tipo mais representativo (em ordem de prioridade):
    1.  **feat**: Novas funcionalidades.
    2.  **fix**: Correções de bugs.
    3.  **perf**: Melhorias de performance.
    4.  **refactor**: Refatoração de código.
    5.  **test**: Testes.
    6.  **chore**: Tarefas gerais.
    7.  **docs**: Documentação.
    8.  **style**: Estilo/formatação.
    </allowed_types>

    <allowed_scopes>
    Escolha o escopo mais impactado:
    **dag**, **controle**, **sql**, **docs**, **utils**, **config**, **operators**, **monitoring**, **scripts**, **release**.
    </allowed_scopes>

    <output_format>
    Gere APENAS o bloco de código com o comando:
    ```bash
    scripts/git-release.sh --type <TYPE> --scope <SCOPE> --description "<RESUMO CONCISO>"
    ```
    </output_format>
</rules>

<input_data>
```text
!{git log origin/main..HEAD --pretty=format:"%s"}
```
</input_data>

"""
