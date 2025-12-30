# Git Helper Scripts – PBastones BI Airflow

Central documentation for the Git helper scripts in this project. These scripts automate common Git actions following the repository workflow and Conventional Commits.

- `scripts/git-develop-commit.sh`: automatiza commits e pushes na branch `develop`, com agrupamento lógico de arquivos.
- `scripts/git-release.sh`: automatiza o fluxo de release, fazendo merge de `develop` em `main` e, opcionalmente, criando uma tag semântica.

> **Importante**: ambos os scripts assumem que o repositório já está corretamente configurado com o workflow descrito em `docs/projeto/desenvolvimento.md` e seguem o padrão de mensagens de commit do projeto.

---

## 1. `git-develop-commit.sh`

Script Python que automatiza commits e pushes na branch `develop`, agrupando arquivos modificados por diretório (ou todos juntos com wildcard) e gerando mensagens no formato **Conventional Commits**.

### 1.1. O que ele faz

- Detecta arquivos modificados automaticamente (`git status --porcelain`)
- Agrupa arquivos por diretório pai ou em um único grupo (`*`)
- Cria **um commit por grupo** com a mesma mensagem
- Usa formato `type(scope): description` (Conventional Commits)
- Faz **push automático** para `origin/develop`
- Verifica/ajusta branch para `develop` (pergunta antes de trocar)
- Exibe preview e pede confirmação antes de commitar/pushar

### 1.2. Sintaxe básica

**Formato com flags (recomendado):**

```bash
./scripts/git-develop-commit.sh --type TYPE --scope SCOPE --description "Descrição" [--body "Corpo detalhado"]
```

Formas curtas:

```bash
./scripts/git-develop-commit.sh -t TYPE -s SCOPE -d "Descrição" [-b "Corpo"]
```

**Formato posicional com vírgulas:**

```bash
./scripts/git-develop-commit.sh "type,scope,Descrição[,Corpo]"
```

> Use **ou** o formato com flags **ou** o formato posicional, nunca os dois ao mesmo tempo.

### 1.3. Argumentos

- `-t, --type` (obrigatório com flags)
  - Um de: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `style`, `perf`
- `-s, --scope` (obrigatório com flags)
  - Um de: `utils`, `controle`, `sql`, `dag`, `config`, `monitoring`, `scripts`, `docs`, `*`
- `-d, --description` (obrigatório com flags)
  - Descrição curta do commit
- `-b, --body` (opcional)
  - Corpo detalhado do commit (segunda parte do Conventional Commit)
- `commit_string` (posicional, opcional)
  - Formato: `"type,scope,description[,body]"`

### 1.4. Exemplos

**Feature simples:**

```bash
./scripts/git-develop-commit.sh -t feat -s utils -d "Add retry logic"
```

**Bugfix com body:**

```bash
./scripts/git-develop-commit.sh -t fix -s controle -d "Corrigir cálculo de hash" \
  -b "Ajusta leitura em chunks para arquivos grandes."
```

**Formato posicional com body:**

```bash
./scripts/git-develop-commit.sh "feat,sql,Adicionar connection pooling,Reduz overhead de conexões."
```

**Wildcard (todos os arquivos em um único commit):**

```bash
./scripts/git-develop-commit.sh -t refactor -s "*" -d "Reorganizar estrutura do projeto"
```

### 1.5. Validações e comportamento

- Garante que há arquivos modificados; caso contrário, aborta com mensagem.
- Se não estiver em `develop`, oferece trocar automaticamente (pede confirmação).
- Mostra **preview** dos grupos de arquivos e das mensagens de commit antes de executar.
- Pede confirmação (`s/n`) antes de criar commits e fazer push.
- Cria sempre commits em `develop` e faz push para `origin/develop`.

---

## 2. `git-release.sh`

Script Bash que automatiza o fluxo de release:

1. Garante que o working tree está limpo.
2. Atualiza `develop` e `main` a partir de `origin`.
3. Faz merge de `develop` em `main` com `--no-ff`.
4. Faz push de `main` para `origin/main`.
5. (Opcional) Cria e envia uma nova tag semântica `vX.Y.Z`.

### 2.1. O que ele faz

