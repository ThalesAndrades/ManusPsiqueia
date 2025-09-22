# Guia de Contribuição - ManusPsiqueia

Primeiramente, agradecemos por seu interesse em contribuir com o ManusPsiqueia! Este guia detalha como você pode nos ajudar a construir uma plataforma de saúde mental cada vez melhor.

## Como Contribuir

Existem várias maneiras de contribuir com o projeto, desde a sugestão de novas funcionalidades até a correção de bugs e melhoria da documentação.

### Reportando Bugs

Se você encontrar um bug, por favor, abra uma [issue](https://github.com/ThalesAndrades/ManusPsiqueia/issues) com as seguintes informações:

- **Descrição clara e concisa** do bug.
- **Passos para reproduzir** o comportamento.
- **Comportamento esperado** e o que realmente aconteceu.
- **Capturas de tela** ou vídeos, se aplicável.
- **Ambiente** (versão do iOS, modelo do dispositivo).

### Sugerindo Melhorias

Para sugerir novas funcionalidades ou melhorias, abra uma [issue](https://github.com/ThalesAndrades/ManusPsiqueia/issues) com a tag `enhancement`. Descreva sua ideia em detalhes, explicando o problema que ela resolve e como beneficiaria os usuários.

## Configuração do Ambiente de Desenvolvimento

Para começar a desenvolver, siga os passos abaixo:

1. **Faça um fork** do repositório.
2. **Clone seu fork** localmente: `git clone https://github.com/seu-usuario/ManusPsiqueia.git`
3. **Abra o projeto** no Xcode: `open ManusPsiqueia.xcodeproj`
4. **Instale as dependências** do Swift Package Manager (o Xcode fará isso automaticamente).

## Padrões de Código

Utilizamos o [SwiftLint](https://github.com/realm/SwiftLint) para garantir um estilo de código consistente. Antes de fazer um commit, certifique-se de que seu código está em conformidade com as regras definidas no arquivo `.swiftlint.yml`.

Você pode rodar o SwiftLint manualmente com o comando:
```bash
swiftlint
```

## Processo de Pull Request

1. **Crie uma nova branch** para sua feature ou correção de bug: `git checkout -b feature/sua-feature` ou `bugfix/seu-bug`.
2. **Faça suas alterações** e commite com mensagens claras e descritivas.
3. **Envie suas alterações** para o seu fork: `git push origin feature/sua-feature`.
4. **Abra um Pull Request** (PR) para a branch `develop` do repositório principal.
5. **Aguarde a revisão** do seu PR. Faremos o possível para revisar o mais rápido possível.

## Licença

Ao contribuir, você concorda que suas contribuições serão licenciadas sob a [Licença MIT](LICENSE) do projeto.

