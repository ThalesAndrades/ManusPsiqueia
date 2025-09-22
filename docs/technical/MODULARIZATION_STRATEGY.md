# Estratégia de Modularização Avançada

**Data:** 22 de setembro de 2025  
**Autor:** Manus AI  
**Projeto:** ManusPsiqueia

## 1. Visão Geral

A modularização é um pilar fundamental da arquitetura do ManusPsiqueia, projetada para criar um sistema desacoplado, escalável e de fácil manutenção. Esta estratégia transforma o projeto de um monólito em um ecossistema de pacotes Swift (Swift Packages) independentes e interdependentes, cada um com uma responsabilidade clara e bem definida.

Os principais objetivos desta estratégia são:

-   **Acelerar a Compilação:** Reduzir os tempos de build, permitindo que o Xcode compile apenas os módulos que foram alterados.
-   **Promover a Reutilização:** Facilitar o compartilhamento de código (UI, serviços, lógica de negócio) entre diferentes projetos da AiLun Tecnologia.
-   **Melhorar a Organização:** Isolar funcionalidades em domínios claros, tornando o código mais fácil de navegar e entender.
-   **Aumentar a Testabilidade:** Permitir que cada módulo seja testado de forma independente e focada.
-   **Facilitar o Desenvolvimento em Equipe:** Reduzir conflitos e permitir que desenvolvedores trabalhem em paralelo em diferentes módulos.

## 2. Arquitetura de Módulos Proposta

A arquitetura modular do ManusPsiqueia é dividida em camadas, desde os módulos de base, que não conhecem a lógica de negócio, até os módulos de features, que compõem a experiência do usuário.

![Diagrama de Dependência de Módulos](module_dependency_diagram.png)

### Camadas da Arquitetura

#### Camada 1: Módulos de Base (Foundation)

Estes são os módulos mais fundamentais e reutilizáveis. Eles não têm conhecimento da lógica de negócio específica do ManusPsiqueia e podem ser usados em qualquer projeto.

| Módulo | Descrição | Responsabilidades |
| :--- | :--- | :--- |
| **ManusPsiqueiaUI** | Biblioteca de componentes de UI. | - Componentes SwiftUI (botões, campos).<br>- Sistema de temas (cores, fontes).<br>- Animações e estilos. |
| **ManusPsiqueiaServices** | Encapsula todas as integrações com serviços externos. | - Clientes de API (REST, GraphQL).<br>- SDKs de terceiros (Stripe, Supabase).<br>- Serviços de baixo nível (rede, segurança). |

#### Camada 2: Módulo Core

Este módulo contém a lógica de negócio central e os modelos de dados que são compartilhados por todo o aplicativo.

| Módulo | Descrição | Responsabilidades |
| :--- | :--- | :--- |
| **ManusPsiqueiaCore** | Lógica de negócio e modelos de dados compartilhados. | - Modelos de dados (User, Subscription).<br>- Lógica de negócio agnóstica de UI.<br>- `Managers` e `Repositories` centrais. |

#### Camada 3: Módulos de Features

Cada funcionalidade principal do aplicativo é encapsulada em seu próprio módulo. Estes módulos dependem das camadas inferiores (Core, UI, Services) para construir sua funcionalidade.

| Módulo | Descrição | Responsabilidades |
| :--- | :--- | :--- |
| **DiaryFeature** | Funcionalidade completa do diário do paciente. | - Views, ViewModels e lógica do diário.<br>- Análise de sentimentos e insights. |
| **AuthenticationFeature** | Fluxo de login, registro e onboarding. | - Telas de autenticação.<br>- Gerenciamento de sessão do usuário. |
| **PaymentFeature** | Gestão de assinaturas e pagamentos. | - Telas de planos e checkout.<br>- Histórico de pagamentos. |

#### Camada 4: Aplicação Principal

Este é o ponto de entrada do aplicativo. Sua principal responsabilidade é montar os diferentes módulos de features e configurar o ambiente da aplicação.

| Módulo | Descrição | Responsabilidades |
| :--- | :--- | :--- |
| **ManusPsiqueia App** | O executável principal do aplicativo. | - Configuração inicial (injeção de dependência).<br>- Navegação principal (Tab Bar, etc.).<br>- Composição dos módulos de features. |

## 3. Princípios de Design dos Módulos

-   **Dependência Unidirecional:** As dependências devem sempre fluir das camadas superiores para as inferiores. Um módulo de feature nunca deve depender de outro módulo de feature diretamente.
-   **Interface Explícita:** Cada módulo deve expor uma API pública clara e bem documentada. A comunicação entre módulos deve ocorrer apenas através dessas APIs públicas.
-   **Alta Coesão, Baixo Acoplamento:** Cada módulo deve ter uma responsabilidade única e bem definida (alta coesão) e ter o mínimo de conhecimento sobre os outros módulos (baixo acoplamento).
-   **Injeção de Dependência:** As dependências de um módulo devem ser injetadas em seu inicializador, facilitando a substituição por mocks durante os testes.

## 4. Roadmap de Modularização

A modularização será implementada em fases para minimizar o impacto no desenvolvimento contínuo.

| Fase | Módulos a Serem Criados | Descrição | Prazo |
| :--- | :--- | :--- | :--- |
| **1 (Concluída)** | `ManusPsiqueiaUI`, `ManusPsiqueiaServices` | Criação dos módulos de base para UI e serviços externos. | Q3 2025 |
| **2** | `ManusPsiqueiaCore` | Extrair todos os modelos de dados, managers e lógica de negócio compartilhada para um módulo central. | Q4 2025 |
| **3** | `AuthenticationFeature`, `DiaryFeature` | Isolar as funcionalidades de autenticação e diário em seus próprios módulos. | Q1 2026 |
| **4** | `PaymentFeature`, `DashboardFeature` | Modularizar as funcionalidades de pagamento e os dashboards principais. | Q2 2026 |
| **5** | **Refatoração Final** | Limpar o projeto principal, que passará a ser apenas um integrador de módulos. | Q3 2026 |

## 5. Impacto no Desenvolvimento

### Estrutura de Pastas

Todos os módulos residirão na pasta `Modules/` na raiz do projeto, facilitando a localização e o gerenciamento.

### Gerenciamento de Dependências

Cada módulo terá seu próprio arquivo `Package.swift`, onde suas dependências externas são declaradas. O projeto principal, por sua vez, dependerá dos módulos locais.

### Processo de Build

O Xcode identificará automaticamente as dependências entre os módulos e realizará a compilação de forma otimizada. Os desenvolvedores não precisarão de nenhuma configuração adicional para compilar e executar o projeto.

## 6. Conclusão

A estratégia de modularização avançada é um investimento crucial na saúde e na longevidade do código-base do ManusPsiqueia. Ao adotar uma arquitetura modular desde o início, garantimos que o projeto possa crescer de forma sustentável, mantendo a agilidade no desenvolvimento, a alta qualidade do código e a capacidade de adaptação a novas oportunidades e desafios.

Esta abordagem não apenas melhora a eficiência técnica, mas também capacita a equipe de desenvolvimento a trabalhar de forma mais autônoma e colaborativa, resultando em um produto final mais robusto e confiável para nossos usuários.
