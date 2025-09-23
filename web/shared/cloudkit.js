/**
 * CloudKit JS Integration Library for ManusPsiqueia
 * 
 * Esta biblioteca fornece uma interface simplificada para interagir
 * com o CloudKit JS, abstraindo a complexidade da configuração e
 * fornecendo métodos específicos para o domínio do ManusPsiqueia.
 */

class ManusPsiqueiaCloudKit {
  constructor() {
    this.container = null;
    this.database = null;
    this.isConfigured = false;
    this.isAuthenticated = false;
    this.currentUser = null;
  }

  /**
   * Configura o CloudKit JS com as credenciais do ManusPsiqueia
   * @param {Object} config - Configuração do CloudKit
   * @param {string} config.apiToken - Token de API do CloudKit
   * @param {string} config.environment - 'development' ou 'production'
   */
  async configure(config) {
    try {
      // Verificar se o CloudKit JS está carregado
      if (typeof CloudKit === 'undefined') {
        throw new Error('CloudKit JS não está carregado. Inclua o script do CloudKit JS.');
      }

      // Configurar o CloudKit
      CloudKit.configure({
        containers: [{
          containerIdentifier: 'iCloud.com.ailun.manuspsiqueia',
          apiTokenAuth: {
            apiToken: config.apiToken,
            persist: true
          },
          environment: config.environment || 'development'
        }]
      });

      this.container = CloudKit.getDefaultContainer();
      this.database = this.container.privateCloudDatabase;
      this.isConfigured = true;

      console.log('✅ CloudKit configurado com sucesso');
      return true;
    } catch (error) {
      console.error('❌ Erro ao configurar CloudKit:', error);
      throw error;
    }
  }

  /**
   * Autentica o usuário com Apple ID
   */
  async authenticate() {
    if (!this.isConfigured) {
      throw new Error('CloudKit não está configurado. Chame configure() primeiro.');
    }

    try {
      const userInfo = await this.container.setUpAuth();
      
      if (userInfo) {
        this.isAuthenticated = true;
        this.currentUser = userInfo;
        console.log('✅ Usuário autenticado:', userInfo.userRecordName);
        return userInfo;
      } else {
        // Solicitar autenticação
        const result = await this.container.requestApplicationPermission('WRITE');
        
        if (result.permission === 'GRANTED') {
          const userInfo = await this.container.setUpAuth();
          this.isAuthenticated = true;
          this.currentUser = userInfo;
          return userInfo;
        } else {
          throw new Error('Permissão negada pelo usuário');
        }
      }
    } catch (error) {
      console.error('❌ Erro na autenticação:', error);
      throw error;
    }
  }

  /**
   * Busca entradas do diário de um paciente
   * @param {string} patientId - ID do paciente
   * @param {Object} options - Opções de busca
   */
  async fetchDiaryEntries(patientId, options = {}) {
    this._ensureAuthenticated();

    try {
      const query = {
        recordType: 'DiaryEntry',
        filterBy: [{
          fieldName: 'patientID',
          comparator: 'EQUALS',
          fieldValue: { value: patientId }
        }],
        sortBy: [{
          fieldName: 'createdAt',
          ascending: false
        }]
      };

      // Aplicar limite se especificado
      if (options.limit) {
        query.resultsLimit = options.limit;
      }

      // Aplicar filtro de data se especificado
      if (options.startDate) {
        query.filterBy.push({
          fieldName: 'createdAt',
          comparator: 'GREATER_THAN_OR_EQUALS',
          fieldValue: { value: options.startDate }
        });
      }

      const response = await this.database.performQuery(query);
      
      return response.records.map(record => ({
        id: record.recordName,
        content: record.fields.content?.value || '',
        mood: record.fields.mood?.value || 0,
        date: new Date(record.fields.createdAt?.value || record.created.timestamp),
        isPrivate: record.fields.isPrivate?.value || false,
        tags: record.fields.tags?.value || [],
        patientId: record.fields.patientID?.value
      }));
    } catch (error) {
      console.error('❌ Erro ao buscar entradas do diário:', error);
      throw error;
    }
  }

