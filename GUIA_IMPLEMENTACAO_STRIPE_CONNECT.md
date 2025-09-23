# Guia de Implementação do Stripe Connect na Plataforma ManusPsiqueia

## 1. Visão Geral

Este documento detalha a implementação do **Stripe Connect** na plataforma ManusPsiqueia, permitindo que psicólogos recebam pagamentos de pacientes de forma direta e segura. A integração foi projetada para ser robusta, segura e escalável, seguindo as melhores práticas de desenvolvimento e conformidade com o PCI DSS.

### Arquitetura da Solução

A integração utiliza os seguintes componentes principais:

- **StripeConnectManager**: Gerencia a criação, onboarding e atualização de contas conectadas (Express Accounts) para psicólogos.
- **SessionPaymentService**: Orquestra o fluxo de pagamento para sessões de terapia, calculando taxas, criando cobranças diretas e gerenciando o ciclo de vida do pagamento.
- **StripeConnectWebhookManager**: Processa eventos assíncronos do Stripe, como pagamentos bem-sucedidos, falhas e atualizações de contas.
- **Views SwiftUI**: Fornecem a interface de usuário para o onboarding de psicólogos, dashboard financeiro e histórico de transações.

## 2. Componentes Implementados

A seguir, uma descrição detalhada dos novos arquivos e suas responsabilidades.

### 2.1. Managers e Serviços

| Arquivo | Descrição |
| :--- | :--- |
| `StripeConnectManager.swift` | Responsável por toda a interação com a API do Stripe Connect. Cria contas, gera links de onboarding e gerencia o estado das contas dos psicólogos. |
| `SessionPaymentService.swift` | Orquestra o fluxo de pagamento de uma sessão. Ele utiliza o `StripeConnectManager` e o `StripeManager` para processar pagamentos, calcular taxas e registrar transações. |
| `StripeConnectWebhookManager.swift` | Lida com os webhooks enviados pelo Stripe. É crucial para manter o estado da aplicação sincronizado com o Stripe, confirmando pagamentos e atualizando contas. |

### 2.2. Modelos de Dados

| Arquivo | Descrição |
| :--- | :--- |
| `StripeConnectModels.swift` | Define todas as estruturas de dados relacionadas ao Stripe Connect, como `ConnectTransaction`, `ConnectPayout`, `FeeConfiguration`, e `SessionPayment`. |

### 2.3. Views e Interface de Usuário

| Arquivo | Descrição |
| :--- | :--- |
| `ConnectOnboardingView.swift` | Uma interface de usuário completa para o processo de onboarding de psicólogos no Stripe Connect. Guia o usuário através dos benefícios e requisitos. |
| `PsychologistFinancialDashboard.swift` | Apresenta um dashboard financeiro para os psicólogos, com métricas de receita, transações e ações rápidas. |
| `PaymentHistoryView.swift` | Exibe um histórico detalhado de todas as transações, com funcionalidades de busca e filtro. |

## 3. Fluxo de Pagamento

O fluxo de pagamento de uma sessão de terapia ocorre da seguinte forma:

1.  **Início do Pagamento**: O `SessionPaymentService` é acionado para processar o pagamento de uma sessão.
2.  **Verificação de Contas**: O serviço verifica se o psicólogo possui uma conta Stripe Connect ativa e se o paciente possui um ID de cliente Stripe. Se não existirem, são criados.
3.  **Cálculo de Taxa**: A taxa da plataforma é calculada com base na `FeeConfiguration`.
4.  **Criação do Payment Intent**: Um `PaymentIntent` é criado como uma **cobrança direta** na conta conectada do psicólogo, com a taxa da plataforma (`application_fee_amount`) especificada.
5.  **Confirmação do Paciente**: O paciente confirma o pagamento através do Payment Sheet do Stripe.
6.  **Webhook de Sucesso**: O Stripe envia um webhook `payment_intent.succeeded` para o backend da ManusPsiqueia.
7.  **Processamento do Webhook**: O `StripeConnectWebhookManager` recebe o evento, valida a assinatura e confirma o pagamento da sessão no `SessionPaymentService`.
8.  **Atualização do Status**: O status da `SessionPayment` é atualizado para `completed` e os fundos são disponibilizados na conta do psicólogo (menos a taxa da plataforma).

## 4. Configuração do Ambiente

Para que a integração funcione corretamente, as seguintes variáveis de ambiente devem ser configuradas no Xcode e no Xcode Cloud:

- `STRIPE_PUBLISHABLE_KEY`: A chave publicável do Stripe.
- `STRIPE_SECRET_KEY`: A chave secreta do Stripe (usada no backend).
- `STRIPE_WEBHOOK_SECRET`: O segredo do endpoint do webhook para validar os eventos recebidos.

### 4.1. Dependências

A dependência do `stripe-ios` no `Package.swift` foi atualizada para incluir o produto `StripeConnect`.

```swift
.target(
    name: "ManusPsiqueia",
    dependencies: [
        // ... outras dependências
        .product(name: "StripeConnect", package: "stripe-ios"),
    ]
),
```

## 5. Próximos Passos e Melhorias

- **Backend API**: Implementar os endpoints no backend para persistir os dados de transações, pagamentos e contas conectadas.
- **Testes Unitários e de Integração**: Expandir a cobertura de testes para os novos managers e serviços.
- **Dashboard do Paciente**: Criar uma view para que os pacientes possam ver seu histórico de pagamentos.
- **Tratamento de Disputas**: Implementar a lógica para gerenciar disputas (chargebacks) através de webhooks e da API.

## 6. Conclusão

A implementação do Stripe Connect fornece uma base sólida para a monetização da plataforma ManusPsiqueia, permitindo um fluxo de pagamento seguro e eficiente entre pacientes e psicólogos. A arquitetura modular facilita a manutenção e a expansão futura do sistema de funcionalidades financeiras.

