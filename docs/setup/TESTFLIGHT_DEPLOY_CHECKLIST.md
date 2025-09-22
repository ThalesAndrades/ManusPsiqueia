# Checklist Final para Deploy no TestFlight via Xcode Cloud

**Data:** 22 de setembro de 2025  
**Autor:** Manus AI  
**Projeto:** ManusPsiqueia

## 1. Introdução

Este checklist garante que todos os passos críticos sejam verificados antes de iniciar um build no Xcode Cloud para deploy no TestFlight. Seguir este guia minimiza a chance de falhas no build e garante uma entrega bem-sucedida para os testadores.

## 2. Checklist de Pré-Build

### ✅ Configuração do Projeto

- [ ] **Bundle Identifiers:** Confirmar que os Bundle IDs para `Development`, `Staging` e `Production` estão corretos nos arquivos `.xcconfig`.
- [ ] **Versão e Build:** Verificar se `MARKETING_VERSION` e `CURRENT_PROJECT_VERSION` estão configurados corretamente nos arquivos `.xcconfig`.
- [ ] **Capacidades:** Garantir que todas as capacidades necessárias (Push Notifications, HealthKit, etc.) estão ativadas no Xcode Project.
- [ ] **Ícones e Launch Screen:** Confirmar que o `AppIcon` e a `Launch Screen` estão configurados corretamente no `Assets.xcassets`.
- [ ] **Info.plist:** Verificar se todas as chaves de permissão (`NSCameraUsageDescription`, etc.) estão presentes e com textos claros.

### ✅ Dependências e Módulos

- [ ] **Package.swift:** Garantir que todas as dependências externas estão com as versões corretas.
- [ ] **Módulos Locais:** Confirmar que todos os módulos em `Modules/` estão compilando sem erros.
- [ ] **Resolução de Dependências:** Executar `swift package resolve` localmente para garantir que não há conflitos.

### ✅ Gestão de Segredos e Variáveis de Ambiente

- [ ] **GitHub Secrets:** Confirmar que todos os segredos para `Staging` e `Production` estão configurados no GitHub Secrets.
- [ ] **Xcode Cloud Environment Variables:** Garantir que as seguintes variáveis estão configuradas no Xcode Cloud:
    - `DEVELOPMENT_TEAM_ID`
    - `STRIPE_PUBLISHABLE_KEY_STAGING`
    - `SUPABASE_URL_STAGING`
    - `SUPABASE_ANON_KEY_STAGING`
    - `OPENAI_API_KEY_STAGING`
- [ ] **Arquivos `.xcconfig`:** Verificar se os arquivos de configuração estão buscando as variáveis de ambiente corretamente (ex: `$(VAR_NAME)`).

### ✅ Scripts de CI/CD

- [ ] **`ci_post_clone.sh`:** Confirmar que o script está validando o ambiente e as configurações iniciais corretamente.
- [ ] **`ci_pre_xcodebuild.sh`:** Garantir que o script está configurando o ambiente de build e validando as variáveis de ambiente.
- [ ] **`ci_post_xcodebuild.sh`:** Verificar se o script está gerando relatórios e validando os artefatos do build.
- [ ] **Permissões:** Garantir que todos os scripts em `ci_scripts/` e `scripts/` têm permissão de execução (`chmod +x`).

### ✅ Assinatura de Código (Code Signing)

- [ ] **Certificados:** Confirmar que os certificados de `Apple Development` e `Apple Distribution` estão disponíveis e válidos no Xcode Cloud.
- [ ] **Provisioning Profiles:** Garantir que os provisioning profiles para `Development`, `Staging` (Ad Hoc/App Store) e `Production` (App Store) estão configurados e válidos.
- [ ] **`CODE_SIGN_STYLE`:** Verificar se está como `Automatic` nos arquivos `.xcconfig`.
- [ ] **`DEVELOPMENT_TEAM`:** Garantir que a variável `$(DEVELOPMENT_TEAM_ID)` está sendo usada nos arquivos `.xcconfig`.

## 3. Processo de Deploy no Xcode Cloud

1.  **Commit e Push:** Faça o commit de todas as alterações para a branch principal (`master` ou `main`).
2.  **Criar Build no Xcode Cloud:**
    - Vá para a seção `Cloud` no Xcode.
    - Selecione o workflow de `Staging`.
    - Inicie um novo build.
3.  **Monitorar o Build:**
    - Acompanhe o progresso do build no Xcode Cloud.
    - Verifique os logs dos scripts de CI/CD para garantir que tudo foi executado corretamente.
4.  **Verificar Artefatos:**
    - Após o build, verifique se o arquivo `.ipa` foi gerado.
    - Baixe e instale o app em um dispositivo de teste para uma verificação final.
5.  **Distribuir para TestFlight:**
    - Se o build for bem-sucedido, o Xcode Cloud automaticamente enviará o build para o App Store Connect.
    - Vá para a seção `TestFlight` no App Store Connect.
    - Adicione notas de teste e distribua a nova versão para os testadores internos e externos.

## 4. Checklist Pós-Deploy

- [ ] **Notificar Testadores:** Informar a equipe e os testadores beta que uma nova versão está disponível.
- [ ] **Monitorar Feedback:** Acompanhar os feedbacks e relatórios de crash no TestFlight.
- [ ] **Analisar Métricas:** Verificar as métricas de uso e performance (se aplicável).
- [ ] **Documentar Release:** Atualizar o `CHANGELOG.md` com as novidades da versão.

## 5. Solução de Problemas Comuns

-   **Falha na Assinatura de Código:**
    - **Causa:** Certificado ou provisioning profile expirado/inválido.
    - **Solução:** Verifique a validade dos certificados e profiles no Apple Developer Portal e no Xcode Cloud.
-   **Variável de Ambiente Não Encontrada:**
    - **Causa:** Variável não configurada no Xcode Cloud.
    - **Solução:** Adicione a variável de ambiente na seção `Environment Variables` do seu workflow no Xcode Cloud.
-   **Falha na Resolução de Dependências:**
    - **Causa:** Conflito de versões ou URL do pacote incorreta.
    - **Solução:** Execute `swift package resolve` localmente e verifique o `Package.swift`.
-   **Script de CI/CD Falhou:**
    - **Causa:** Erro de sintaxe ou permissão no script.
    - **Solução:** Verifique os logs do script no Xcode Cloud e teste o script localmente.

Seguindo este checklist, o processo de deploy para o TestFlight se tornará mais seguro, rápido e confiável.
