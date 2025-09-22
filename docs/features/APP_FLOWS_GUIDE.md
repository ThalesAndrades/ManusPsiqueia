# Guia de Fluxos do App ManusPsiqueia

**Data:** 22 de setembro de 2025  
**Autor:** Manus AI  
**Versão:** 1.0  
**Empresa:** AiLun Tecnologia (CNPJ: 60.740.536/0001-75)

## 1. Visão Geral

Este documento mapeia todos os fluxos de usuário dentro do app ManusPsiqueia, desde o primeiro acesso até funcionalidades avançadas. Cada fluxo inclui wireframes conceituais, estados da interface e pontos de decisão críticos.

## 2. Arquitetura de Navegação

### 2.1. Estrutura Principal

```
ManusPsiqueia App
├── 🔐 Autenticação
│   ├── Onboarding
│   ├── Login/Cadastro
│   └── Recuperação de Senha
├── 🏠 Tab Bar Principal
│   ├── 📖 Diário (Home)
│   ├── 📊 Insights
│   ├── 🎯 Metas
│   ├── 👤 Perfil
│   └── ⚙️ Configurações
├── 💰 Paywall/Assinatura
├── 🔔 Notificações
└── 🆘 Suporte/Ajuda
```

## 3. Fluxo de Primeira Experiência (FTUE)

### 3.1. Splash Screen e Onboarding

**Objetivo:** Apresentar o app e seus benefícios, coletando permissões essenciais.

```
[Splash Screen] → [Onboarding 1] → [Onboarding 2] → [Onboarding 3] → [Permissões] → [Cadastro]
```

#### Tela 1: Splash Screen
- **Duração:** 2-3 segundos
- **Elementos:** Logo ManusPsiqueia, loading indicator
- **Ações:** Carregamento automático

#### Tela 2: Onboarding - Bem-vindo
```swift
struct OnboardingWelcomeView: View {
    var body: some View {
        VStack(spacing: 30) {
            // Ilustração: Pessoa escrevendo em diário digital
            Image("onboarding_welcome")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 300)
            
            VStack(spacing: 16) {
                Text("Bem-vindo ao ManusPsiqueia")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Seu diário pessoal com inteligência artificial para autoconhecimento e bem-estar mental")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button("Começar") {
                // Navegar para próxima tela
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
    }
}
```

#### Tela 3: Onboarding - Funcionalidades
- **Título:** "Como funciona?"
- **Elementos:** 
  - 📝 "Escreva seus pensamentos"
  - 🤖 "IA analisa seus sentimentos"
  - 📈 "Acompanhe seu progresso"
- **CTA:** "Continuar"

#### Tela 4: Onboarding - Privacidade
- **Título:** "Sua privacidade é sagrada"
- **Elementos:**
  - 🔒 "Dados criptografados"
  - 🚫 "Nunca compartilhamos"
  - ✅ "Você tem controle total"
- **CTA:** "Entendi"

#### Tela 5: Permissões
```swift
struct PermissionsView: View {
    @State private var notificationsGranted = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Permissões")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 20) {
                PermissionRow(
                    icon: "bell.fill",
                    title: "Notificações",
                    description: "Lembretes gentis para escrever no diário",
                    isRequired: false,
                    isGranted: $notificationsGranted
                )
                
                PermissionRow(
                    icon: "icloud.fill",
                    title: "iCloud",
                    description: "Sincronizar entre seus dispositivos",
                    isRequired: true,
                    isGranted: .constant(true)
                )
            }
            
            Spacer()
            
            Button("Continuar") {
                // Navegar para cadastro
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
    }
}
```

### 3.2. Fluxo de Cadastro/Login

**Estados possíveis:**
- Novo usuário (Cadastro)
- Usuário existente (Login)
- Login social (Apple, Google)
- Recuperação de senha

#### Tela de Cadastro
```swift
struct SignUpView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Criar conta")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                CustomTextField(
                    title: "Nome completo",
                    text: $name,
                    icon: "person.fill"
                )
                
                CustomTextField(
                    title: "Email",
                    text: $email,
                    icon: "envelope.fill",
                    keyboardType: .emailAddress
                )
                
                CustomTextField(
                    title: "Senha",
                    text: $password,
                    icon: "lock.fill",
                    isSecure: true
                )
            }
            
            Button("Criar conta") {
                createAccount()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading)
            
            Divider()
            
            VStack(spacing: 12) {
                SignInWithAppleButton(.signUp) { request in
                    // Configurar request
                } onCompletion: { result in
                    // Processar resultado
                }
                .frame(height: 50)
                
                Button("Entrar com Google") {
                    signInWithGoogle()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            HStack {
                Text("Já tem conta?")
                Button("Fazer login") {
                    // Navegar para login
                }
                .foregroundColor(.accentColor)
            }
        }
        .padding()
    }
    
    private func createAccount() {
        // Implementar cadastro
    }
}
```

