#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🎨 Formatando código Python (Host System)..."

echo "📝 Formatando com Black..."
black dags/

echo "📦 Organizando imports com isort..."
isort dags/

echo "🔍 Verificando com flake8..."
flake8 dags/ || echo "⚠️ flake8 encontrou alguns avisos (verifique acima)"

echo "✅ Formatação concluída!"
echo ""
echo "💡 Próximo passo: execute 'git diff' para revisar as mudanças"

