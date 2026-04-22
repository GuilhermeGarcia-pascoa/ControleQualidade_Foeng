# Implementação de Paginação e Filtros no Backend - Registros

## Alterações Realizadas

### Endpoint GET /registos/:noId
- **Arquivo modificado**: `src/routes/registos.js`
- **Novos parâmetros de query**:
  - `page` (padrão: 1) - Número da página (1-based)
  - `limit` (padrão: 50, máximo: 100)
  - `search` - String de busca
  - `filtroColuna` - Coluna específica ('_autor' ou nome do campo) ou null para todas

### Lógica de Filtros
- **Filtro por autor**: `filtroColuna = '_autor'` → filtra `u.nome`
- **Filtro por campo específico**: `filtroColuna = 'nome_campo'` → filtra `JSON_EXTRACT(dados, '$.nome_campo')`
- **Filtro geral**: `filtroColuna = null` → filtra autor + qualquer campo no JSON usando `JSON_SEARCH`

### Estrutura da Resposta
```json
{
  "success": true,
  "registos": [...],
  "total": 150,
  "page": 1,
  "limit": 50,
  "totalPages": 3
}
```

### Queries SQL Atualizadas
1. **Registros filtrados e paginados**:
   ```sql
   SELECT r.*, u.nome as nome_utilizador
   FROM registos r
   JOIN utilizadores u ON r.utilizador_id = u.id
   WHERE [whereClause com filtros]
   ORDER BY r.criado_em DESC
   LIMIT ? OFFSET ?
   ```

2. **Contagem total com filtros**:
   ```sql
   SELECT COUNT(*) as total FROM registos WHERE [countWhereClause com filtros]
   ```

## Como Testar
1. **Sem filtros**:
   ```
   GET /api/registos/1?page=1&limit=50
   ```

2. **Filtro por autor**:
   ```
   GET /api/registos/1?page=1&limit=50&search=João&filtroColuna=_autor
   ```

3. **Filtro por campo específico**:
   ```
   GET /api/registos/1?page=1&limit=50&search=valor&filtroColuna=nome_campo
   ```

4. **Filtro geral**:
   ```
   GET /api/registos/1?page=1&limit=50&search=termo
   ```

## Benefícios
- Filtros aplicados no backend antes da paginação
- Resultados precisos e consistentes
- Suporte a paginação clássica
- Performance otimizada para grandes datasets