# Gerenciamento Seguro de Chaves Secretas do Stripe

## 1. Visão Geral

Este documento descreve a implementação de um sistema robusto e seguro para o gerenciamento das chaves secretas do Stripe na plataforma ManusPsiqueia. O objetivo é proteger as chaves contra acesso não autorizado, vazamentos e uso indevido, seguindo as melhores práticas de segurança e conformidade com o PCI DSS.

A solução adota uma abordagem de defesa em profundidade, combinando criptografia forte, armazenamento seguro no Keychain, detecção de ambiente e auditoria contínua.

## 2. Componentes Principais

| Componente | Responsabilidade |
| :--- | :--- |
| `StripeSecurityManager.swift` | Orquestra todo o ciclo de vida das chaves: armazenamento, recuperação, validação, criptografia e auditoria. É o ponto central de controle para todas as operações de segurança relacionadas ao Stripe. |
| `StripeBackendService.swift` | Um serviço de backend que encapsula todas as chamadas para a API do Stripe que requerem a chave secreta. Ele utiliza o `StripeSecurityManager` para obter a chave de forma segura antes de fazer qualquer requisição. |
| `StripeKeysConfigurationView.swift` | Uma interface de administração que permite a configuração segura das chaves para diferentes ambientes (Desenvolvimento, Homologação, Produção). |
| `StripeConfiguration.xcconfig` | Arquivo de configuração que define as variáveis de ambiente para as chaves do Stripe, permitindo a injeção segura de chaves no Xcode Cloud. |

## 3. Mecanismos de Segurança

### 3.1. Armazenamento Seguro

- **Keychain**: Todas as chaves são armazenadas no Keychain do iOS, utilizando o atributo `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. Isso garante que as chaves só possam ser acessadas quando o dispositivo está desbloqueado e não são incluídas em backups do iCloud ou iTunes.

### 3.2. Criptografia

- **AES-256-GCM**: Antes de serem armazenadas no Keychain, as chaves são criptografadas usando o algoritmo AES-256-GCM, um padrão de criptografia autenticada que garante confidencialidade e integridade.
- **Chave Específica do Dispositivo**: A chave de criptografia é derivada de um identificador único do dispositivo (`identifierForVendor`), garantindo que uma chave criptografada em um dispositivo não possa ser descriptografada em outro.

### 3.3. Detecção de Ambiente

- **Separação de Chaves**: O sistema gerencia conjuntos de chaves separados para cada ambiente (`development`, `staging`, `production`).
- **Prevenção de Vazamento**: O `StripeSecurityManager` impede o uso de chaves de produção em ambientes de desenvolvimento ou homologação, reduzindo o risco de vazamentos acidentais.

### 3.4. Auditoria e Logging

- **AuditLogger**: Todas as operações críticas de segurança (armazenamento, acesso, remoção de chaves) são registradas pelo `AuditLogger`.
- **Auditoria de Segurança**: O `StripeSecurityManager` inclui uma função de auditoria (`performSecurityAudit`) que verifica a presença, validade e conformidade de todas as chaves configuradas.

## 4. Fluxo de Operação

1.  **Configuração (Admin)**: Um administrador utiliza a `StripeKeysConfigurationView` para inserir e salvar as chaves do Stripe para cada ambiente. As chaves são criptografadas e armazenadas no Keychain.
2.  **Inicialização da Aplicação**: Durante a inicialização, o `StripeManager` e outros serviços solicitam as chaves necessárias ao `StripeSecurityManager`.
3.  **Recuperação da Chave**: O `StripeSecurityManager` detecta o ambiente atual, recupera a chave criptografada correspondente do Keychain e a descriptografa em memória.
4.  **Uso da Chave Secreta**: O `StripeBackendService` recebe a chave secreta e a utiliza para autenticar requisições à API do Stripe. A chave nunca é exposta diretamente a outras partes da aplicação.
5.  **Uso da Chave Publicável**: O `StripeManager` recebe a chave publicável e a utiliza para configurar o SDK do Stripe no frontend.

## 5. Configuração no Xcode Cloud

Para garantir a segurança em CI/CD, as chaves secretas **NUNCA** devem ser commitadas no repositório. Em vez disso, elas devem ser configuradas como **variáveis de ambiente secretas** no Xcode Cloud:

- `STRIPE_PUBLISHABLE_KEY_PROD`
- `STRIPE_SECRET_KEY_PROD`
- `STRIPE_WEBHOOK_SECRET_PROD`

O arquivo `StripeConfiguration.xcconfig` está configurado para ler essas variáveis durante o processo de build.

## 6. Conclusão

Este sistema de gerenciamento de chaves secretas estabelece uma base de segurança sólida para a integração com o Stripe, protegendo as informações mais sensíveis da plataforma e garantindo a confiança dos usuários. A abordagem multicamadas dificulta significativamente o acesso não autorizado e fornece ferramentas para auditoria e conformidade contínuas.
