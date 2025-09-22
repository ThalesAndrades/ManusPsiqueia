# Guia Completo para Finalização do Projeto ManusPsiqueia

**Data:** 22 de setembro de 2025  
**Autor:** Manus AI  
**Versão:** 1.0  
**Empresa:** AiLun Tecnologia (CNPJ: 60.740.536/0001-75)

## 1. Visão Geral

Este é o guia definitivo e completo para finalizar o projeto ManusPsiqueia. Ele abrange desde configurações técnicas básicas até estratégias de lançamento e crescimento. Seguindo este guia, você terá um produto completo, funcional e pronto para o mercado.

**Tempo estimado total:** 3-5 dias de trabalho focado

## 2. Fase 1: Configurações Técnicas Fundamentais

### 2.1. Configuração de Serviços Externos (Prioridade: CRÍTICA)

#### A. Supabase - Backend como Serviço

**Objetivo:** Configurar o banco de dados e autenticação.

**Passos Detalhados:**

1. **Criar Conta e Projetos:**
   - Acesse [supabase.com](https://supabase.com) e crie uma conta
   - Crie 3 projetos:
     - `manus-psiqueia-dev` (Desenvolvimento)
     - `manus-psiqueia-staging` (Testes/TestFlight)
     - `manus-psiqueia-prod` (Produção/App Store)

2. **Configurar Banco de Dados:**
   ```sql
   -- Tabela de usuários (estende auth.users)
   CREATE TABLE public.user_profiles (
     id UUID REFERENCES auth.users(id) PRIMARY KEY,
     full_name TEXT,
     avatar_url TEXT,
     subscription_status TEXT DEFAULT 'free',
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Tabela de entradas do diário
   CREATE TABLE public.diary_entries (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     user_id UUID REFERENCES auth.users(id) NOT NULL,
     title TEXT,
     content TEXT NOT NULL,
     mood_score INTEGER CHECK (mood_score >= 1 AND mood_score <= 10),
     ai_insights JSONB,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Tabela de assinaturas
   CREATE TABLE public.subscriptions (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     user_id UUID REFERENCES auth.users(id) NOT NULL,
     stripe_subscription_id TEXT UNIQUE,
     status TEXT NOT NULL,
     current_period_start TIMESTAMP WITH TIME ZONE,
     current_period_end TIMESTAMP WITH TIME ZONE,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Políticas de segurança (RLS)
   ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
   ALTER TABLE public.diary_entries ENABLE ROW LEVEL SECURITY;
   ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

   -- Políticas para user_profiles
   CREATE POLICY "Users can view own profile" ON public.user_profiles
     FOR SELECT USING (auth.uid() = id);
   
   CREATE POLICY "Users can update own profile" ON public.user_profiles
     FOR UPDATE USING (auth.uid() = id);

   -- Políticas para diary_entries
   CREATE POLICY "Users can view own diary entries" ON public.diary_entries
     FOR SELECT USING (auth.uid() = user_id);
   
   CREATE POLICY "Users can insert own diary entries" ON public.diary_entries
     FOR INSERT WITH CHECK (auth.uid() = user_id);
   
   CREATE POLICY "Users can update own diary entries" ON public.diary_entries
     FOR UPDATE USING (auth.uid() = user_id);

   -- Políticas para subscriptions
   CREATE POLICY "Users can view own subscriptions" ON public.subscriptions
     FOR SELECT USING (auth.uid() = user_id);
   ```

3. **Configurar Autenticação:**
   - Vá para Authentication > Settings
   - Configure provedores: Email/Password, Google, Apple
   - Configure URLs de redirecionamento para o app

4. **Obter Credenciais:**
   - Vá para Project Settings > API
   - Copie a Project URL e a anon public key para cada projeto

#### B. Stripe - Processamento de Pagamentos

**Objetivo:** Configurar sistema de assinaturas e pagamentos.

**Passos Detalhados:**

1. **Configurar Conta Stripe:**
   - Acesse [dashboard.stripe.com](https://dashboard.stripe.com)
   - Complete a verificação da conta para aceitar pagamentos reais
   - Configure webhooks para `https://api.manuspsiqueia.com/webhooks/stripe`

2. **Criar Produtos e Preços:**
   ```bash
   # Produto Premium Mensal
   stripe products create \
     --name "ManusPsiqueia Premium" \
     --description "Acesso completo às funcionalidades de IA e análises avançadas"

   # Preço Mensal (R$ 29,90)
   stripe prices create \
     --product prod_XXXXXXXXXX \
     --unit-amount 2990 \
     --currency brl \
     --recurring interval=month

   # Preço Anual (R$ 299,90 - 2 meses grátis)
   stripe prices create \
     --product prod_XXXXXXXXXX \
     --unit-amount 29990 \
     --currency brl \
     --recurring interval=year
   ```

3. **Configurar Webhooks:**
   - Endpoint: `https://api.manuspsiqueia.com/webhooks/stripe`
   - Eventos: `customer.subscription.created`, `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.payment_succeeded`, `invoice.payment_failed`

#### C. OpenAI - Inteligência Artificial

**Objetivo:** Configurar análise de sentimentos e insights do diário.

**Passos Detalhados:**

1. **Configurar Conta OpenAI:**
   - Acesse [platform.openai.com](https://platform.openai.com)
   - Configure billing e limites de uso
   - Crie chaves de API separadas para cada ambiente

2. **Configurar Prompts Otimizados:**
   ```swift
   // Exemplo de prompt para análise de diário
   let systemPrompt = """
   Você é um assistente especializado em saúde mental e bem-estar. 
   Analise o texto do diário fornecido e forneça:
   1. Uma análise empática do estado emocional
   2. Insights construtivos sobre padrões de pensamento
   3. Sugestões práticas para melhorar o bem-estar
   4. Uma classificação de humor de 1-10
   
   Seja sempre respeitoso, empático e profissional. 
   Nunca forneça diagnósticos médicos ou conselhos médicos específicos.
   """
   ```

### 2.2. Configuração do Arquivo .env

Crie o arquivo `.env` na raiz do projeto com todas as credenciais:

```env
# Development Environment
STRIPE_PUBLISHABLE_KEY_DEV=pk_test_sua_chave_dev_aqui
STRIPE_SECRET_KEY_DEV=sk_test_sua_chave_secreta_dev_aqui
SUPABASE_URL_DEV=https://seu-projeto-dev.supabase.co
SUPABASE_ANON_KEY_DEV=sua_chave_anon_dev_aqui
SUPABASE_SERVICE_KEY_DEV=sua_chave_service_dev_aqui
OPENAI_API_KEY_DEV=sk-sua_chave_openai_dev_aqui

# Staging Environment
STRIPE_PUBLISHABLE_KEY_STAGING=pk_test_sua_chave_staging_aqui
STRIPE_SECRET_KEY_STAGING=sk_test_sua_chave_secreta_staging_aqui
SUPABASE_URL_STAGING=https://seu-projeto-staging.supabase.co
SUPABASE_ANON_KEY_STAGING=sua_chave_anon_staging_aqui
SUPABASE_SERVICE_KEY_STAGING=sua_chave_service_staging_aqui
OPENAI_API_KEY_STAGING=sk-sua_chave_openai_staging_aqui

# Production Environment
STRIPE_PUBLISHABLE_KEY_PROD=pk_live_sua_chave_prod_aqui
STRIPE_SECRET_KEY_PROD=sk_live_sua_chave_secreta_prod_aqui
SUPABASE_URL_PROD=https://seu-projeto-prod.supabase.co
SUPABASE_ANON_KEY_PROD=sua_chave_anon_prod_aqui
SUPABASE_SERVICE_KEY_PROD=sua_chave_service_prod_aqui
OPENAI_API_KEY_PROD=sk-sua_chave_openai_prod_aqui

# Apple Configuration
DEVELOPMENT_TEAM_ID=SEU_TEAM_ID_AQUI
APPLE_ID=seu_apple_id@email.com
APP_SPECIFIC_PASSWORD=sua_senha_especifica_do_app

# Analytics (opcional)
FIREBASE_PROJECT_ID=manus-psiqueia
MIXPANEL_TOKEN=seu_token_mixpanel_aqui
```

### 2.3. Configuração do Xcode Cloud

1. **Configurar Workflows:**
   - Development: Build automático em cada push para `develop`
   - Staging: Build automático em cada push para `main` + deploy para TestFlight
   - Production: Build manual + deploy para App Store

2. **Adicionar Variáveis de Ambiente:**
   - Copie todas as variáveis do arquivo `.env` para o Xcode Cloud
   - Configure diferentes valores para cada workflow

3. **Configurar Scripts de CI/CD:**
   - Os scripts em `ci_scripts/` já estão prontos
   - Certifique-se de que têm permissão de execução

## 3. Fase 2: Desenvolvimento do Backend (Opcional)

### 3.1. Decisão: Backend Próprio vs. Serverless

**Opção A: Backend Próprio (Recomendado para controle total)**

Tecnologias sugeridas:
- **Node.js + Express** ou **Python + FastAPI**
- **PostgreSQL** (pode usar o mesmo do Supabase)
- **Redis** para cache
- **Docker** para containerização

**Opção B: Serverless (Recomendado para MVP rápido)**

- Use **Supabase Edge Functions** para lógica de negócio
- **Vercel Functions** ou **Netlify Functions** para webhooks
- **Stripe Webhooks** direto para o Supabase

### 3.2. Endpoints Essenciais (se escolher Backend Próprio)

```javascript
// Estrutura básica do backend
const express = require('express');
const app = express();

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Webhook do Stripe
app.post('/webhooks/stripe', (req, res) => {
  // Processar eventos do Stripe
  // Atualizar status de assinatura no Supabase
});

// Sincronização de perfil
app.post('/users/profile', (req, res) => {
  // Sincronizar dados do usuário
});

// Análise de diário com IA
app.post('/diary/analyze', async (req, res) => {
  // Chamar OpenAI API
  // Salvar insights no Supabase
});
```

## 4. Fase 3: Funcionalidades Avançadas

### 4.1. Sistema de Notificações Push

1. **Configurar Apple Push Notifications:**
   ```swift
   // Implementar no AppDelegate
   func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
           if granted {
               DispatchQueue.main.async {
                   application.registerForRemoteNotifications()
               }
           }
       }
       return true
   }
   ```

2. **Tipos de Notificações:**
   - Lembretes diários para escrever no diário
   - Insights semanais baseados nos padrões
   - Celebrações de marcos (30 dias consecutivos, etc.)

### 4.2. Analytics e Métricas

1. **Implementar Firebase Analytics:**
   ```swift
   // Eventos importantes para rastrear
   Analytics.logEvent("diary_entry_created", parameters: [
       "mood_score": moodScore,
       "word_count": wordCount
   ])
   
   Analytics.logEvent("subscription_started", parameters: [
       "plan_type": planType,
       "price": price
   ])
   ```

2. **Métricas de Negócio:**
   - DAU/MAU (Usuários Ativos Diários/Mensais)
   - Taxa de retenção (D1, D7, D30)
   - LTV (Lifetime Value)
   - Churn rate
   - Conversão freemium → premium

### 4.3. Sistema de Backup e Sincronização

1. **iCloud Sync:**
   ```swift
   // Configurar Core Data com CloudKit
   lazy var persistentContainer: NSPersistentCloudKitContainer = {
       let container = NSPersistentCloudKitContainer(name: "ManusPsiqueia")
       container.persistentStoreDescriptions.first?.setOption(true as NSNumber, 
                                                              forKey: NSPersistentHistoryTrackingKey)
       container.persistentStoreDescriptions.first?.setOption(true as NSNumber, 
                                                              forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
       return container
   }()
   ```

2. **Export de Dados:**
   - PDF com todas as entradas do diário
   - CSV para análise externa
   - Backup completo em JSON

## 5. Fase 4: Testes e Qualidade

### 5.1. Testes Automatizados Avançados

1. **Testes de Integração:**
   ```swift
   func testStripePaymentFlow() async throws {
       // Testar fluxo completo de pagamento
       let paymentIntent = try await APIService.shared.createPaymentIntent(amount: 2990)
       XCTAssertNotNil(paymentIntent.clientSecret)
   }
   
   func testDiaryAnalysisFlow() async throws {
       // Testar análise de diário com OpenAI
       let insight = try await APIService.shared.generateDiaryInsight(text: "Hoje foi um bom dia")
       XCTAssertEqual(insight.sentiment, .positive)
   }
   ```

2. **Testes de UI:**
   ```swift
   func testDiaryCreationFlow() throws {
       let app = XCUIApplication()
       app.launch()
       
       app.buttons["Novo Diário"].tap()
       app.textViews["Conteúdo"].typeText("Teste de entrada do diário")
       app.buttons["Salvar"].tap()
       
       XCTAssertTrue(app.staticTexts["Entrada salva com sucesso"].exists)
   }
   ```

### 5.2. Testes de Performance

1. **Testes de Carga:**
   - Simular 1000+ usuários simultâneos
   - Testar tempo de resposta das APIs
   - Monitorar uso de memória e CPU

2. **Testes de Conectividade:**
   - Testar comportamento offline
   - Sincronização quando volta online
   - Tratamento de erros de rede

## 6. Fase 5: Preparação para Lançamento

### 6.1. App Store Optimization (ASO)

1. **Metadados da App Store:**
   ```
   Nome: ManusPsiqueia - Diário com IA
   Subtítulo: Bem-estar mental com inteligência artificial
   
   Palavras-chave: diário, saúde mental, bem-estar, IA, mindfulness, 
                   autoconhecimento, terapia, ansiedade, depressão, humor
   
   Descrição:
   Transforme sua jornada de autoconhecimento com o ManusPsiqueia, 
   o primeiro diário inteligente que usa IA para ajudar você a 
   entender melhor suas emoções e padrões de pensamento.
   
   ✨ Funcionalidades principais:
   • Diário pessoal seguro e privado
   • Análise de sentimentos com IA avançada
   • Insights personalizados sobre seu bem-estar
   • Gráficos de humor e progresso
   • Lembretes inteligentes
   • Sincronização com iCloud
   
   🔒 Privacidade garantida:
   Seus dados são criptografados e nunca compartilhados. 
   Você tem controle total sobre suas informações pessoais.
   ```

2. **Screenshots e Vídeo Preview:**
   - 6.7": iPhone 15 Pro Max
   - 6.5": iPhone 15 Plus
   - 5.5": iPhone 8 Plus
   - 12.9": iPad Pro
   - Vídeo de 30 segundos mostrando funcionalidades principais

### 6.2. Materiais de Marketing

1. **Website Landing Page:**
   ```html
   <!-- Estrutura básica -->
   <header>
     <h1>ManusPsiqueia</h1>
     <p>Seu diário inteligente para bem-estar mental</p>
     <button>Download na App Store</button>
   </header>
   
   <section id="features">
     <!-- Funcionalidades principais -->
   </section>
   
   <section id="privacy">
     <!-- Garantias de privacidade -->
   </section>
   
   <section id="pricing">
     <!-- Planos e preços -->
   </section>
   ```

2. **Materiais para Imprensa:**
   - Press kit com logos e screenshots
   - Comunicado de imprensa
   - Biografia da empresa e fundadores

### 6.3. Estratégia de Preços

1. **Modelo Freemium:**
   - **Gratuito:** 5 entradas por mês, análises básicas
   - **Premium (R$ 29,90/mês):** Entradas ilimitadas, análises avançadas, insights personalizados, export de dados
   - **Premium Anual (R$ 299,90/ano):** Mesmo que mensal com 2 meses grátis

2. **Período de Teste:**
   - 7 dias grátis do Premium
   - Sem cobrança no cartão durante o teste

## 7. Fase 6: Lançamento e Crescimento

### 7.1. Estratégia de Lançamento

1. **Soft Launch (Semana 1-2):**
   - Lançar apenas no Brasil
   - Convidar 100 beta testers
   - Coletar feedback e corrigir bugs críticos

2. **Public Launch (Semana 3-4):**
   - Lançamento oficial na App Store
   - Campanha de marketing digital
   - Outreach para influenciadores de saúde mental

3. **Growth Phase (Mês 2-6):**
   - Otimização baseada em dados
   - Novas funcionalidades baseadas em feedback
   - Expansão para outros países

### 7.2. Métricas de Sucesso

1. **Métricas de Produto:**
   - 1.000 downloads na primeira semana
   - Taxa de retenção D7 > 40%
   - Taxa de conversão freemium → premium > 5%
   - Rating na App Store > 4.5

2. **Métricas de Negócio:**
   - MRR (Monthly Recurring Revenue) de R$ 10.000 em 3 meses
   - LTV/CAC ratio > 3:1
   - Churn rate mensal < 5%

### 7.3. Roadmap de Funcionalidades Futuras

1. **Trimestre 1:**
   - Apple Watch app
   - Widgets para iOS
   - Integração com Apple Health

2. **Trimestre 2:**
   - Versão para iPad otimizada
   - Temas personalizáveis
   - Compartilhamento com terapeutas

3. **Trimestre 3:**
   - Versão Android
   - Comunidade de usuários
   - Desafios de bem-estar

## 8. Checklist Final de Validação

### 8.1. Checklist Técnico

- [ ] Todas as APIs estão funcionando (Supabase, Stripe, OpenAI)
- [ ] App compila sem erros em Release
- [ ] Todos os testes unitários passam
- [ ] Testes de UI passam nos principais fluxos
- [ ] Performance está otimizada (< 100MB RAM, < 50% CPU)
- [ ] App funciona offline para funcionalidades básicas
- [ ] Sincronização com iCloud está funcionando
- [ ] Notificações push estão configuradas
- [ ] Analytics está coletando dados corretamente
- [ ] Crash reporting está configurado

### 8.2. Checklist de Negócio

- [ ] Modelo de preços definido e implementado
- [ ] Termos de uso e política de privacidade criados
- [ ] Materiais de marketing prontos
- [ ] Website landing page no ar
- [ ] Contas em redes sociais criadas
- [ ] Estratégia de lançamento definida
- [ ] Métricas de sucesso estabelecidas
- [ ] Plano de crescimento documentado

### 8.3. Checklist Legal e Compliance

- [ ] LGPD compliance implementado
- [ ] Termos de uso revisados por advogado
- [ ] Política de privacidade completa
- [ ] Consentimento para coleta de dados implementado
- [ ] Direito ao esquecimento implementado
- [ ] Criptografia de dados sensíveis
- [ ] Auditoria de segurança realizada

## 9. Recursos e Contatos Importantes

### 9.1. Documentação Técnica

- [Documentação do Supabase](https://supabase.com/docs)
- [Documentação do Stripe](https://stripe.com/docs)
- [Documentação da OpenAI](https://platform.openai.com/docs)
- [Guias da Apple para App Store](https://developer.apple.com/app-store/)

### 9.2. Ferramentas Recomendadas

- **Design:** Figma, Sketch
- **Analytics:** Firebase, Mixpanel
- **Crash Reporting:** Firebase Crashlytics
- **Customer Support:** Intercom, Zendesk
- **Email Marketing:** Mailchimp, ConvertKit
- **Social Media:** Buffer, Hootsuite

### 9.3. Comunidades e Suporte

- **iOS Development:** Stack Overflow, Reddit r/iOSProgramming
- **Startup Community:** Product Hunt, Indie Hackers
- **Mental Health Tech:** Digital Health Coalition
- **Brazilian Tech:** ABES, Brasscom

## 10. Conclusão

Este guia completo fornece um roadmap detalhado para transformar o ManusPsiqueia de um projeto técnico excelente em um produto de sucesso no mercado. A combinação de tecnologia avançada, foco no usuário e estratégia de negócio sólida posiciona o app para se tornar uma referência no segmento de saúde mental digital.

**Próximos Passos Imediatos:**

1. **Semana 1:** Configurar todos os serviços externos (Supabase, Stripe, OpenAI)
2. **Semana 2:** Implementar e testar todas as integrações
3. **Semana 3:** Preparar materiais de marketing e App Store
4. **Semana 4:** Soft launch com beta testers
5. **Semana 5:** Lançamento público oficial

O projeto está tecnicamente pronto. Agora é hora de executar a estratégia de negócio e levar o ManusPsiqueia ao mercado com confiança e ambição.

**Status Final:** 🚀 **PRONTO PARA EXECUÇÃO E LANÇAMENTO**
