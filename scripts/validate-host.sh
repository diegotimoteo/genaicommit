#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔍 Validando qualidade do código Python (Host System)..."
echo "📍 Diretório: $PROJECT_ROOT"

# Verificar se ferramentas estão instaladas
for tool in black flake8 isort pylint; do
  if ! command -v "$tool" &> /dev/null; then
    echo "❌ Erro: $tool não está instalado no host system"
    echo "   Execute: pip install --user $tool"
    exit 1
  fi
done

echo ""
echo "📝 Verificando formatação com Black..."
black --check dags/ || {
  echo "⚠️  Código não está formatado. Execute: black dags/"
  exit 1
}

echo "✅ Black: OK"
echo ""

echo "📦 Verificando organização de imports com isort..."
isort --check-only dags/ || {
  echo "⚠️  Imports não estão organizados. Execute: isort dags/"
  exit 1
}

echo "✅ isort: OK"
echo ""

echo "🔎 Verificando problemas com Flake8..."
flake8 dags/ || {
  echo "⚠️  Flake8 encontrou problemas"
  exit 1
}

echo "✅ Flake8: OK"
echo ""

echo "🐍 Verificando com Pylint (avisos apenas)..."
pylint dags/ --exit-zero || true

echo ""
echo "✅ Validação concluída com sucesso!"