## 4. Fluxo Principal - Tab Bar Navigation

### 4.1. Tab 1: Diário (Home)

**Objetivo:** Tela principal onde usuários criam e visualizam entradas do diário.

#### Estados da Tela:
1. **Estado Vazio:** Primeira vez, sem entradas
2. **Estado com Conteúdo:** Lista de entradas existentes
3. **Estado de Carregamento:** Sincronizando dados

```swift
struct DiaryHomeView: View {
    @StateObject private var viewModel = DiaryViewModel()
    @State private var showingNewEntry = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.entries.isEmpty {
                    EmptyDiaryView {
                        showingNewEntry = true
                    }
                } else {
                    DiaryEntriesList(entries: viewModel.entries)
                }
            }
            .navigationTitle("Meu Diário")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewEntry = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                NewDiaryEntryView()
            }
        }
        .onAppear {
            viewModel.loadEntries()
        }
    }
}

struct EmptyDiaryView: View {
    let onCreateFirst: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image("empty_diary")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
            
            VStack(spacing: 12) {
                Text("Seu diário está vazio")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Comece escrevendo sobre seu dia, seus sentimentos ou qualquer coisa que esteja em sua mente")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Escrever primeira entrada") {
                onCreateFirst()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
    }
}
```

#### Fluxo de Criação de Entrada

```
[Diário Home] → [Nova Entrada] → [Escrita] → [Análise IA] → [Salvar] → [Visualizar Resultado]
```

```swift
struct NewDiaryEntryView: View {
    @State private var title = ""
    @State private var content = ""
    @State private var mood: MoodLevel = .neutral
    @State private var isAnalyzing = false
    @State private var aiInsight: AIInsight?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Campo de título
                TextField("Título (opcional)", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Seletor de humor
                MoodSelector(selectedMood: $mood)
                
                // Campo de conteúdo principal
                TextEditor(text: $content)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        Text("Como foi seu dia? O que você está sentindo?")
                            .foregroundColor(.gray)
                            .opacity(content.isEmpty ? 1 : 0)
                            .allowsHitTesting(false),
                        alignment: .topLeading
                    )
                
                // Contador de palavras
                HStack {
                    Spacer()
                    Text("\(content.split(separator: " ").count) palavras")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Botão de análise IA (Premium)
                if !content.isEmpty {
                    Button("Analisar com IA ✨") {
                        analyzeWithAI()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(isAnalyzing)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Nova Entrada")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salvar") {
                        saveEntry()
                    }
                    .disabled(content.isEmpty)
                }
            }
        }
    }
    
    private func analyzeWithAI() {
        // Verificar se é usuário premium
        // Chamar API da OpenAI
        // Mostrar insights
    }
    
    private func saveEntry() {
        // Salvar no Supabase
        // Atualizar lista
        dismiss()
    }
}

struct MoodSelector: View {
    @Binding var selectedMood: MoodLevel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Como você está se sentindo?")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(MoodLevel.allCases, id: \.self) { mood in
                    Button(action: { selectedMood = mood }) {
                        VStack(spacing: 4) {
                            Text(mood.emoji)
                                .font(.title)
                            Text(mood.description)
                                .font(.caption)
                        }
                        .padding(8)
                        .background(
                            selectedMood == mood ? 
                            Color.accentColor.opacity(0.2) : 
                            Color.clear
                        )
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

enum MoodLevel: CaseIterable {
    case veryBad, bad, neutral, good, veryGood
    
    var emoji: String {
        switch self {
        case .veryBad: return "😢"
        case .bad: return "😕"
        case .neutral: return "😐"
        case .good: return "😊"
        case .veryGood: return "😄"
        }
    }
    
    var description: String {
        switch self {
        case .veryBad: return "Muito mal"
        case .bad: return "Mal"
        case .neutral: return "Neutro"
        case .good: return "Bem"
        case .veryGood: return "Muito bem"
        }
    }
    
    var score: Int {
        switch self {
        case .veryBad: return 1
        case .bad: return 3
        case .neutral: return 5
        case .good: return 7
        case .veryGood: return 10
        }
    }
}
```

### 4.2. Tab 2: Insights

**Objetivo:** Mostrar análises e padrões baseados nas entradas do diário.

