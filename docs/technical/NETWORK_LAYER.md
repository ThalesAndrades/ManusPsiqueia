# Arquitetura da Camada de Rede - ManusPsiqueia

**Data:** 22 de setembro de 2025  
**Autor:** Manus AI  
**Versão:** 2.0

## 1. Visão Geral

A camada de rede do ManusPsiqueia foi completamente refatorada para ser mais robusta, resiliente e centralizada. A nova arquitetura é composta por dois componentes principais:

-   **`NetworkManager`**: Uma classe de baixo nível responsável por todas as operações de rede, incluindo monitoramento de conectividade, retry automático e tratamento de erros.
-   **`APIService`**: Uma classe de alto nível que utiliza o `NetworkManager` para se comunicar com todas as APIs externas (OpenAI, Stripe, Supabase) e com o backend do ManusPsiqueia.

Esta arquitetura desacopla a lógica de negócio da complexidade da rede, tornando o código mais limpo, testável e fácil de manter.

## 2. Componentes Principais

### 2.1. NetworkManager

O `NetworkManager` é o coração da camada de rede. Suas principais responsabilidades são:

-   **Monitoramento de Conectividade:** Utiliza `NWPathMonitor` para detectar o status da rede em tempo real e notificar a aplicação sobre mudanças.
-   **Retry Automático:** Tenta novamente requisições que falham devido a erros de servidor (5xx) ou problemas de rede, com um delay configurável.
-   **Timeout Configurável:** Permite definir timeouts específicos para diferentes tipos de requisição (rápida, padrão, crítica).
-   **Tratamento de Erros Centralizado:** Mapeia erros de URLSession para um enum `NetworkError` claro e conciso.
-   **Requisições Genéricas:** Oferece métodos genéricos (`GET`, `POST`, `PUT`, `DELETE`) que podem ser usados por qualquer serviço.
-   **Suporte a Batch e Upload/Download:** Inclui métodos para realizar requisições em lote e para fazer upload/download de arquivos.

#### Exemplo de Uso (GET)

```swift
struct User: Codable {
    let id: Int
    let name: String
}

let url = URL(string: "https://api.example.com/users/1")!

do {
    let user: User = try await NetworkManager.shared.get(url: url)
    print("Usuário encontrado: \(user.name)")
} catch {
    print("Erro ao buscar usuário: \(error.localizedDescription)")
}
```

### 2.2. APIService

O `APIService` atua como uma fachada (Facade) para todas as interações com APIs. Ele utiliza o `NetworkManager` para realizar as requisições e encapsula toda a lógica específica de cada API.

-   **Centralização:** Todas as chamadas de API passam por este serviço, facilitando o gerenciamento e a depuração.
-   **Lógica de Negócio:** Contém a lógica para construir os corpos das requisições, adicionar headers de autenticação e decodificar as respostas para os modelos de dados da aplicação.
-   **Gerenciamento de Estado:** Publica propriedades como `isLoading` e `lastError`, permitindo que a UI reaja ao estado das requisições.
-   **Validação de Configuração:** Inclui métodos para validar se todas as chaves de API e URLs necessárias estão configuradas antes de fazer uma chamada.

#### Exemplo de Uso (OpenAI)

```swift
let diaryText = "Hoje foi um dia desafiador, mas consegui superar os obstáculos."

do {
    let insight = try await APIService.shared.generateDiaryInsight(text: diaryText)
    print("Insight gerado: \(insight.text)")
    print("Sentimento: \(insight.sentiment.rawValue)")
} catch {
    print("Erro ao gerar insight: \(error.localizedDescription)")
}
```

## 3. Fluxo de uma Requisição

1.  **UI/ViewModel:** Uma ação do usuário dispara uma chamada a um método no `APIService` (ex: `generateDiaryInsight`).
2.  **APIService:**
    -   Define `isLoading` como `true`.
    -   Valida a configuração da API (ex: verifica se a chave da OpenAI existe).
    -   Constrói a URL, o corpo da requisição e os headers de autenticação.
    -   Chama o método apropriado no `NetworkManager` (ex: `post`).
3.  **NetworkManager:**
    -   Verifica a conectividade da rede.
    -   Cria uma `URLRequest` com as configurações de timeout e cache.
    -   Executa a requisição usando `URLSession`.
    -   Se a requisição falhar, tenta novamente (se aplicável).
    -   Se a requisição for bem-sucedida, decodifica a resposta para o tipo genérico `T`.
    -   Se ocorrer um erro, mapeia para um `NetworkError` e o lança.
4.  **APIService:**
    -   Recebe o resultado (sucesso ou erro) do `NetworkManager`.
    -   Se for sucesso, processa os dados e os retorna para a camada de UI.
    -   Se for erro, mapeia para um `APIError`, atualiza `lastError` e o lança.
    -   Define `isLoading` como `false`.
5.  **UI/ViewModel:**
    -   Recebe os dados ou o erro.
    -   Atualiza a interface do usuário para refletir o resultado.

## 4. Tratamento de Erros

A nova camada de rede possui um sistema de tratamento de erros em dois níveis:

-   **`NetworkError` (NetworkManager):** Erros de baixo nível relacionados à conectividade, timeouts, respostas inválidas e erros de servidor.
-   **`APIError` (APIService):** Erros de alto nível relacionados à lógica de negócio, como configuração inválida, autenticação falha ou limite de requisições excedido.

Essa separação permite que a UI trate os erros de forma mais granular. Por exemplo, um erro `APIError.authenticationFailed` pode redirecionar o usuário para a tela de login, enquanto um `APIError.networkUnavailable` pode exibir um banner de "sem conexão".

## 5. Como Adicionar um Novo Endpoint

Adicionar um novo endpoint é um processo simples e direto:

1.  **Adicionar Endpoint no `APIService`:**
    -   Se for uma nova API, adicione a URL base na struct `Endpoints`.
    -   Crie um novo método no `APIService` para a nova funcionalidade (ex: `fetchWeatherForecast`).

2.  **Implementar o Método:**
    -   Valide a configuração necessária (chaves de API, etc.).
    -   Construa a URL, o corpo da requisição e os headers.
    -   Chame o método apropriado do `NetworkManager` (`get`, `post`, etc.), passando os dados e a configuração de requisição (`.default`, `.fast`, `.critical`).
    -   Encapsule a chamada em um bloco `do-catch` para tratar erros e gerenciar o estado `isLoading`.

3.  **Criar Modelos de Dados:**
    -   Crie as structs `Codable` necessárias para o corpo da requisição e para a resposta.

4.  **Chamar na UI:**
    -   Chame o novo método do `APIService` a partir do seu ViewModel ou View.

## 6. Conclusão

A nova arquitetura da camada de rede fornece uma base sólida, segura e escalável para o ManusPsiqueia. Ela promove boas práticas de desenvolvimento, como o desacoplamento de responsabilidades e o tratamento de erros robusto, garantindo que o aplicativo possa crescer de forma sustentável e oferecer uma experiência confiável aos usuários.
