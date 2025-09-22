# Guia de Automação - ManusPsiqueia

**Data:** 22 de setembro de 2025  
**Autor:** Manus AI  
**Versão:** 1.0

## 1. Visão Geral

O projeto ManusPsiqueia utiliza uma série de scripts de automação para simplificar tarefas comuns de desenvolvimento, garantir a qualidade do código e padronizar processos como setup e deploy. Este guia descreve os scripts disponíveis e como utilizá-los.

Todos os scripts estão localizados no diretório `scripts/`.

## 2. Scripts Disponíveis

### 2.1. `setup_project.sh`

Este é o script mais importante para novos desenvolvedores. Ele automatiza todo o processo de configuração do ambiente de desenvolvimento.

**Funcionalidades:**
-   Verifica se todas as dependências necessárias (Xcode, Swift, Git) estão instaladas.
-   Resolve as dependências do Swift Package Manager.
-   Configura Git hooks para verificações pre-commit (linting e detecção de segredos).
-   Cria arquivos de configuração de exemplo (`.env.example`, `.swiftlint.yml`).
-   Executa testes para validar a configuração inicial.
-   Gera um relatório de setup com os próximos passos.

**Como Usar:**

```bash
# Navegue para o diretório raiz do projeto
cd /caminho/para/ManusPsiqueia

# Torne o script executável (apenas na primeira vez)
chmod +x scripts/setup_project.sh

# Execute o script
./scripts/setup_project.sh
```

### 2.2. `deploy.sh`

Este script automatiza o processo de build, assinatura e deploy do aplicativo para diferentes ambientes.

**Funcionalidades:**
-   Suporta deploy para `development`, `staging` (TestFlight) e `production` (App Store).
-   Executa testes antes do deploy (pode ser pulado).
-   Faz o build e o archive do aplicativo com as configurações corretas para cada ambiente.
-   Exporta o arquivo `.ipa`.
-   Faz o upload para o App Store Connect (para staging e production).
-   Gera um relatório de deploy detalhado.

**Como Usar:**

```bash
# Deploy para TestFlight
./scripts/deploy.sh staging

# Deploy para App Store (pulando testes)
./scripts/deploy.sh production --skip-tests

# Simular um deploy de desenvolvimento
./scripts/deploy.sh development --dry-run

# Ver todas as opções
./scripts/deploy.sh --help
```

**Pré-requisitos:**
-   Configure as variáveis de ambiente `APPLE_ID` e `APP_SPECIFIC_PASSWORD` para fazer o upload.
-   Configure a variável `DEVELOPMENT_TEAM_ID`.

### 2.3. `check_api_connectivity.sh`

Verifica a conectividade com todas as APIs externas e internas utilizadas pelo projeto.

**Funcionalidades:**
-   Testa a conexão com OpenAI, Stripe, Supabase e o backend do ManusPsiqueia.
-   Verifica endpoints específicos para cada ambiente.
-   Gera um relatório de conectividade com o status de cada serviço.

**Como Usar:**

```bash
./scripts/check_api_connectivity.sh
```

### 2.4. `project_health_monitor.sh`

Executa uma análise completa da "saúde" do projeto, verificando diversos aspectos de qualidade.

**Funcionalidades:**
-   Verifica a estrutura de arquivos e diretórios.
-   Analisa a configuração de segredos e variáveis de ambiente.
-   Verifica a implementação da modularização.
-   Analisa a configuração de CI/CD.
-   Calcula a cobertura de testes (se configurado).
-   Gera um relatório de saúde detalhado em Markdown.

**Como Usar:**

```bash
./scripts/project_health_monitor.sh
```

### 2.5. `validate_code_signing.sh`

Valida se as configurações de assinatura de código estão corretas para todos os ambientes.

**Funcionalidades:**
-   Verifica se os arquivos `.xcconfig` estão configurados corretamente.
-   Valida os Bundle IDs para cada ambiente.
-   Verifica se o `Info.plist` está usando variáveis de build.
-   Gera um relatório de validação.

**Como Usar:**

```bash
./scripts/validate_code_signing.sh
```

## 3. CI/CD com Xcode Cloud

O projeto está configurado para integração contínua e entrega contínua (CI/CD) com o Xcode Cloud. Os scripts de automação são utilizados nas diferentes fases do workflow.

**Scripts de CI/CD (localizados em `ci_scripts/`):**

-   **`ci_post_clone.sh`:** Executado após o clone do repositório. Ideal para instalar dependências ou ferramentas adicionais.
-   **`ci_pre_xcodebuild.sh`:** Executado antes do build. Usado para configurar variáveis de ambiente, gerar arquivos de configuração ou executar validações.
-   **`ci_post_xcodebuild.sh`:** Executado após o build. Usado para fazer upload de artefatos, enviar notificações ou gerar relatórios.

**Como Configurar no Xcode Cloud:**

1.  Vá para a configuração do seu workflow no Xcode Cloud.
2.  Na seção "Actions", adicione uma nova ação para cada fase (Post-Clone, Pre-Xcodebuild, Post-Xcodebuild).
3.  Configure cada ação para executar o script correspondente (ex: `ci_scripts/ci_pre_xcodebuild.sh`).
4.  Certifique-se de que os scripts tenham permissão de execução (`chmod +x`).

## 4. Como Criar um Novo Script

Ao criar um novo script de automação, siga estas boas práticas:

1.  **Use Bash:** Escreva scripts em Bash para garantir a compatibilidade.
2.  **Adicione `set -e`:** Use `set -e` no início do script para que ele pare imediatamente se um comando falhar.
3.  **Use Funções:** Organize seu código em funções para torná-lo mais legível e reutilizável.
4.  **Adicione Cores:** Use códigos de cores para diferenciar mensagens de sucesso, aviso e erro.
5.  **Crie uma Função de Ajuda:** Inclua uma função `show_help()` que explique como usar o script e quais são suas opções.
6.  **Adicione um Cabeçalho:** Inclua um cabeçalho com o nome do script, autor e data.
7.  **Localização:** Salve o novo script no diretório `scripts/`.
8.  **Permissão de Execução:** Não se esqueça de tornar o script executável com `chmod +x nome_do_script.sh`.

## 5. Conclusão

A automação é um pilar fundamental do projeto ManusPsiqueia. Utilizar os scripts disponíveis ajuda a manter a alta qualidade do projeto, reduzir erros manuais e acelerar o ciclo de desenvolvimento. Incentive todos os membros da equipe a se familiarizarem e utilizarem essas ferramentas em essas ferramentas.
