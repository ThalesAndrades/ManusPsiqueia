/**
 * Configuração centralizada para as aplicações web do ManusPsiqueia
 */

// Configurações por ambiente
const environments = {
  development: {
    cloudkit: {
      environment: 'development',
      apiToken: process.env.VITE_CLOUDKIT_API_TOKEN_DEV || 'your-dev-token-here'
    },
    api: {
      baseUrl: 'https://dev-api.manuspsiqueia.com.br',
      timeout: 10000
    },
    features: {
      analytics: false,
      debugMode: true,
      mockData: true
    }
  },
  
  staging: {
    cloudkit: {
      environment: 'development', // Usar development para staging também
      apiToken: process.env.VITE_CLOUDKIT_API_TOKEN_STAGING || 'your-staging-token-here'
    },
    api: {
      baseUrl: 'https://staging-api.manuspsiqueia.com.br',
      timeout: 8000
    },
    features: {
      analytics: true,
      debugMode: false,
      mockData: false
    }
  },
  
  production: {
    cloudkit: {
      environment: 'production',
      apiToken: process.env.VITE_CLOUDKIT_API_TOKEN_PROD || 'your-prod-token-here'
    },
    api: {
      baseUrl: 'https://api.manuspsiqueia.com.br',
      timeout: 5000
    },
    features: {
      analytics: true,
      debugMode: false,
      mockData: false
    }
  }
};

// Detectar ambiente atual
const getCurrentEnvironment = () => {
  // Verificar variável de ambiente do Vite
  if (import.meta.env.VITE_ENVIRONMENT) {
    return import.meta.env.VITE_ENVIRONMENT;
  }
  
  // Detectar baseado na URL (para builds de produção)
  if (typeof window !== 'undefined') {
    const hostname = window.location.hostname;
    
    if (hostname.includes('localhost') || hostname.includes('127.0.0.1')) {
      return 'development';
    } else if (hostname.includes('staging')) {
      return 'staging';
    } else {
      return 'production';
    }
  }
  
  // Fallback para development
  return 'development';
};

// Configuração atual baseada no ambiente
const currentEnv = getCurrentEnvironment();
const config = environments[currentEnv];

// Adicionar informações do ambiente à configuração
config.environment = currentEnv;
config.version = '1.0.0';
config.buildDate = new Date().toISOString();

// Configurações específicas da aplicação
config.app = {
  name: 'ManusPsiqueia',
  description: 'Plataforma de Saúde Mental Digital',
  company: 'AiLun Tecnologia',
  supportEmail: 'suporte@manuspsiqueia.com.br',
  privacyPolicyUrl: 'https://manuspsiqueia.com.br/privacidade',
  termsOfServiceUrl: 'https://manuspsiqueia.com.br/termos'
};

// Configurações de UI
config.ui = {
  theme: {
    primaryColor: '#3B82F6', // Blue-500
    secondaryColor: '#10B981', // Green-500
    accentColor: '#F59E0B', // Yellow-500
    errorColor: '#EF4444', // Red-500
    warningColor: '#F97316', // Orange-500
    successColor: '#22C55E' // Green-500
  },
  
  layout: {
    sidebarWidth: '256px',
    headerHeight: '64px',
    maxContentWidth: '1200px'
  },
  
  animations: {
    duration: '200ms',
    easing: 'cubic-bezier(0.4, 0, 0.2, 1)'
  }
};

// Configurações de dados mock (para desenvolvimento)
config.mockData = {
  patients: [
    {
      id: '1',
      name: 'Ana Silva',
      email: 'ana.silva@email.com',
      lastEntry: '2025-09-22',
      mood: 7,
      status: 'active',
      avatar: null,
      subscriptionStatus: 'premium'
    },
    {
      id: '2',
      name: 'Carlos Santos',
      email: 'carlos.santos@email.com',
      lastEntry: '2025-09-21',
      mood: 5,
      status: 'needs_attention',
      avatar: null,
      subscriptionStatus: 'free'
    },
    {
      id: '3',
      name: 'Maria Oliveira',
      email: 'maria.oliveira@email.com',
      lastEntry: '2025-09-23',
      mood: 8,
      status: 'active',
      avatar: null,
      subscriptionStatus: 'premium'
    },
    {
      id: '4',
      name: 'João Pereira',
      email: 'joao.pereira@email.com',
      lastEntry: '2025-09-20',
      mood: 6,
      status: 'inactive',
      avatar: null,
      subscriptionStatus: 'free'
    }
  ],
  
  diaryEntries: [
    {
      id: '1',
      patientId: '1',
      content: 'Hoje foi um dia melhor. Consegui sair para caminhar e me senti mais animada.',
      mood: 7,
      date: '2025-09-22',
      tags: ['exercício', 'humor positivo'],
      isPrivate: false
    },
    {
      id: '2',
      patientId: '2',
      content: 'Dia difícil no trabalho. Muita pressão e ansiedade.',
      mood: 4,
      date: '2025-09-21',
      tags: ['trabalho', 'ansiedade'],
      isPrivate: true
    }
  ],
  
  stats: {
    totalPatients: 4,
    todayEntries: 12,
    averageMood: 7.2,
    activePatients: 3,
    weeklyGrowth: 15,
    monthlyRetention: 85
  }
};

// Utilitários de configuração
config.utils = {
  /**
   * Verifica se uma feature está habilitada
   */
  isFeatureEnabled: (featureName) => {
    return config.features[featureName] || false;
  },
  
  /**
   * Obtém a URL da API com endpoint
   */
  getApiUrl: (endpoint) => {
    return `${config.api.baseUrl}${endpoint.startsWith('/') ? '' : '/'}${endpoint}`;
  },
  
  /**
   * Verifica se está em modo de desenvolvimento
   */
  isDevelopment: () => {
    return config.environment === 'development';
  },
  
  /**
   * Verifica se está em modo de produção
   */
  isProduction: () => {
    return config.environment === 'production';
  },
  
  /**
   * Log condicional (apenas em desenvolvimento)
   */
  log: (...args) => {
    if (config.features.debugMode) {
      console.log('[ManusPsiqueia]', ...args);
    }
  },
  
  /**
   * Obtém dados mock se habilitado
   */
  getMockData: (dataType) => {
    if (config.features.mockData && config.mockData[dataType]) {
      return config.mockData[dataType];
    }
    return null;
  }
};

// Log da configuração atual (apenas em desenvolvimento)
if (config.features.debugMode) {
  console.log('🔧 Configuração do ManusPsiqueia:', {
    environment: config.environment,
    version: config.version,
    features: config.features,
    cloudkit: {
      environment: config.cloudkit.environment,
      hasToken: !!config.cloudkit.apiToken && config.cloudkit.apiToken !== 'your-dev-token-here'
    }
  });
}

export default config;