  /**
   * Busca informações de pacientes
   * @param {Array} patientIds - Array de IDs dos pacientes (opcional)
   */
  async fetchPatients(patientIds = null) {
    this._ensureAuthenticated();

    try {
      const query = {
        recordType: 'User',
        filterBy: [{
          fieldName: 'userType',
          comparator: 'EQUALS',
          fieldValue: { value: 'patient' }
        }]
      };

      // Se IDs específicos foram fornecidos, filtrar por eles
      if (patientIds && patientIds.length > 0) {
        query.filterBy.push({
          fieldName: 'recordName',
          comparator: 'IN',
          fieldValue: { value: patientIds }
        });
      }

      const response = await this.database.performQuery(query);
      
      return response.records.map(record => ({
        id: record.recordName,
        name: record.fields.name?.value || 'Nome não disponível',
        email: record.fields.email?.value || '',
        lastActive: record.fields.lastActive?.value ? new Date(record.fields.lastActive.value) : null,
        subscriptionStatus: record.fields.subscriptionStatus?.value || 'free',
        createdAt: new Date(record.created.timestamp)
      }));
    } catch (error) {
      console.error('❌ Erro ao buscar pacientes:', error);
      throw error;
    }
  }

  /**
   * Cria um relatório de progresso
   * @param {Object} reportData - Dados do relatório
   */
  async createProgressReport(reportData) {
    this._ensureAuthenticated();

    try {
      const record = {
        recordType: 'ProgressReport',
        fields: {
          patientID: { value: reportData.patientId },
          reportType: { value: reportData.type || 'weekly' },
          content: { value: reportData.content },
          insights: { value: reportData.insights || '' },
          moodTrend: { value: reportData.moodTrend || [] },
          generatedBy: { value: this.currentUser.userRecordName },
          generatedAt: { value: new Date() }
        }
      };

      const response = await this.database.saveRecords([record]);
      return response.records[0];
    } catch (error) {
      console.error('❌ Erro ao criar relatório:', error);
      throw error;
    }
  }

  /**
   * Busca estatísticas agregadas
   */
  async fetchDashboardStats() {
    this._ensureAuthenticated();

    try {
      // Buscar contagem de pacientes
      const patientsQuery = {
        recordType: 'User',
        filterBy: [{
          fieldName: 'userType',
          comparator: 'EQUALS',
          fieldValue: { value: 'patient' }
        }]
      };

      // Buscar entradas de hoje
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      
      const entriesQuery = {
        recordType: 'DiaryEntry',
        filterBy: [{
          fieldName: 'createdAt',
          comparator: 'GREATER_THAN_OR_EQUALS',
          fieldValue: { value: today }
        }]
      };

      const [patientsResponse, entriesResponse] = await Promise.all([
        this.database.performQuery(patientsQuery),
        this.database.performQuery(entriesQuery)
      ]);

      // Calcular humor médio das entradas de hoje
      const todayEntries = entriesResponse.records;
      const avgMood = todayEntries.length > 0 
        ? todayEntries.reduce((sum, record) => sum + (record.fields.mood?.value || 0), 0) / todayEntries.length
        : 0;

      return {
        totalPatients: patientsResponse.records.length,
        todayEntries: todayEntries.length,
        averageMood: Math.round(avgMood * 10) / 10,
        activePatients: patientsResponse.records.filter(record => {
          const lastActive = record.fields.lastActive?.value;
          if (!lastActive) return false;
          const daysSinceActive = (Date.now() - new Date(lastActive).getTime()) / (1000 * 60 * 60 * 24);
          return daysSinceActive <= 7;
        }).length
      };
    } catch (error) {
      console.error('❌ Erro ao buscar estatísticas:', error);
      throw error;
    }
  }

  /**
   * Verifica se o usuário está autenticado
   */
  _ensureAuthenticated() {
    if (!this.isAuthenticated) {
      throw new Error('Usuário não está autenticado. Chame authenticate() primeiro.');
    }
  }

  /**
   * Obtém o status da conexão
   */
  getConnectionStatus() {
    return {
      configured: this.isConfigured,
      authenticated: this.isAuthenticated,
      user: this.currentUser
    };
  }
}

// Exportar para uso em módulos
if (typeof module !== 'undefined' && module.exports) {
  module.exports = ManusPsiqueiaCloudKit;
}

// Disponibilizar globalmente para uso direto
if (typeof window !== 'undefined') {
  window.ManusPsiqueiaCloudKit = ManusPsiqueiaCloudKit;
}

export default ManusPsiqueiaCloudKit;