```swift
struct InsightsView: View {
    @StateObject private var viewModel = InsightsViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Resumo semanal
                    WeeklySummaryCard(summary: viewModel.weeklySummary)
                    
                    // Gráfico de humor
                    MoodChartCard(moodData: viewModel.moodData)
                    
                    // Insights da IA
                    if viewModel.isPremium {
                        AIInsightsCard(insights: viewModel.aiInsights)
                    } else {
                        PremiumUpsellCard()
                    }
                    
                    // Padrões identificados
                    PatternsCard(patterns: viewModel.patterns)
                    
                    // Palavras mais usadas
                    WordCloudCard(words: viewModel.frequentWords)
                }
                .padding()
            }
            .navigationTitle("Insights")
            .refreshable {
                await viewModel.refresh()
            }
        }
        .onAppear {
            viewModel.loadInsights()
        }
    }
}

struct WeeklySummaryCard: View {
    let summary: WeeklySummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Resumo da Semana")
                    .font(.headline)
                Spacer()
                Text(summary.dateRange)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                StatItem(
                    title: "Entradas",
                    value: "\(summary.entriesCount)",
                    icon: "doc.text"
                )
                
                StatItem(
                    title: "Humor Médio",
                    value: summary.averageMood.emoji,
                    icon: "heart"
                )
                
                StatItem(
                    title: "Palavras",
                    value: "\(summary.totalWords)",
                    icon: "textformat"
                )
            }
            
            if let insight = summary.weeklyInsight {
                Text(insight)
                    .font(.body)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct MoodChartCard: View {
    let moodData: [MoodDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Evolução do Humor")
                .font(.headline)
            
            // Gráfico de linha simples
            MoodLineChart(data: moodData)
                .frame(height: 200)
            
            HStack {
                Text("Últimos 30 dias")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Ver detalhes") {
                    // Navegar para tela detalhada
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
```

### 4.3. Tab 3: Metas

**Objetivo:** Definir e acompanhar metas de bem-estar.

```swift
struct GoalsView: View {
    @StateObject private var viewModel = GoalsViewModel()
    @State private var showingNewGoal = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.goals.isEmpty {
                    EmptyGoalsView {
                        showingNewGoal = true
                    }
                } else {
                    GoalsList(goals: viewModel.goals)
                }
            }
            .navigationTitle("Metas")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewGoal = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewGoal) {
                NewGoalView()
            }
        }
    }
}

struct GoalCard: View {
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(goal.title)
                    .font(.headline)
                Spacer()
                Text(goal.category.emoji)
                    .font(.title2)
            }
            
            Text(goal.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            // Barra de progresso
            ProgressView(value: goal.progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
            
            HStack {
                Text("\(Int(goal.progress * 100))% concluído")
                    .font(.caption)
                Spacer()
                Text(goal.deadline.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Botões de ação
            HStack(spacing: 12) {
                Button("Registrar progresso") {
                    // Ação
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
```

### 4.4. Tab 4: Perfil

**Objetivo:** Configurações do usuário, assinatura e dados pessoais.

```swift
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationView {
            List {
                // Seção do usuário
                Section {
                    HStack(spacing: 16) {
                        AsyncImage(url: viewModel.user.avatarURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.gray)
                                )
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.user.fullName)
                                .font(.headline)
                            Text(viewModel.user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if viewModel.user.isPremium {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                    Text("Premium")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Seção de assinatura
                if !viewModel.user.isPremium {
                    Section {
                        Button("Upgrade para Premium ✨") {
                            // Mostrar paywall
                        }
                        .foregroundColor(.accentColor)
                    }
                }
                
                // Seção de estatísticas
                Section("Estatísticas") {
                    StatRow(title: "Entradas no diário", value: "\(viewModel.stats.totalEntries)")
                    StatRow(title: "Dias consecutivos", value: "\(viewModel.stats.streakDays)")
                    StatRow(title: "Palavras escritas", value: "\(viewModel.stats.totalWords)")
                    StatRow(title: "Membro desde", value: viewModel.user.memberSince.formatted(date: .abbreviated, time: .omitted))
                }
                
                // Seção de configurações
                Section("Configurações") {
                    NavigationLink("Notificações", destination: NotificationSettingsView())
                    NavigationLink("Privacidade", destination: PrivacySettingsView())
                    NavigationLink("Backup e Sincronização", destination: BackupSettingsView())
                    NavigationLink("Exportar Dados", destination: ExportDataView())
                }
                
                // Seção de suporte
                Section("Suporte") {
                    NavigationLink("Central de Ajuda", destination: HelpCenterView())
                    NavigationLink("Contato", destination: ContactView())
                    NavigationLink("Avaliar App", destination: EmptyView()) // Abrir App Store
                }
                
                // Seção de conta
                Section {
                    Button("Sair da Conta") {
                        viewModel.signOut()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Perfil")
        }
    }
}
```

