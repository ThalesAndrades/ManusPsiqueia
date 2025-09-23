import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button.jsx'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card.jsx'
import { Badge } from '@/components/ui/badge.jsx'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar.jsx'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs.jsx'
import { 
  Users, 
  TrendingUp, 
  Calendar, 
  MessageSquare, 
  BarChart3, 
  Settings,
  Bell,
  Search,
  Plus,
  Filter
} from 'lucide-react'
import './App.css'

function App() {
  const [cloudKitStatus, setCloudKitStatus] = useState('connecting')
  const [patients, setPatients] = useState([])

  // Simular conexão com CloudKit
  useEffect(() => {
    const initializeCloudKit = async () => {
      try {
        // Aqui será implementada a conexão real com CloudKit JS
        console.log('Inicializando CloudKit...')
        
        // Simular delay de conexão
        await new Promise(resolve => setTimeout(resolve, 2000))
        
        setCloudKitStatus('connected')
        
        // Dados simulados de pacientes
        setPatients([
          {
            id: '1',
            name: 'Ana Silva',
            lastEntry: '2025-09-22',
            mood: 7,
            status: 'active',
            avatar: null
          },
          {
            id: '2', 
            name: 'Carlos Santos',
            lastEntry: '2025-09-21',
            mood: 5,
            status: 'needs_attention',
            avatar: null
          },
          {
            id: '3',
            name: 'Maria Oliveira', 
            lastEntry: '2025-09-23',
            mood: 8,
            status: 'active',
            avatar: null
          }
        ])
      } catch (error) {
        console.error('Erro ao conectar com CloudKit:', error)
        setCloudKitStatus('error')
      }
    }

    initializeCloudKit()
  }, [])

  const getStatusColor = (status) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-800'
      case 'needs_attention': return 'bg-yellow-100 text-yellow-800'
      case 'inactive': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const getMoodEmoji = (mood) => {
    if (mood >= 8) return '😊'
    if (mood >= 6) return '😐'
    if (mood >= 4) return '😔'
    return '😢'
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 px-6 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <h1 className="text-2xl font-bold text-gray-900">ManusPsiqueia</h1>
            <Badge variant="outline" className="text-blue-600">
              Dashboard Profissional
            </Badge>
          </div>
          
          <div className="flex items-center space-x-4">
            <div className="flex items-center space-x-2">
              <div className={`w-2 h-2 rounded-full ${
                cloudKitStatus === 'connected' ? 'bg-green-500' : 
                cloudKitStatus === 'connecting' ? 'bg-yellow-500' : 'bg-red-500'
              }`} />
              <span className="text-sm text-gray-600">
                {cloudKitStatus === 'connected' ? 'CloudKit Conectado' : 
                 cloudKitStatus === 'connecting' ? 'Conectando...' : 'Erro de Conexão'}
              </span>
            </div>
            
            <Button variant="ghost" size="sm">
              <Bell className="h-4 w-4" />
            </Button>
            
            <Button variant="ghost" size="sm">
              <Settings className="h-4 w-4" />
            </Button>
            
            <Avatar>
              <AvatarFallback>PS</AvatarFallback>
            </Avatar>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="p-6">
        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total de Pacientes</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{patients.length}</div>
              <p className="text-xs text-muted-foreground">
                +2 novos esta semana
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Entradas Hoje</CardTitle>
              <MessageSquare className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">12</div>
              <p className="text-xs text-muted-foreground">
                +20% vs ontem
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Humor Médio</CardTitle>
              <TrendingUp className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">7.2</div>
              <p className="text-xs text-muted-foreground">
                +0.5 vs semana passada
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Consultas Hoje</CardTitle>
              <Calendar className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">5</div>
              <p className="text-xs text-muted-foreground">
                3 presenciais, 2 online
              </p>
            </CardContent>
          </Card>
        </div>

        {/* Tabs */}
        <Tabs defaultValue="patients" className="space-y-4">
          <TabsList>
            <TabsTrigger value="patients">Pacientes</TabsTrigger>
            <TabsTrigger value="analytics">Analytics</TabsTrigger>
            <TabsTrigger value="reports">Relatórios</TabsTrigger>
            <TabsTrigger value="messages">Mensagens</TabsTrigger>
          </TabsList>

          <TabsContent value="patients" className="space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-semibold">Lista de Pacientes</h2>
              <div className="flex items-center space-x-2">
                <Button variant="outline" size="sm">
                  <Search className="h-4 w-4 mr-2" />
                  Buscar
                </Button>
                <Button variant="outline" size="sm">
                  <Filter className="h-4 w-4 mr-2" />
                  Filtrar
                </Button>
                <Button size="sm">
                  <Plus className="h-4 w-4 mr-2" />
                  Novo Paciente
                </Button>
              </div>
            </div>

            <div className="grid gap-4">
              {patients.map((patient) => (
                <Card key={patient.id} className="hover:shadow-md transition-shadow cursor-pointer">
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-4">
                        <Avatar>
                          <AvatarImage src={patient.avatar} />
                          <AvatarFallback>
                            {patient.name.split(' ').map(n => n[0]).join('')}
                          </AvatarFallback>
                        </Avatar>
                        
                        <div>
                          <h3 className="font-semibold">{patient.name}</h3>
                          <p className="text-sm text-gray-600">
                            Última entrada: {new Date(patient.lastEntry).toLocaleDateString('pt-BR')}
                          </p>
                        </div>
                      </div>
                      
                      <div className="flex items-center space-x-4">
                        <div className="text-center">
                          <div className="text-2xl">{getMoodEmoji(patient.mood)}</div>
                          <div className="text-sm text-gray-600">Humor: {patient.mood}/10</div>
                        </div>
                        
                        <Badge className={getStatusColor(patient.status)}>
                          {patient.status === 'active' ? 'Ativo' : 
                           patient.status === 'needs_attention' ? 'Atenção' : 'Inativo'}
                        </Badge>
                        
                        <Button variant="outline" size="sm">
                          Ver Detalhes
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </TabsContent>

          <TabsContent value="analytics">
            <Card>
              <CardHeader>
                <CardTitle>Analytics em Desenvolvimento</CardTitle>
                <CardDescription>
                  Gráficos e métricas detalhadas serão implementados aqui
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="flex items-center justify-center h-64 bg-gray-50 rounded-lg">
                  <div className="text-center">
                    <BarChart3 className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                    <p className="text-gray-600">Gráficos de evolução e tendências</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="reports">
            <Card>
              <CardHeader>
                <CardTitle>Relatórios Automatizados</CardTitle>
                <CardDescription>
                  Relatórios gerados pela IA do ManusPsiqueia
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="flex items-center justify-center h-64 bg-gray-50 rounded-lg">
                  <div className="text-center">
                    <MessageSquare className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                    <p className="text-gray-600">Relatórios de progresso e insights</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="messages">
            <Card>
              <CardHeader>
                <CardTitle>Centro de Mensagens</CardTitle>
                <CardDescription>
                  Comunicação segura com pacientes
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="flex items-center justify-center h-64 bg-gray-50 rounded-lg">
                  <div className="text-center">
                    <MessageSquare className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                    <p className="text-gray-600">Sistema de mensagens em desenvolvimento</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </main>
    </div>
  )
}

export default App
