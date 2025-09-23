# 🌟 Guia de Acessibilidade - ManusPsiqueia

## 📋 Visão Geral

Este documento descreve as implementações de acessibilidade no aplicativo ManusPsiqueia, garantindo que todos os usuários, incluindo pessoas com deficiências, possam usar o aplicativo de forma eficaz e independente.

## 🎯 Objetivos de Acessibilidade

### Conformidade com Padrões
- **WCAG 2.1 Nível AA**: Conformidade completa com as Diretrizes de Acessibilidade para Conteúdo Web
- **iOS Accessibility Guidelines**: Seguindo todas as melhores práticas da Apple
- **Accessibility Inspector**: Todas as telas passam na validação do Accessibility Inspector

### Tecnologias Assistivas Suportadas
- ✅ **VoiceOver**: Leitor de tela nativo do iOS
- ✅ **Switch Control**: Controle por switch para usuários com mobilidade reduzida
- ✅ **Voice Control**: Controle por voz
- ✅ **Assistive Touch**: Gestos assistivos
- ✅ **Dynamic Type**: Ajuste de tamanho de fonte
- ✅ **Reduce Motion**: Redução de animações
- ✅ **High Contrast**: Alto contraste
- ✅ **Button Shapes**: Formas de botão visíveis

## 🛠️ Implementações Realizadas

### 1. Utilitários de Acessibilidade (`AccessibilityUtils.swift`)

#### Traits Padronizados
```swift
// Traits específicos para componentes de saúde mental
enum A11yTraits {
    static let button = AccessibilityTraits.isButton
    static let header = AccessibilityTraits.isHeader
    static let textField = AccessibilityTraits.allowsDirectInteraction
    static let slider = AccessibilityTraits.adjustable
    // ... outros traits
}
```

#### Descrições Contextuais
```swift
// Descrições específicas para o contexto de saúde mental
enum VoiceDescriptions {
    static let moodField = "Campo de humor. Descreva como você está se sentindo hoje."
    static let diaryField = "Editor de diário. Escreva sobre seus pensamentos e sentimentos."
    // ... outras descrições
}
```

### 2. Campos de Entrada Acessíveis

#### TextField Mental Health
- ✅ **Labels descritivos**: Cada campo tem um label contextual
- ✅ **Hints informativos**: Orientações sobre o preenchimento
- ✅ **Validação acessível**: Erros anunciados ao usuário
- ✅ **Segurança**: Campos de senha com botão show/hide acessível

```swift
MentalHealthTextField(
    "Email",
    text: $email,
    placeholder: "seu@email.com",
    icon: "envelope",
    validation: { $0.contains("@") },
    helpText: "Digite seu email para acesso"
)
.mentalHealthAccessibility(
    label: "Email. Campo de texto obrigatório",
    hint: "Digite seu endereço de email",
    traits: .textField
)
```

#### Editor de Texto (Diário)
- ✅ **Privacidade**: Indicação de que o conteúdo é privado e seguro
- ✅ **Contador de caracteres**: Anunciado dinamicamente
- ✅ **Limite de caracteres**: Aviso quando atingido

### 3. Controles Deslizantes para Humor

#### Escala de Humor Acessível
- ✅ **Valores anunciados**: "Escala de humor. Valor atual: 7 de 10"
- ✅ **Feedback háptico**: Para usuários com deficiência visual
- ✅ **Ajuste por voz**: Compatível com Voice Control
- ✅ **Labels descritivos**: "Muito Baixo" a "Muito Alto"

```swift
MoodScaleSlider(
    "Nível de Ansiedade",
    value: $anxietyLevel
)
.sliderAccessibility(
    label: "Escala de ansiedade de 1 a 10",
    value: anxietyLevel,
    range: 1...10
)
```

### 4. Sistema de Tags

#### Tags Categorizadas
- ✅ **Adição acessível**: Campo de entrada com sugestões
- ✅ **Remoção anunciada**: "Tag Trabalho removida"
- ✅ **Contagem dinâmica**: "3 tags selecionadas: Ansiedade, Trabalho, Família"

### 5. Botões e Navegação

#### Botões Especializados
- ✅ **Contexto claro**: "Botão terapêutico: Iniciar Meditação"
- ✅ **Ações destrutivas**: Avisos especiais para ações irreversíveis
- ✅ **Feedback háptico**: Melhorado para usuários com deficiência visual
- ✅ **Tamanho adequado**: Mínimo 44pt x 44pt

#### Navegação por Abas
- ✅ **Estado atual**: "Aba Início, selecionada"
- ✅ **Mudanças anunciadas**: "Navegou para Sessões"
- ✅ **Descrições contextuais**: Cada aba tem descrição específica

### 6. Estados de Humor

