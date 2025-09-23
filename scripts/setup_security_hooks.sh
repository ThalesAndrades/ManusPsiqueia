#!/bin/bash

# Script para configurar hooks de segurança
# ManusPsiqueia - Setup de Segurança

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Configurando Hooks de Segurança - ManusPsiqueia${NC}"
echo "=================================================="
echo ""

# Verificar se estamos em um repositório git
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Este não é um repositório Git!${NC}"
    exit 1
fi

# Criar hook pre-commit
echo -e "${YELLOW}📝 Configurando hook pre-commit...${NC}"

cat > ".git/hooks/pre-commit" << 'EOF'
#!/bin/bash

# Pre-commit hook para detectar tokens expostos
# ManusPsiqueia - Hook de Segurança

set -e

echo "🔍 Executando verificação de segurança pré-commit..."

# Verificar se o script de detecção existe
if [ ! -f "scripts/secrets_manager.sh" ]; then
    echo "❌ Script de gerenciamento de segredos não encontrado!"
    exit 1
fi

# Executar detecção de tokens
if ! ./scripts/secrets_manager.sh scan; then
    echo ""
    echo "❌ COMMIT BLOQUEADO: Tokens suspeitos detectados!"
    echo ""
    echo "Para resolver:"
    echo "1. Remova os tokens dos arquivos"
    echo "2. Revogue os tokens nos serviços correspondentes"
    echo "3. Use variáveis de ambiente ou Keychain para armazenar secrets"
    echo "4. Adicione arquivos com secrets ao .gitignore"
    echo ""
    echo "Para pular esta verificação (NÃO RECOMENDADO):"
    echo "git commit --no-verify"
    echo ""
    exit 1
fi

echo "✅ Verificação de segurança concluída com sucesso!"
exit 0
EOF

# Tornar o hook executável
chmod +x ".git/hooks/pre-commit"

echo -e "${GREEN}✅ Hook pre-commit configurado!${NC}"
echo ""

# Testar o hook
echo -e "${YELLOW}🧪 Testando hook de segurança...${NC}"
if [ -x "scripts/secrets_manager.sh" ]; then
    if ./scripts/secrets_manager.sh scan > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Teste do hook passou!${NC}"
    else
        echo -e "${YELLOW}⚠️  Hook funcionando - tokens detectados (esperado se houver templates)${NC}"
    fi
else
    echo -e "${RED}❌ Script de detecção não encontrado ou não executável${NC}"
fi

echo ""
echo -e "${BLUE}📋 Configuração concluída!${NC}"
echo ""
echo -e "${YELLOW}💡 O que foi configurado:${NC}"
echo "   • Hook pre-commit para detectar tokens expostos"
echo "   • Verificação automática antes de cada commit"
echo "   • Bloqueio de commits com tokens suspeitos"
echo ""
echo -e "${YELLOW}💡 Como usar:${NC}"
echo "   • Os commits serão verificados automaticamente"
echo "   • Para pular a verificação: git commit --no-verify (NÃO RECOMENDADO)"
echo "   • Para verificar manualmente: ./scripts/secrets_manager.sh scan"
echo ""