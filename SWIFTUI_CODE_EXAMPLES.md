# 💻 Exemplos de Código SwiftUI para Dicas de Design Avançado

**Status:** ✅ **EXEMPLOS DE CÓDIGO GERADOS**

Aqui estão exemplos de código SwiftUI para as três principais dicas de design avançado, que podem ser diretamente aplicados ao projeto ManusPsiqueia para modernizar e inovar seu visual, alinhando-o com as melhores práticas da Apple e a estética dos sites existentes.

## 🚀 **1. Fundos Dinâmicos e Materiais Adaptativos (Liquid Glass)**

Esta dica foca em criar fundos e componentes com efeitos translúcidos e gradientes animados, replicando a sensação de profundidade e modernidade.

### **Exemplo 1.1: Card com Material Translúcido**

Este código demonstra como usar `ultraThinMaterial` para criar um card com um fundo translúcido, permitindo que o conteúdo de trás seja sutilmente visível.

```swift
import SwiftUI

struct MaterialCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bem-vindo ao Psiqueia")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text("Sua jornada de autoconhecimento começa aqui.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                // Ação do botão
            }) {
                Text("Explorar Recursos")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Capsule().fill(Color.accentColor))
            }
        }
        .padding(20)
        .background(.ultraThinMaterial) // Aplica o efeito de material translúcido
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
}

struct MaterialCardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Fundo para mostrar o efeito de translucidez
            LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            MaterialCardView()
        }
    }
}
```

### **Exemplo 1.2: Fundo com Gradiente Animado e Interativo**

Este exemplo cria um fundo com um gradiente que muda sutilmente ao longo do tempo, simulando um efeito dinâmico como as "bolhas" ou "partículas" dos sites.

```swift
import SwiftUI

struct AnimatedGradientBackground: View {
    var body: some View {
        ZStack {
            TimelineView(.animation(minimumInterval: 0.1, paused: false)) {
                let time = $0.date.timeIntervalSinceReferenceDate
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.6 + sin(time * 0.5) * 0.2),
                        Color.blue.opacity(0.6 + cos(time * 0.3) * 0.2)
                    ]),
                    startPoint: UnitPoint(x: 0.5 + sin(time * 0.1) * 0.5, y: 0.5 + cos(time * 0.1) * 0.5),
                    endPoint: UnitPoint(x: 0.5 - sin(time * 0.1) * 0.5, y: 0.5 - cos(time * 0.1) * 0.5)
                )
                .ignoresSafeArea()
            }
            // Conteúdo do app ficaria aqui, sobre o gradiente animado
            Text("Seu App Psiqueia")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundColor(.white)
        }
    }
}

struct AnimatedGradientBackground_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedGradientBackground()
    }
}
```

## ⚡ **2. Microinterações e Animações Fluidas**

O SwiftUI é excelente para criar transições suaves e feedback visual. O `matchedGeometryEffect` é uma ferramenta poderosa para isso.

### **Exemplo 2.1: Transição Suave com `matchedGeometryEffect`**

Este código demonstra como um card pode se expandir suavemente para se tornar uma tela de detalhes, usando `matchedGeometryEffect` para uma transição fluida.

```swift
import SwiftUI

struct MatchedGeometryEffectExample: View {
    @Namespace private var namespace
    @State private var showDetail = false

    var body: some View {
        VStack {
            if !showDetail {
                CardView(namespace: namespace, showDetail: $showDetail)
            } else {
                DetailView(namespace: namespace, showDetail: $showDetail)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1).ignoresSafeArea())
    }
}

struct CardView: View {
    var namespace: Namespace.ID
    @Binding var showDetail: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text("Entrada do Diário")
                .font(.headline)
                .matchedGeometryEffect(id: "title", in: namespace)
            Text("Hoje me senti muito bem e produtivo.")
                .font(.subheadline)
                .matchedGeometryEffect(id: "content", in: namespace)
        }
        .padding()
        .frame(width: 300, height: 150, alignment: .leading)
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        .onTapGesture {
            withAnimation(.spring()) {
                showDetail.toggle()
            }
        }
    }
}

struct DetailView: View {
    var namespace: Namespace.ID
    @Binding var showDetail: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text("Entrada do Diário")
                .font(.largeTitle)
                .fontWeight(.bold)
                .matchedGeometryEffect(id: "title", in: namespace)
            Text("Hoje me senti muito bem e produtivo. Consegui finalizar todas as minhas tarefas e ainda tive tempo para meditar. Agradeço por este dia.")
                .font(.body)
                .matchedGeometryEffect(id: "content", in: namespace)
            Spacer()
            Button("Fechar") {
                withAnimation(.spring()) {
                    showDetail.toggle()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.9))
        .foregroundColor(.white)
        .ignoresSafeArea()
    }
}

struct MatchedGeometryEffectExample_Previews: PreviewProvider {
    static var previews: some View {
        MatchedGeometryEffectExample()
    }
}
```

## 🧩 **3. Componentes Modulares e Reutilizáveis com `ViewModifier`**

Criar `ViewModifier`s é uma prática excelente para garantir consistência visual e acelerar o desenvolvimento, centralizando estilos comuns.

### **Exemplo 3.1: `ViewModifier` para Estilo de Botão Primário**

Este `ViewModifier` define um estilo de botão primário que pode ser reutilizado em todo o aplicativo, garantindo que todos os botões primários tenham a mesma aparência.

```swift
import SwiftUI

struct PrimaryButtonStyleModifier: ViewModifier {
    var backgroundColor: Color = .accentColor
    var foregroundColor: Color = .white
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(foregroundColor)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(backgroundColor))
            .cornerRadius(cornerRadius) // Note: cornerRadius on background, not content directly
            .shadow(color: backgroundColor.opacity(0.3), radius: 5, x: 0, y: 5)
    }
}

extension View {
    func primaryButtonStyle(backgroundColor: Color = .accentColor, foregroundColor: Color = .white, cornerRadius: CGFloat = 12) -> some View {
        modifier(PrimaryButtonStyleModifier(backgroundColor: backgroundColor, foregroundColor: foregroundColor, cornerRadius: cornerRadius))
    }
}

struct PrimaryButtonExample: View {
    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                print("Botão primário clicado!")
            }) {
                Text("Entrar no Psiqueia")
            }
            .primaryButtonStyle()

            Button(action: {
                print("Botão secundário clicado!")
            }) {
                Text("Criar Nova Conta")
            }
            .primaryButtonStyle(backgroundColor: .gray, cornerRadius: 8)
        }
        .padding()
    }
}

struct PrimaryButtonExample_Previews: PreviewProvider {
    static var previews: some View {
        PrimaryButtonExample()
    }
}
```

## 🎯 **Conclusão**

Estes exemplos fornecem uma base sólida para implementar as dicas de design avançado no ManusPsiqueia. Ao utilizar `Material` para translucidez, `TimelineView` para gradientes animados, `matchedGeometryEffect` para transições fluidas e `ViewModifier`s para componentes reutilizáveis, o aplicativo pode alcançar um visual moderno, inovador e perfeitamente alinhado com a identidade visual da marca Psiqueia. A combinação dessas técnicas resultará em uma experiência de usuário superior e visualmente cativante. 