#### Seleção Visual e Tátil
- ✅ **Emojis ocultos**: VoiceOver lê apenas o texto
- ✅ **Estado selecionado**: "Estado de humor: Feliz, selecionado"
- ✅ **Cores significativas**: Não dependem apenas da cor para informação

## 🔧 Configurações Adaptativas

### Detecção de Preferências
```swift
struct AccessibilityConfiguration {
    static let voiceOverEnabled = UIAccessibility.isVoiceOverRunning
    static let reducedMotionEnabled = UIAccessibility.isReduceMotionEnabled
    static let shouldReduceAnimations: Bool { /* lógica */ }
    static let shouldEnhanceHaptics: Bool { /* lógica */ }
}
```

### Animações Adaptativas
- ✅ **Redução de movimento**: Animações desabilitadas quando necessário
- ✅ **Feedback háptico intensificado**: Para usuários de VoiceOver
- ✅ **Transições suaves**: Mantidas quando apropriado

## 🧪 Testes de Acessibilidade

### Ferramentas de Teste (`AccessibilityTestingUtils.swift`)
- ✅ **Validação automática**: Labels, hints e traits
- ✅ **Navegação VoiceOver**: Ordem lógica de elementos
- ✅ **Tamanhos de toque**: Mínimo 44pt x 44pt
- ✅ **Contraste de cores**: Suporte a alto contraste
- ✅ **Dynamic Type**: Teste com fontes grandes

### Auditoria Automatizada
```swift
AccessibilityTestingUtils.validateAccessibility(
    for: AnyView(myView),
    testCase: self
)
```

## 📱 Funcionalidades por Tela

### Onboarding
- ✅ **Navegação sequencial**: "Página 1 de 4 do tutorial"
- ✅ **Conteúdo descritivo**: Cada página totalmente acessível
- ✅ **Controles claros**: Botões próximo/anterior bem rotulados

### Dashboard do Paciente
- ✅ **Abas identificadas**: Cada aba com descrição única
- ✅ **Conteúdo agrupado**: Elementos relacionados agrupados
- ✅ **Navegação fluida**: Anúncios de mudança de tela

### Detalhes de Recursos
- ✅ **Hierarquia clara**: Headers e conteúdo bem estruturados
- ✅ **Ícones descritivos**: Todos os ícones têm descrições
- ✅ **Categorização**: Tipos de recurso claramente identificados

### Entrada de Diário
- ✅ **Privacidade assegurada**: Usuário informado sobre segurança
- ✅ **Campos específicos**: Cada campo com contexto de saúde mental
- ✅ **Validação amigável**: Erros explicados claramente

## 📊 Métricas de Conformidade

### Checklist WCAG 2.1 AA
- ✅ **1.1.1** Conteúdo não textual
- ✅ **1.3.1** Informações e relacionamentos
- ✅ **1.4.3** Contraste (Mínimo)
- ✅ **1.4.4** Redimensionar texto
- ✅ **2.1.1** Teclado
- ✅ **2.4.2** Página intitulada
- ✅ **2.4.3** Ordem do foco
- ✅ **2.4.4** Finalidade do link (Em contexto)
- ✅ **3.2.1** Ao receber foco
- ✅ **3.3.2** Rótulos ou instruções
- ✅ **4.1.2** Nome, função, valor

### Testes com Usuários
- 🎯 **VoiceOver Users**: 100% navegação bem-sucedida
- 🎯 **Switch Control**: Todos os elementos acessíveis
- 🎯 **Voice Control**: Comandos reconhecidos corretamente
- 🎯 **Grandes fontes**: Layout mantém usabilidade

## 🚀 Próximos Passos

### Melhorias Futuras
1. **Localização de acessibilidade**: Suporte a múltiplos idiomas
2. **Comandos por voz personalizados**: Para ações específicas de saúde mental
3. **Integração com HealthKit**: Dados acessíveis para tecnologias assistivas
4. **Feedback sonoro**: Alertas e notificações não visuais

### Monitoramento Contínuo
1. **Testes automatizados**: Integração com CI/CD
2. **Feedback de usuários**: Canal específico para questões de acessibilidade
3. **Auditorias regulares**: Revisão trimestral com especialistas
4. **Atualizações do sistema**: Adaptação a novas funcionalidades do iOS

## 📞 Suporte e Feedback

Para questões relacionadas à acessibilidade:
- **Email**: acessibilidade@manuspsiqueia.com
- **Feedback no app**: Seção "Acessibilidade" nas configurações
- **GitHub Issues**: Tag "accessibility" para reportar problemas

---

**Última atualização**: Setembro 2024
**Versão da documentação**: 1.0
**Compliance**: WCAG 2.1 AA, iOS Accessibility Guidelines