## 5. Fluxos Especiais

### 5.1. Fluxo de Paywall/Assinatura

**Trigger Points:**
- Tentar usar funcionalidade premium
- Após 5 entradas gratuitas
- Botão "Upgrade" no perfil

```swift
struct PaywallView: View {
    @State private var selectedPlan: SubscriptionPlan = .monthly
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.yellow)
                
                Text("Desbloqueie todo o potencial")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Análises avançadas com IA, insights personalizados e muito mais")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Features
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "infinity", title: "Entradas ilimitadas", description: "Escreva quantas vezes quiser")
                FeatureRow(icon: "brain.head.profile", title: "Análises com IA", description: "Insights profundos sobre seus padrões")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Relatórios avançados", description: "Gráficos e estatísticas detalhadas")
                FeatureRow(icon: "icloud.and.arrow.up", title: "Backup automático", description: "Seus dados sempre seguros")
                FeatureRow(icon: "envelope", title: "Relatórios por email", description: "Resumos semanais personalizados")
            }
            
            // Plans
            VStack(spacing: 12) {
                PlanCard(
                    plan: .annual,
                    isSelected: selectedPlan == .annual,
                    onSelect: { selectedPlan = .annual }
                )
                
                PlanCard(
                    plan: .monthly,
                    isSelected: selectedPlan == .monthly,
                    onSelect: { selectedPlan = .monthly }
                )
            }
            
            // CTA
            Button("Começar teste grátis de 7 dias") {
                startTrial()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading)
            
            Text("Cancele a qualquer momento")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Close button
            Button("Talvez depois") {
                dismiss()
            }
            .font(.body)
            .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private func startTrial() {
        // Implementar compra via Stripe
    }
}

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.title)
                            .font(.headline)
                        
                        if plan == .annual {
                            Text("ECONOMIZE 17%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(plan.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(plan.price)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if plan == .annual {
                        Text("R$ 24,99/mês")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                isSelected ? 
                Color.accentColor.opacity(0.1) : 
                Color(.systemBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.accentColor : Color.gray.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum SubscriptionPlan {
    case monthly, annual
    
    var title: String {
        switch self {
        case .monthly: return "Mensal"
        case .annual: return "Anual"
        }
    }
    
    var subtitle: String {
        switch self {
        case .monthly: return "Renovação mensal"
        case .annual: return "Renovação anual"
        }
    }
    
    var price: String {
        switch self {
        case .monthly: return "R$ 29,90"
        case .annual: return "R$ 299,90"
        }
    }
}
```

### 5.2. Fluxo de Análise com IA

**Trigger:** Usuário premium clica em "Analisar com IA" em uma entrada.

```swift
struct AIAnalysisView: View {
    let diaryEntry: DiaryEntry
    @State private var analysis: AIAnalysis?
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                AIAnalysisLoadingView()
            } else if let analysis = analysis {
                AIAnalysisResultView(analysis: analysis)
            } else if error != nil {
                AIAnalysisErrorView {
                    loadAnalysis()
                }
            }
        }
        .navigationTitle("Análise com IA")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadAnalysis()
        }
    }
    
    private func loadAnalysis() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let result = try await APIService.shared.generateDiaryInsight(text: diaryEntry.content)
                await MainActor.run {
                    self.analysis = result
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
}

struct AIAnalysisLoadingView: View {
    @State private var animationPhase = 0
    
    var body: some View {
        VStack(spacing: 24) {
            // Animação de "pensando"
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 12, height: 12)
                        .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animationPhase
                        )
                }
            }
            
            VStack(spacing: 8) {
                Text("Analisando sua entrada...")
                    .font(.headline)
                
                Text("Nossa IA está processando seus pensamentos e identificando padrões emocionais")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

struct AIAnalysisResultView: View {
    let analysis: AIAnalysis
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Sentiment Score
                SentimentCard(sentiment: analysis.sentiment)
                
                // Key Insights
                InsightsCard(insights: analysis.insights)
                
                // Emotional Patterns
                if !analysis.patterns.isEmpty {
                    PatternsCard(patterns: analysis.patterns)
                }
                
                // Suggestions
                if !analysis.suggestions.isEmpty {
                    SuggestionsCard(suggestions: analysis.suggestions)
                }
                
                // Disclaimer
                DisclaimerCard()
            }
            .padding()
        }
    }
}

struct SentimentCard: View {
    let sentiment: Sentiment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Análise de Sentimento")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(sentiment.label)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Confiança: \(Int(sentiment.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(sentiment.emoji)
                    .font(.system(size: 50))
            }
            
            ProgressView(value: sentiment.positivity, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: sentiment.color))
            
            HStack {
                Text("Negativo")
                    .font(.caption)
                Spacer()
                Text("Positivo")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
```