- Valida que a mensagem de merge segue **Conventional Commits**.
- Gera mensagem de merge com título + lista de commits de `develop`.
- Permite incluir um `body` opcional (detalhes da release).
- Calcula **automaticamente** o próximo `vX.Y.Z` a partir das tags existentes.
- Pode ser executado em modo **sem tag** para merges apenas de documentação ou ajustes menores.

### 2.2. Sintaxe básica

O script suporta três formas de especificar a mensagem de merge.

#### (a) Flags estruturadas (recomendado)

```bash
./scripts/git-release.sh \
  --type TYPE \
  --scope SCOPE \
  --description "Descrição" \
  [--body "Corpo detalhado"] \
  [--no-tag]
```

#### (b) Formato posicional com vírgulas

```bash
./scripts/git-release.sh "type,scope,Descrição[,Corpo]" [--no-tag]
```

#### (c) Modo legado (mensagem pronta)

```bash
./scripts/git-release.sh "type(scope): Descrição" [--no-tag]
```

> Em todos os modos, o título final precisa obedecer a `type(scope): description` com `type` válido.

### 2.3. Flags e argumentos

- `-t, --type` (obrigatório se usar flags)
  - `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `style`, `perf`
- `-s, --scope` (obrigatório se usar flags)
  - Ex.: `dag`, `controle`, `sql`, `docs`, `utils`, `config`, `operators`, `monitoring`, `scripts`, `release`
- `-d, --description` (obrigatório se usar flags)
  - Descrição curta do merge da release
- `-b, --body` (opcional)
  - Corpo detalhado que será incluído na mensagem de merge (abaixo do título)
- `--no-tag` (opcional)
  - Executa o fluxo de merge **sem criar nem pushar** uma nova tag `vX.Y.Z`
- `-h, --help`
  - Mostra ajuda detalhada e exemplos

Quando usado no formato posicional:

- `"type,scope,description[,body]"` é parseado e validado contra os mesmos tipos e escopos.
- Se não houver vírgula, o script assume **modo legado** (string já está formatada como Conventional Commit completo).

### 2.4. Exemplos

**Release normal com tag:**

```bash
./scripts/git-release.sh \
  --type chore \
  --scope release \
  --description "integrar melhorias de producao"
```

**Merge de documentação sem criar tag:**

```bash
./scripts/git-release.sh --no-tag \
  --type docs \
  --scope docs \
  --description "integrar atualizacoes de documentacao"
```

**Formato posicional com body:**

```bash
./scripts/git-release.sh "feat,release,preparar release v0.1.0,Inclui novas DAGs e ajustes de performance."
```

**Modo legado (mensagem pronta):**

```bash
./scripts/git-release.sh "chore(release): integrar melhorias de Building Permits e logs do Telegram"
```

### 2.5. Validações e comportamento

- Exige working tree limpo (sem mudanças pendentes) antes de iniciar.
- Atualiza `develop` e `main` via `git pull origin <branch>`.
- Emite um **warning** se o script não for iniciado a partir de `develop`.
- Valida a mensagem de merge contra o padrão **Conventional Commits**.
- Gera arquivo temporário com:
  - Título (`type(scope): description`)
  - Opcionalmente, o `body` informado pelo usuário
  - Lista de mensagens dos commits de `develop` ainda não presentes em `main`, cada uma em uma linha no formato `- type(scope): description`.
- Sempre faz push para `origin/main`.
- Se **não** for usado `--no-tag`:
  - Calcula o próximo `vX.Y.Z` a partir das tags existentes `v*`.
  - Cria uma tag anotada `git tag -a vX.Y.Z -m "Release vX.Y.Z - <título>"`.
  - Faz push da tag para `origin`.
- Com `--no-tag`:
  - Pula completamente a criação e o push da tag, logando `Skipping semantic version tag creation (no-tag mode).`

---

## 3. Recomendações de uso

- Use `git-develop-commit.sh` no dia a dia, para organizar commits em `develop`.
- Use `git-release.sh` apenas quando for **integrar `develop` em `main`**.
- Para releases de **apenas documentação ou ajustes menores**, prefira `git-release.sh --no-tag` para não poluir o histórico de tags.
- Mantenha sempre o padrão de mensagens de commit conforme a convenção do projeto.

