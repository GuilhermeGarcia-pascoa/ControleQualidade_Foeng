# 🧪 Script de Testes - Validação com Express-Validator (PowerShell)
# Uso: .\test-validation.ps1 -Token "seu_jwt_token"

param(
    [string]$Token = "seu_token_jwt_aqui",
    [string]$BaseURL = "http://localhost:3000/api"
)

Write-Host "🧪 Iniciando testes de validação com Express-Validator" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Base URL: $BaseURL" -ForegroundColor Gray
Write-Host "Token: $($Token.Substring(0, 20))..." -ForegroundColor Gray
Write-Host ""

function Test-Endpoint {
    param(
        [int]$Number,
        [string]$Description,
        [string]$Method,
        [string]$Endpoint,
        [object]$Body,
        [bool]$RequireAuth = $false
    )
    
    Write-Host "[TESTE $Number]" -ForegroundColor Yellow -NoNewline
    Write-Host " $Description" -ForegroundColor White
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if ($RequireAuth) {
        $headers["Authorization"] = "Bearer $Token"
    }
    
    try {
        if ($Method -eq "POST" -or $Method -eq "PUT") {
            $response = Invoke-WebRequest -Uri "$BaseURL$Endpoint" `
                -Method $Method `
                -Headers $headers `
                -Body ($Body | ConvertTo-Json) `
                -ErrorAction Stop
        } else {
            $response = Invoke-WebRequest -Uri "$BaseURL$Endpoint" `
                -Method $Method `
                -Headers $headers `
                -ErrorAction Stop
        }
        
        Write-Host "❌ FALHA: Validação não rejeitou dados inválidos!" -ForegroundColor Red
        Write-Host "Response: $($response.Content)" -ForegroundColor Gray
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.Value__
        $content = $_.ErrorDetails.Message
        
        if ($statusCode -eq 400) {
            Write-Host "✅ SUCESSO: HTTP 400 retornado" -ForegroundColor Green
            $json = $content | ConvertFrom-Json
            if ($json.success -eq $false -and $json.errors) {
                Write-Host "   Erros encontrados: $($json.errors.Count)" -ForegroundColor Gray
                foreach ($error in $json.errors) {
                    Write-Host "   - Campo: $($error.campo)" -ForegroundColor DarkGray
                    Write-Host "     Mensagem: $($error.mensagem)" -ForegroundColor DarkGray
                }
            }
        } else {
            Write-Host "⚠️  WARNING: HTTP $statusCode (esperado 400)" -ForegroundColor Yellow
            Write-Host "Response: $content" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
}

# Testes

Test-Endpoint -Number 1 `
    -Description "Login com email inválido" `
    -Method "POST" `
    -Endpoint "/auth" `
    -Body @{email="invalido"; password="password123"}

Test-Endpoint -Number 2 `
    -Description "Login com password muito curta" `
    -Method "POST" `
    -Endpoint "/auth" `
    -Body @{email="test@example.com"; password="123"}

Test-Endpoint -Number 3 `
    -Description "Criar projeto com nome vazio" `
    -Method "POST" `
    -Endpoint "/projetos" `
    -Body @{nome=""; descricao="Teste"; criado_por=1} `
    -RequireAuth $true

Test-Endpoint -Number 4 `
    -Description "Criar nó com projeto_id inválido" `
    -Method "POST" `
    -Endpoint "/nos" `
    -Body @{projeto_id="abc"; nome="Pasta"; pai_id=$null} `
    -RequireAuth $true

Test-Endpoint -Number 5 `
    -Description "Criar registo com JSON inválido" `
    -Method "POST" `
    -Endpoint "/registos" `
    -Body @{no_id=1; dados_json="{campo:valor}"} `
    -RequireAuth $true

Test-Endpoint -Number 6 `
    -Description "Criar utilizador com email inválido" `
    -Method "POST" `
    -Endpoint "/utilizadores" `
    -Body @{nome="João"; email="invalido"; password="pass1234"; perfil="trabalhador"} `
    -RequireAuth $true

Test-Endpoint -Number 7 `
    -Description "Criar utilizador com perfil inválido" `
    -Method "POST" `
    -Endpoint "/utilizadores" `
    -Body @{nome="João"; email="joao@example.com"; password="pass1234"; perfil="superuser"} `
    -RequireAuth $true

Test-Endpoint -Number 8 `
    -Description "Criar campo com tipo inválido" `
    -Method "POST" `
    -Endpoint "/campos" `
    -Body @{no_id=1; nome_campo="Status"; tipo_campo="custom"; opcoes=$null; obrigatorio=$true}

Test-Endpoint -Number 9 `
    -Description "Obter registos com limit > 100" `
    -Method "GET" `
    -Endpoint "/registos/1?limit=200&page=1" `
    -RequireAuth $true

Test-Endpoint -Number 10 `
    -Description "GET com projeto_id inválido" `
    -Method "GET" `
    -Endpoint "/projetos/abc/contagem" `
    -RequireAuth $true

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Testes concluídos!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Dicas:" -ForegroundColor Cyan
Write-Host "  • Todos os testes devem retornar HTTP 400" -ForegroundColor Gray
Write-Host "  • Response deve incluir 'success: false'" -ForegroundColor Gray
Write-Host "  • Array 'errors' com campo, mensagem e valor" -ForegroundColor Gray
Write-Host "  • Uso: .\test-validation.ps1 -Token 'seu_jwt_token'" -ForegroundColor Gray
Write-Host "  • Certifique-se que o API está rodando em $BaseURL" -ForegroundColor Gray
