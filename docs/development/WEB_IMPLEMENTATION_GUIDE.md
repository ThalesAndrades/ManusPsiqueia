# 🌐 Guia de Implementação para Aplicações Web

**Data:** 23 de setembro de 2025  
**Projeto:** ManusPsiqueia  
**Fase:** 5 - Guias de Implementação

## 1. Introdução

Este guia fornece um passo a passo para desenvolvedores que desejam contribuir com as aplicações web do ManusPsiqueia (Dashboard Profissional e Portal da Família). Ele cobre desde a configuração do ambiente até a execução de testes e a submissão de código.

## 2. Pré-requisitos

-   Node.js (versão 20 ou superior)
-   pnpm (instalado via `npm install -g pnpm`)
-   Acesso ao repositório GitHub do ManusPsiqueia
-   Um editor de código (ex: VS Code)

## 3. Configuração do Ambiente de Desenvolvimento

1.  **Clonar o Repositório:**
    ```bash
    git clone https://github.com/ThalesAndrades/ManusPsiqueia.git
    cd ManusPsiqueia
    ```

2.  **Navegar para o Projeto Web:**
    ```bash
    cd web/dashboard-profissional
    ```

3.  **Instalar Dependências:**
    ```bash
    pnpm install
    ```

4.  **Configurar Variáveis de Ambiente:**
    -   Crie um arquivo `.env.local` na raiz do projeto web (`web/dashboard-profissional`).
    -   Adicione as seguintes variáveis:
        ```
        VITE_CLOUDKIT_API_TOKEN_DEV=seu-token-de-desenvolvimento
        VITE_ENVIRONMENT=development
        ```
    -   **Nota:** Obtenha o token de API do CloudKit Dashboard.

5.  **Iniciar o Servidor de Desenvolvimento:**
    ```bash
    pnpm run dev
    ```
    -   A aplicação estará disponível em `http://localhost:5173`.

## 4. Estrutura do Projeto (React)

-   **`src/`**: Diretório principal do código-fonte.
    -   **`components/`**: Componentes React reutilizáveis.
        -   **`ui/`**: Componentes do Shadcn/UI.
    -   **`hooks/`**: Hooks React customizados.
    -   **`lib/`**: Funções utilitárias e bibliotecas.
    -   **`App.jsx`**: Componente principal da aplicação.
    -   **`main.jsx`**: Ponto de entrada da aplicação.
-   **`public/`**: Arquivos estáticos.
-   **`package.json`**: Dependências e scripts do projeto.

## 5. Fluxo de Desenvolvimento

1.  **Criar uma Nova Branch:**
    ```bash
    git checkout -b feature/nome-da-sua-feature
    ```

2.  **Desenvolver a Funcionalidade:**
    -   Crie novos componentes, hooks e páginas conforme necessário.
    -   Utilize os componentes do Shadcn/UI para manter a consistência visual.
    -   Siga as convenções de estilo e linting do projeto.

3.  **Escrever Testes:**
    -   Crie testes unitários para seus componentes e hooks.
    -   Execute os testes com `pnpm test`.

4.  **Submeter um Pull Request:**
    -   Faça commit de suas alterações com uma mensagem clara.
    -   Envie a branch para o GitHub: `git push origin feature/nome-da-sua-feature`
    -   Abra um pull request para a branch `master`.

## 6. Scripts Úteis

-   `pnpm run dev`: Inicia o servidor de desenvolvimento.
-   `pnpm run build`: Gera o build de produção.
-   `pnpm run test`: Executa os testes.
-   `pnpm run lint`: Executa o linter.
-   `pnpm run preview`: Visualiza o build de produção localmente.

---

**Responsável:** Manus AI  
**Aprovação:** (Pendente)

