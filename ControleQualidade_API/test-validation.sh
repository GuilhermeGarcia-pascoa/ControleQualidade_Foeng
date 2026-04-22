#!/bin/bash

# 🧪 Script de Testes - Validação com Express-Validator
# Este script testa alguns endpoints com dados inválidos

API_URL="http://localhost:3000/api"
TOKEN="seu_token_jwt_aqui"

echo "🧪 Iniciando testes de validação..."
echo "═══════════════════════════════════"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Teste 1: Login com email inválido
echo -e "\n${YELLOW}[TESTE 1]${NC} Login com email inválido"
curl -s -X POST "$API_URL/auth" \
  -H "Content-Type: application/json" \
  -d '{"email":"invalido","password":"password123"}' | jq '.'

# Teste 2: Login com password curta
echo -e "\n${YELLOW}[TESTE 2]${NC} Login com password muito curta"
curl -s -X POST "$API_URL/auth" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123"}' | jq '.'

# Teste 3: Criar projeto com nome vazio
echo -e "\n${YELLOW}[TESTE 3]${NC} Criar projeto com nome vazio"
curl -s -X POST "$API_URL/projetos" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"nome":"","descricao":"Teste","criado_por":1}' | jq '.'

# Teste 4: Criar nó com projeto_id inválido
echo -e "\n${YELLOW}[TESTE 4]${NC} Criar nó com projeto_id inválido"
curl -s -X POST "$API_URL/nos" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"projeto_id":"abc","nome":"Pasta","pai_id":null}' | jq '.'

# Teste 5: Criar registo com JSON inválido
echo -e "\n${YELLOW}[TESTE 5]${NC} Criar registo com JSON inválido"
curl -s -X POST "$API_URL/registos" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"no_id":1,"dados_json":"{campo:valor}"}' | jq '.'

# Teste 6: Criar utilizador com email inválido
echo -e "\n${YELLOW}[TESTE 6]${NC} Criar utilizador com email inválido"
curl -s -X POST "$API_URL/utilizadores" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"nome":"João","email":"invalido","password":"pass1234","perfil":"trabalhador"}' | jq '.'

# Teste 7: Criar utilizador com perfil inválido
echo -e "\n${YELLOW}[TESTE 7]${NC} Criar utilizador com perfil inválido"
curl -s -X POST "$API_URL/utilizadores" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"nome":"João","email":"joao@example.com","password":"pass1234","perfil":"superuser"}' | jq '.'

# Teste 8: Criar campo com tipo inválido
echo -e "\n${YELLOW}[TESTE 8]${NC} Criar campo com tipo inválido"
curl -s -X POST "$API_URL/campos" \
  -H "Content-Type: application/json" \
  -d '{"no_id":1,"nome_campo":"Status","tipo_campo":"custom","opcoes":null,"obrigatorio":true}' | jq '.'

# Teste 9: Obter registos com limit inválido
echo -e "\n${YELLOW}[TESTE 9]${NC} Obter registos com limit > 100"
curl -s -X GET "$API_URL/registos/1?limit=200&page=1" \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# Teste 10: Endereço com ID inválido
echo -e "\n${YELLOW}[TESTE 10]${NC} GET com projeto_id inválido"
curl -s -X GET "$API_URL/projetos/abc/contagem" \
  -H "Authorization: Bearer $TOKEN" | jq '.'

echo -e "\n${GREEN}═══════════════════════════════════${NC}"
echo -e "${GREEN}✅ Testes concluídos!${NC}"
echo ""
echo "💡 Dicas:"
echo "  - Todos os testes devem retornar HTTP 400"
echo "  - Response deve incluir 'success: false'"
echo "  - Array 'errors' com campo, mensagem e valor"
echo "  - Substitua \$TOKEN por um JWT válido"
echo "  - Verifique que o API está rodando em http://localhost:3000"
