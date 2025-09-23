# 🚀 Guia de Deploy para Aplicações Web

**Data:** 23 de setembro de 2025  
**Projeto:** ManusPsiqueia  
**Fase:** 5 - Guias de Deploy

## 1. Introdução

Este guia descreve o processo de deploy das aplicações web do ManusPsiqueia (Dashboard Profissional e Portal da Família) utilizando o pipeline de CI/CD configurado no Xcode Cloud e a plataforma de hospedagem Vercel.

## 2. Deploy Automatizado (Recomendado)

O deploy é totalmente automatizado através do Xcode Cloud. Qualquer commit na branch `master` no diretório `/web` irá disparar o workflow `Web-CI-CD`, que fará o deploy automaticamente para a Vercel.

### **Fluxo do Deploy Automatizado:**

1.  **Commit e Push:** O desenvolvedor faz um commit e push para a branch `master`.
2.  **Trigger no Xcode Cloud:** O Xcode Cloud detecta o commit no diretório `/web` e inicia o workflow `Web-CI-CD`.
3.  **Build e Teste:** O workflow instala as dependências, executa testes e gera o build de produção.
4.  **Deploy na Vercel:** O build é enviado para a Vercel e publicado no ambiente de produção.

## 3. Deploy Manual (Para Emergências)

Em caso de falha no pipeline de CI/CD, é possível fazer o deploy manualmente.

### **Pré-requisitos:**

-   Vercel CLI instalado (`npm install -g vercel`)
-   Token de acesso da Vercel
-   Acesso ao repositório GitHub

### **Passos para Deploy Manual:**

1.  **Login na Vercel:**
    ```bash
    vercel login
    ```

2.  **Clonar o Repositório:**
    ```bash
    git clone https://github.com/ThalesAndrades/ManusPsiqueia.git
    cd ManusPsiqueia/web/dashboard-profissional
    ```

3.  **Instalar Dependências e Fazer Build:**
    ```bash
    pnpm install
    pnpm run build
    ```

4.  **Fazer o Deploy:**
    ```bash
    vercel --prod --token SEU_VERCEL_TOKEN
    ```

## 4. Configuração na Vercel

1.  **Criar um Novo Projeto:**
    -   No dashboard da Vercel, clique em **Add New... > Project**.
    -   Importe o repositório `ThalesAndrades/ManusPsiqueia`.

2.  **Configurar o Projeto:**
    -   **Framework Preset:** Vite
    -   **Build Command:** `pnpm run build`
    -   **Output Directory:** `dist`
    -   **Root Directory:** `web/dashboard-profissional`

3.  **Configurar Variáveis de Ambiente:**
    -   No menu **Settings > Environment Variables**, adicione:
        -   `VITE_CLOUDKIT_API_TOKEN_PROD`: Token de produção do CloudKit
        -   `VITE_ENVIRONMENT`: `production`

## 5. Monitoramento

-   **Logs do Xcode Cloud:** Verifique os logs de cada execução do workflow para diagnosticar problemas.
-   **Dashboard da Vercel:** Monitore o status dos deploys, o tráfego e os logs da aplicação.

---

**Responsável:** Manus AI  
**Aprovação:** (Pendente)