## 6. Estados de Erro e Edge Cases

### 6.1. Estados de Conectividade

```swift
struct ConnectivityBanner: View {
    let isConnected: Bool
    
    var body: some View {
        if !isConnected {
            HStack {
                Image(systemName: "wifi.slash")
                Text("Sem conexão - trabalhando offline")
                Spacer()
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .foregroundColor(.orange)
        }
    }
}
```

### 6.2. Estados de Carregamento

```swift
struct LoadingStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
```

### 6.3. Estados de Erro

```swift
struct ErrorStateView: View {
    let error: AppError
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: error.icon)
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Text(error.title)
                    .font(.headline)
                
                Text(error.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Tentar novamente") {
                onRetry()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
    }
}

enum AppError: Error {
    case networkError
    case authenticationError
    case subscriptionError
    case aiServiceError
    
    var icon: String {
        switch self {
        case .networkError: return "wifi.slash"
        case .authenticationError: return "person.crop.circle.badge.xmark"
        case .subscriptionError: return "creditcard.trianglebadge.exclamationmark"
        case .aiServiceError: return "brain.head.profile"
        }
    }
    
    var title: String {
        switch self {
        case .networkError: return "Sem conexão"
        case .authenticationError: return "Erro de autenticação"
        case .subscriptionError: return "Problema com assinatura"
        case .aiServiceError: return "Serviço de IA indisponível"
        }
    }
    
    var message: String {
        switch self {
        case .networkError: return "Verifique sua conexão com a internet e tente novamente."
        case .authenticationError: return "Faça login novamente para continuar."
        case .subscriptionError: return "Houve um problema com sua assinatura. Entre em contato conosco."
        case .aiServiceError: return "O serviço de análise está temporariamente indisponível."
        }
    }
}
```

## 7. Navegação e Deep Links

### 7.1. URL Scheme

```
manuspsiqueia://
├── diary/new                    # Nova entrada
├── diary/entry/{id}             # Entrada específica
├── insights                     # Tela de insights
├── goals                        # Tela de metas
├── goals/new                    # Nova meta
├── profile                      # Perfil do usuário
├── subscription                 # Tela de assinatura
└── settings/{section}           # Configurações específicas
```

### 7.2. Implementação de Deep Links

```swift
struct ContentView: View {
    @StateObject private var navigationManager = NavigationManager()
    
    var body: some View {
        TabView(selection: $navigationManager.selectedTab) {
            DiaryHomeView()
                .tabItem {
                    Image(systemName: "book")
                    Text("Diário")
                }
                .tag(Tab.diary)
            
            InsightsView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Insights")
                }
                .tag(Tab.insights)
            
            GoalsView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Metas")
                }
                .tag(Tab.goals)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Perfil")
                }
                .tag(Tab.profile)
        }
        .onOpenURL { url in
            navigationManager.handle(url: url)
        }
    }
}

class NavigationManager: ObservableObject {
    @Published var selectedTab: Tab = .diary
    
    func handle(url: URL) {
        guard url.scheme == "manuspsiqueia" else { return }
        
        let path = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        switch path {
        case "diary":
            selectedTab = .diary
            if pathComponents.first == "new" {
                // Mostrar tela de nova entrada
            }
        case "insights":
            selectedTab = .insights
        case "goals":
            selectedTab = .goals
        case "profile":
            selectedTab = .profile
        case "subscription":
            // Mostrar paywall
            break
        default:
            break
        }
    }
}

enum Tab {
    case diary, insights, goals, profile
}
```

## 8. Conclusão

Este guia mapeia todos os fluxos principais do app ManusPsiqueia, fornecendo uma base sólida para implementação e testes. Cada fluxo foi projetado pensando na experiência do usuário, com estados claros, tratamento de erros e navegação intuitiva.

**Próximos Passos:**
1. Implementar os ViewModels para cada tela
2. Criar os componentes reutilizáveis (botões, cards, etc.)
3. Implementar a lógica de navegação e deep links
4. Adicionar animações e transições
5. Testar todos os fluxos em diferentes dispositivos

O app está arquiteturado para ser escalável, mantível e oferecer uma experiência excepcional aos usuários do ManusPsiqueia.
