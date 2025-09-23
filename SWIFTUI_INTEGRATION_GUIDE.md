# 🧩 Guia de Integração de Exemplos de Código SwiftUI no ManusPsiqueia

**Status:** ✅ **GUIA DE INTEGRAÇÃO CRIADO**

Este guia detalha o processo passo a passo para integrar os exemplos de código SwiftUI fornecidos no projeto ManusPsiqueia. O objetivo é incorporar as novas funcionalidades visuais de forma eficiente, organizada e alinhada com a arquitetura existente do projeto.

## 🎯 **Visão Geral da Integração**

Os exemplos de código serão integrados como novos componentes e modificadores dentro do target principal do aplicativo (`ManusPsiqueia`). Posteriormente, para maior modularidade e reutilização, eles podem ser movidos para o módulo `ManusPsiqueiaUI`.

## 📋 **Passo a Passo da Integração**

### **Fase 1: Adicionar os Arquivos de Código**

1.  **Crie um novo grupo (pasta) no Xcode** chamado `UI/Components` dentro do grupo `ManusPsiqueia` (o target principal do aplicativo).
2.  **Crie novos arquivos Swift/SwiftUI** dentro deste grupo para cada exemplo:
    *   `MaterialCardView.swift` (para o Exemplo 1.1)
    *   `AnimatedGradientBackground.swift` (para o Exemplo 1.2)
    *   `MatchedGeometryEffectExample.swift` (para o Exemplo 2.1)
    *   `PrimaryButtonStyleModifier.swift` (para o Exemplo 3.1)
3.  **Copie e cole o código** de cada exemplo para o seu respectivo arquivo.

    *   **Observação:** Certifique-se de que cada arquivo contenha apenas a `struct View` ou `ViewModifier` e suas `PreviewProvider`s associadas. Remova quaisquer `import SwiftUI` duplicados se o Xcode já os adicionar automaticamente.

### **Fase 2: Integrar `PrimaryButtonStyleModifier`**

O `PrimaryButtonStyleModifier` é um `ViewModifier` que pode ser aplicado a qualquer `Button` para padronizar seu estilo.

1.  **Localize os botões existentes** no seu aplicativo que devem ter o estilo primário (ex: botões de login, cadastro, confirmação).
2.  **Aplique o modificador** `.primaryButtonStyle()` a esses botões.

    *   **Exemplo:** Se você tem um botão na sua tela de login:

        ```swift
        // Antes
        Button("Entrar") {
            // Ação de login
        }
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)

        // Depois
        Button("Entrar") {
            // Ação de login
        }
        .primaryButtonStyle(backgroundColor: .purple, cornerRadius: 15) // Use as cores da sua marca
        ```

3.  **Ajuste as cores:** Modifique `backgroundColor` e `foregroundColor` no `PrimaryButtonStyleModifier` ou ao aplicá-lo para refletir a paleta de cores da marca Psiqueia (roxo, azul, rosa).

### **Fase 3: Integrar `MaterialCardView`**

O `MaterialCardView` pode ser usado para exibir informações importantes com um efeito translúcido.

1.  **Identifique áreas** onde cards informativos ou de destaque são usados (ex: dashboard do paciente, tela de insights, onboarding).
2.  **Substitua ou adicione** instâncias de `MaterialCardView`.

    *   **Exemplo:** Em uma tela de insights, você pode ter:

        ```swift
        // Antes
        VStack {
            Text("Seu Resumo Semanal")
            // ... outros elementos
        }
        .background(Color.white)
        .cornerRadius(10)

        // Depois
        MaterialCardView() // Ou crie uma versão customizada do seu card usando o conceito de Material
        ```

3.  **Personalize o conteúdo:** Adapte o `VStack` dentro de `MaterialCardView` para exibir o conteúdo específico do seu aplicativo.

### **Fase 4: Integrar `AnimatedGradientBackground`**

Este fundo dinâmico pode ser usado para criar uma atmosfera imersiva nas telas principais do aplicativo.

1.  **Identifique as telas principais** onde você deseja um fundo dinâmico (ex: tela de login/cadastro, tela inicial do diário, tela de insights).
2.  **Envolva o conteúdo da sua `View`** com `AnimatedGradientBackground`.

    *   **Exemplo:** Na sua `ContentView` ou na `LoginView`:

        ```swift
        // Antes
        struct LoginView: View {
            var body: some View {
                VStack {
                    // Campos de login
                }
                .background(Color.white.ignoresSafeArea())
            }
        }

        // Depois
        struct LoginView: View {
            var body: some View {
                AnimatedGradientBackground {
                    VStack {
                        // Campos de login
                    }
                }
            }
        }
        ```

3.  **Ajuste as cores do gradiente:** Modifique as cores dentro de `AnimatedGradientBackground` para corresponder à paleta roxo/azul/rosa dos sites da Psiqueia.

### **Fase 5: Integrar `MatchedGeometryEffectExample`**

Este exemplo é mais complexo e demonstra uma técnica de transição avançada. Ele deve ser usado para fluxos específicos onde um elemento se transforma em uma tela de detalhes.

1.  **Identifique um fluxo** onde um item da lista se expande para uma tela de detalhes (ex: item do diário para detalhes do diário, paciente da lista para perfil do paciente).
2.  **Adapte `CardView` e `DetailView`** para o seu modelo de dados e UI.
3.  **Implemente a lógica de estado** (`@State private var showDetail = false`) e o `matchedGeometryEffect` com um `@Namespace`.

    *   **Exemplo:** Se você tem uma lista de entradas de diário, cada entrada pode ser uma `CardView` que, ao ser tocada, se transforma em uma `DetailView`.

### **Fase 6: Refinamento e Testes**

1.  **Ajuste Fino:** Altere os valores de `padding`, `cornerRadius`, `shadow` e `animation` para que se encaixem perfeitamente na estética geral do aplicativo.
2.  **Modo Escuro:** Verifique como os novos componentes se comportam no modo claro e escuro. Use `Color.primary`, `Color.secondary` e `Color.accentColor` para garantir a adaptação automática.
3.  **Testes:** Compile e execute o aplicativo em diferentes simuladores e dispositivos para garantir que as novas implementações funcionem conforme o esperado e não introduzam regressões.

## 🚀 **Próximos Passos (Opcional - Modularização)**

Para manter o projeto organizado e facilitar a reutilização, considere mover esses novos componentes e modificadores para o módulo `ManusPsiqueiaUI` que já foi criado. Isso envolveria:

1.  **Mover os arquivos** `.swift` para o diretório `Modules/ManusPsiqueiaUI/Sources/ManusPsiqueiaUI/`.
2.  **Atualizar o `Package.swift`** do `ManusPsiqueiaUI` para exportar esses novos componentes.
3.  **Importar `ManusPsiqueiaUI`** nas views do aplicativo principal onde os componentes são usados.

Ao seguir este guia, você estará no caminho certo para transformar o visual do ManusPsiqueia, tornando-o mais moderno, inovador e perfeitamente alinhado com a identidade visual da sua marca.
