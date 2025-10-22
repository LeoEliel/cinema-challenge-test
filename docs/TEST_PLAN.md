# **Plano de Testes: Aplicação Cinema Challenge (Back-end e Front-end)**

**Data de Elaboração:** 20 de Outubro de 2025

**Última Atualização:** 22 de Outubro de 2025

## 1. Apresentação
<!--
## 1. Apresentação

Este documento detalha o plano de testes para a aplicação **Cinema Challenge**, abrangendo sua API REST (back-end) e interface web (front-end).

O pilar central deste projeto é a implementação de uma esteira de DevOps e Qualidade Contínua. A estratégia de inovação, que atende aos requisitos do "Adicional de Inovação", se divide em duas frentes principais:

1.  **Criação de Ambiente de Teste (Docker):** A aplicação (back-end e front-end) será **containerizada utilizando Docker e Docker Compose**. Isso garante um ambiente de teste estável, isolado e 100% reprodutível, eliminando problemas de "funciona na minha máquina" e facilitando a execução em qualquer ambiente.
2.  **Automação da Execução (CI/CD):** Um pipeline de Integração Contínua será configurado com **GitHub Actions**. Este pipeline será responsável por "orquestrar" o processo: ele irá construir os containers da aplicação, subí-los, executar a suíte de testes de automação contra eles e, por fim, gerar os relatórios.

O foco deste planejamento é validar a aplicação dentro deste ecossistema automatizado. Este plano servirá como guia para a análise, criação de cenários, mapeamento de issues e o desenvolvimento da automação com **Robot Framework**, que será o motor de testes dentro do pipeline de CI.
-->
Este documento detalha o plano de testes para a aplicação **Cinema Challenge**, que consiste em uma API REST (back-end) e uma interface web (front-end). O back-end será acessível localmente (ex: `http://localhost:3000/`) e o front-end também (ex: `http://localhost:8080/`).

O foco deste planejamento é garantir a qualidade, a conformidade com as regras de negócio e a estabilidade de todos os componentes da aplicação, incluindo os endpoints da API (Usuários, Login, Filmes, Theaters, Sessões, Reservas) e os fluxos de usuário na interface. Este plano servirá como guia para a análise, a criação de cenários, o mapeamento de issues e, principalmente, para o desenvolvimento do projeto de automação de testes de caixa preta de ambos os lados da aplicação com **Robot Framework** e bibliotecas auxiliares.

## 2. Objetivo

O objetivo principal é validar de forma sistemática a aplicação Cinema Challenge, tanto em sua camada de serviço (API) quanto na de apresentação (UI), para garantir que ela opere suas funcionalidades conforme o esperado.

### Objetivos Específicos:

* Validar o **CRUD completo** do endpoint de `/users`.
* Verificar o processo de **autenticação** e validar o comportamento esperado do **CRUD completo** no endpoint `/auth` e suas rotas ramificadas.
* Validar o **CRUD completo** do endpoint de `/movies`, incluindo as restrições de acesso por perfil (admin).
* Validar o **CRUD completo** do endpoint de `/theaters`, incluindo as restrições de autenticação.
* Validar os **fluxos completos** dos endpoints de `/sessions` e `/reservations`.
* Validar os **principais fluxos de usuário na interface web (front-end)**, como login, visualização de filmes, seleção de assentos, reserva e pagamento.
* Garantir que todas as **regras de negócio** e critérios de aceitação sejam atendidos em ambas as camadas.
* Identificar, documentar e reportar quaisquer divergências (**issues**) entre o comportamento esperado e o real no repositório do GitHub.
* Produzir um **projeto de automação de testes robusto e bem estruturado com Robot Framework**.

## 3. Escopo

### Funcionalidades em Escopo:

* **Back-end (API):**
    * **Usuários (`/users`):** CRUD (POST, GET, PUT).
    * **Autenticação (`/login`):** Login (POST).
    * **Registro (`/register`):** Criação de usuário (POST).
    * **Perfil do Usuário (`/me`, `/profile`):** Visualizar perfil (GET), Atualizar perfil (PUT).
    * **Filmes (`/movies`):** CRUD completo (POST, GET, PUT, DELETE).
    * **Theaters (`/theaters`):** CRUD completo (POST, GET, PUT, DELETE).
    * **Sessões (`/sessions`):** CRUD completo (POST, GET, PUT, DELETE).
    * **Reservas (`/reservations`):** CRUD completo (POST, GET, PUT, DELETE).
* **Front-end (UI):**
    * Fluxo de Login de usuário.
    * Visualização da lista de filmes na Home.
    * Visualização da página de detalhes de um filme.
    * Fluxo de seleção de assentos.
    * Fluxo de checkout e reserva.
    * Visualização de "Minhas Reservas".

<!-- ### Fora de Escopo:

* Testes de performance, carga ou estresse.
* Testes de usabilidade e acessibilidade aprofundados no front-end.
* Testes de infraestrutura ou segurança aprofundados. -->

## 4. Análise

A análise será baseada na comparação direta entre os resultados obtidos nos testes automatizados (API e UI) e o comportamento esperado. Serão avaliados:

* **Status Codes HTTP:** (API) Conformidade com os padrões REST.
* **Corpo da Resposta (Response Body):** (API) Validação da estrutura do JSON e dos dados retornados.
* **Comportamento da Interface:** (UI) Renderização de componentes, navegação entre telas e atualização de dados.
* **Regras de Negócio:** Validação de lógicas específicas (ex: apenas admin pode cadastrar filme, etc.).

## 5. Técnicas Aplicadas

* **Teste Baseado em Especificação:** Uso das User Stories e do Mapa Mental da API.
* **Análise de Valor Limite:** Para campos com restrições.
* **Particionamento de Equivalência:** Para campos com regras (ex: formato do e-mail).
* **Teste de Transição de Estado:** Para validar fluxos sequenciais no front-end e na API (Ex: Login -> Ver Sessões -> Criar Reserva).
* **Teste de Robustez (Fuzzing):** Envio de dados malformados ou inesperados nos endpoints da API para validar o tratamento de erros.

## 6. Ambiente e Recursos de Teste

### Local dos Testes
* Ambiente de desenvolvimento local.
<!--* Ambiente em nuvem com Integração com o Github Actions.-->

### Ambiente de Testes (Hardware e Software)
* **Sistema Operacional:** Windows 11 (ou similar)
* **Hardware:** PC (Intel i5, 12GB RAM, 64 bits ou similar)
* **Software:**
    * Framework de Teste: **Robot Framework**
    * Bibliotecas: `robotframework-requests` (API), `robotframework-browser` (UI), `robotframework-faker`, `robotframework-jsonlibrary`, `pytest`
    * Editor de Código: VS Code
    * Controle de Versão: Git / GitHub
    * Gerenciamento de Testes: Jira

### Recursos Necessários
* **Humanos:** 1 Analista de Qualidade.
* **Equipamentos:** Computador com acesso à internet.

## 7. Mapa Mental da Aplicação (Estrutura da API)

O mapa mental da API, fornecido pelo usuário (arquivo `cinema-challenge.jpg`), é a referência visual para a arquitetura dos endpoints. Ele detalha todas as rotas, os métodos HTTP correspondentes e as regras de autorização (necessidade de token e permissões de administrador).

```bash
CinemaApp API
├─── Auth
│    ├─── POST /login
│    ├─── POST /register
│    ├─── GET  /me                   *
│    ├─── PUT  /profile              *
│
├─── Users
│    ├─── POST /users
│    ├─── GET /users                 *
│    ├─── GET /users/{id}            *
│    ├─── PUT /users/{id}            *
│    └─── DELETE /users/{id}         *!
│
├─── Movies
│    ├─── POST /movies               *!
│    ├─── GET /movies
│    ├─── GET /movies/{id}
│    ├─── PUT /movies/{id}           *!
│    └─── DELETE /movies/{id}        *!
│
├─── Theaters
│    ├─── POST /theaters             *
│    ├─── GET /theaters
│    ├─── GET /theaters/{id}
│    ├─── PUT /theaters/{id}         *
│    └─── DELETE /theaters/{id}      *
│
├─── Sessions
│    ├─── POST /sessions             *!
│    ├─── GET /sessions
│    ├─── GET /sessions/{id}
│    ├─── PUT /sessions/{id}         *!
│    └─── DELETE /sessions/{id}      *!
│
└─── Reservations
     ├─── POST /reservations         *
     ├─── GET /reservations          *
     ├─── GET /reservations/{id}     *
     ├─── PUT /reservations/{id}     *
     └─── DELETE /reservations/{id}  *

------------------------------------------
Legenda:
(*)   Rota precisa de Token de Autenticação
(!)   Rota exclusiva para usuários Admin
(*!)  Rota Autenticada e de Admin
------------------------------------------
```
<div align="center">
  <img src="assets/mindmap.png" alt="Mapa Mental da API" width="600">
</div>

*(Referência: `mindmap.png`)*

## 8. Cenários de Teste Detalhados (BDD/Gherkin)

Esta seção final detalha os casos de teste derivados diretamente das Histórias de Usuário (US) e seus respectivos Critérios de Aceitação. Cada caso de teste possui um ID único (CTC) para rastreabilidade no Jira e no projeto de automação.

### **Feature: Autenticação (US-AUTH)**

#### US-AUTH-001: Registro de Usuário
**Como** visitante  
**Eu** quero registrar uma nova conta  
**Para** que eu possa reservar ingressos de cinema

**CTC-001:** Registro de novo usuário com sucesso
```gherkin
Dado que eu sou um visitante na página de registro
Quando eu preencho os campos de nome, e-mail (único) e senha com dados válidos
E clico no botão de registrar
Então o sistema deve criar a nova conta
E eu devo ser redirecionado para a página de login ou para a home já autenticado
```

**CTC-002:** Tentativa de registro com e-mail já existente
```gherkin
Dado que o e-mail "usuario.existente@teste.com" já está cadastrado
E eu estou na página de registro
Quando eu preencho o formulário com o e-mail "usuario.existente@teste.com"
E clico no botão de registrar
Então o sistema deve exibir uma mensagem de erro informando que o e-mail já está em uso
E o registro não deve ser concluído
```

**CTC-003:** Tentativa de registro com formato de e-mail inválido
```gherkin
Dado que eu sou um visitante na página de registro
Quando eu preencho o campo de e-mail com o valor "email-invalido"
E preencho os outros campos com dados válidos
E clico no botão de registrar
Então o sistema deve exibir uma mensagem de erro sobre o formato do e-mail
E o registro não deve ser concluído
```

#### US-AUTH-002: Login de Usuário
**Como** usuário registrado  
**Eu** quero fazer login na minha conta  
**Para** que eu possa acessar recursos personalizados

**CTC-004:** Login com credenciais válidas
```gherkin
Dado que eu sou um usuário registrado e estou na página de login
Quando eu insiro meu e-mail e senha corretos
E clico no botão de login
Então o sistema deve me autenticar com sucesso
E eu devo ser redirecionado para a página inicial
E um token JWT deve ser armazenado no localStorage do navegador
```

**CTC-005:** Tentativa de login com senha incorreta
```gherkin
Dado que eu sou um usuário registrado e estou na página de login
Quando eu insiro meu e-mail correto e uma senha incorreta
E clico no botão de login
Então o sistema deve exibir uma mensagem de erro de "credenciais inválidas"
E eu devo permanecer na página de login
```

#### US-AUTH-003: Logout de Usuário
**Como** usuário logado  
**Eu** quero sair da minha conta  
**Para** que minha sessão seja encerrada

**CTC-006:** Logout de usuário autenticado
```gherkin
Dado que eu sou um usuário logado no sistema
Quando eu clico na opção "Sair" no menu de navegação
Então o token JWT deve ser removido do localStorage
E eu devo ser redirecionado para a página de login ou inicial (como visitante)
```

**CTC-007:** Tentativa de acesso a rota protegida após logout
```gherkin
Dado que eu realizei o logout da minha conta
Quando eu tento acessar a URL da página "Minhas Reservas" diretamente
Então o sistema deve me redirecionar para a página de login
E eu não devo conseguir visualizar a página de reservas
```

#### US-AUTH-004: Visualizar e Gerenciar Perfil do Usuário
**Como** usuário logado  
**Eu** quero visualizar e atualizar minhas informações de perfil  
**Para** que eu possa manter meus dados atualizados

**CTC-008:** Visualizar informações do perfil
```gherkin
Dado que eu sou um usuário logado no sistema
Quando eu acesso a minha página de perfil
Então eu devo ver meu nome, e-mail e função (role) corretamente exibidos
```

**CTC-009:** Atualizar nome do perfil com sucesso
```gherkin
Dado que eu estou na minha página de perfil
Quando eu edito o campo "Nome Completo" com um novo valor
E clico no botão "Salvar Alterações"
Então o sistema deve exibir uma mensagem de confirmação de sucesso
E o novo nome deve ser exibido na página
```

### **Feature: Filmes e Sessões (US-MOVIE, US-SESSION)**

#### US-MOVIE-001: Navegar na Lista de Filmes
**Como** usuário (visitante ou autenticado)  
**Eu** quero navegar pelos filmes disponíveis  
**Para** que eu possa descobrir filmes para assistir

**CTC-010:** Visualizar lista de filmes em cartaz
```gherkin
Dado que eu acesso a página inicial da aplicação
Quando eu rolo a tela até a seção "Filmes em Cartaz"
Então eu devo ver uma lista de filmes em formato de grid
E cada filme deve exibir seu pôster, título, classificação e gêneros
```

**CTC-011:** Acessar detalhes de um filme a partir da lista
```gherkin
Dado que eu estou visualizando a lista de filmes em cartaz
Quando eu clico no card de um filme específico
Então eu devo ser redirecionado para a página de detalhes daquele filme
```

#### US-MOVIE-002: Visualizar Detalhes do Filme
**Como** usuário (visitante ou autenticado)  
**Eu** quero visualizar informações detalhadas sobre um filme  
**Para** que eu possa decidir se quero assisti-lo

**CTC-012:** Visualizar informações detalhadas de um filme
```gherkin
Dado que eu estou na página de detalhes de um filme
Então eu devo visualizar a sinopse, elenco, diretor, data de lançamento e duração do filme
E o pôster do filme deve ser exibido
E uma lista de horários de sessões disponíveis deve ser mostrada
```

#### US-SESSION-001: Visualizar Horários de Sessões
**Como** usuário (visitante ou autenticado)  
**Eu** quero visualizar horários para um filme específico  
**Para** que eu possa planejar quando assisti-lo

**CTC-013:** Navegar para seleção de assentos a partir de um horário
```gherkin
Dado que eu estou na página de detalhes de um filme
Quando eu clico em um horário de sessão disponível
Então eu devo ser redirecionado para a página de seleção de assentos para aquela sessão
E a página deve exibir a data, hora e cinema da sessão escolhida
```

### **Feature: Reservas (US-RESERVE)**

#### US-RESERVE-001: Selecionar Assentos para Reserva
**Como** usuário logado  
**Eu** quero selecionar assentos para uma sessão de filme  
**Para** que eu possa reservar minha localização preferida

**CTC-014:** Selecionar assentos disponíveis
```gherkin
Dado que eu sou um usuário logado e estou na página de seleção de assentos
Quando eu clico em um ou mais assentos marcados como "disponível"
Então os assentos selecionados devem mudar de cor para "selecionado"
E o subtotal da compra deve ser atualizado para refletir o número de assentos
```

**CTC-015:** Tentativa de selecionar assento já reservado
```gherkin
Dado que eu estou na página de seleção de assentos
Quando eu clico em um assento marcado como "ocupado"
Então o estado do assento não deve ser alterado
E o subtotal da compra não deve ser modificado
```

#### US-RESERVE-002: Processo de Checkout
**Como** usuário logado  
**Eu** quero finalizar o processo de compra dos ingressos  
**Para** que eu possa garantir minha reserva

**CTC-016:** Finalizar uma reserva com sucesso
```gherkin
Dado que eu selecionei meus assentos e cliquei para prosseguir
Quando eu sou redirecionado para a página de checkout
E eu seleciono um método de pagamento
E clico em "Confirmar Reserva"
Então o sistema deve processar o pagamento (simulado)
E uma confirmação visual de sucesso da reserva deve ser exibida
```

**CTC-017:** Verificar se assentos ficam ocupados após reserva
```gherkin
Dado que eu completei uma reserva para a sessão do filme X às 19:00
Quando eu (ou outro usuário) acesso novamente a seleção de assentos para a mesma sessão
Então os assentos que eu reservei devem estar marcados como "ocupado" e não podem ser selecionados
```

#### US-RESERVE-003: Visualizar Minhas Reservas
**Como** usuário logado  
**Eu** quero visualizar meu histórico de reservas  
**Para** que eu possa verificar minhas reservas

**CTC-018:** Acessar e visualizar histórico de reservas
```gherkin
Dado que eu sou um usuário logado e possuo reservas anteriores
Quando eu clico no link "Minhas Reservas" no menu
Então eu devo ser redirecionado para a página de histórico de reservas
E devo ver uma lista de cards, cada um representando uma reserva
E cada card deve exibir o pôster do filme, data, horário, assentos e status da reserva
```

### **Feature: Experiência do Usuário e Navegação (US-HOME, US-NAV)**

#### US-HOME-001: Página Inicial Atrativa
**Como** usuário (visitante ou autenticado)  
**Eu** quero ter uma visão geral e atrativa da aplicação ao entrar na página inicial  
**Para** que eu possa navegar facilmente e entender os serviços oferecidos

**CTC-019:** Verificar elementos da página inicial para visitante
```gherkin
Dado que eu sou um visitante acessando a página inicial
Então eu devo ver um banner principal
E a seção "Filmes em Cartaz"
E um cabeçalho com links de navegação para Login e Registro
```

**CTC-020:** Verificar elementos da página inicial para usuário autenticado
```gherkin
Dado que eu sou um usuário logado acessando a página inicial
Então eu devo ver um banner principal e a seção "Filmes em Cartaz"
E um cabeçalho com links de navegação para "Minhas Reservas" e "Perfil"
```

#### US-NAV-001: Navegação Intuitiva
**Como** usuário da aplicação  
**Eu** quero navegar facilmente entre as diferentes seções do site  
**Para** que eu possa encontrar rapidamente as informações e funcionalidades que preciso

**CTC-021:** Verificar consistência do cabeçalho de navegação
```gherkin
Dado que eu estou navegando pela aplicação
Quando eu acesso diferentes páginas como a Home, Detalhes de um Filme e Perfil
Então o cabeçalho principal de navegação deve estar sempre visível no topo da página
```

**CTC-022:** Verificar responsividade do menu de navegação
```gherkin
Dado que eu estou acessando a aplicação
Quando eu redimensiono a janela do navegador para uma largura de dispositivo móvel
Então o menu de navegação principal deve se transformar em um menu "hambúrguer" (ícone de menu)
E ao clicar no ícone, as opções de navegação devem ser exibidas
```
### Feature: Gerenciamento de Salas (Theaters)
(Derivado diretamente do Mapa Mental da API e Escopo do Projeto)

**CTC-023_API** (API): Listar todas as salas (Theaters) com sucesso

```gherkin
Dado que existem salas de cinema cadastradas no banco de dados
Quando eu envio uma requisição GET para o endpoint "/theaters"
Então a resposta deve ter o status code 200
E o corpo da resposta deve ser uma lista (array) contendo todas as salas
```

**CTC-024_API** (API): Buscar uma sala (Theater) por ID existente

```gherkin
Dado que existe uma sala com um ID conhecido
Quando eu envio uma requisição GET para o endpoint "/theaters/{id_da_sala}"
Então a resposta deve ter o status code 200
E o corpo da resposta deve conter os dados da sala específica (ex: nome, capacidade)
```

**CTC-025_API** (API): Tentar buscar uma sala (Theater) por ID inexistente

```gherkin
Dado que um ID de sala não existe no banco de dados
Quando eu envio uma requisição GET para o endpoint "/theaters/{id_inexistente}"
Então a resposta deve ter o status code 404
E o corpo da resposta deve conter uma mensagem de "Sala não encontrada"
```

**CTC-026_API** (API): Criar uma nova sala (Theater) com sucesso (requer auth)

```gherkin
Dado que eu estou autenticado com um token de usuário válido
E eu tenho um payload com dados válidos de uma nova sala (ex: nome "Sala 5", capacidade 150)
Quando eu envio uma requisição POST para o endpoint "/theaters" com esse payload
Então a resposta deve ter o status code 201
E o corpo da resposta deve conter os dados da sala recém-criada
```

**CTC-027_API** (API): Tentar criar uma nova sala (Theater) sem autenticação

```gherkin
Dado que eu não estou autenticado
Quando eu envio uma requisição POST para o endpoint "/theaters" com dados de uma nova sala
Então a resposta deve ter o status code 401
E o corpo da resposta deve conter uma mensagem de erro de "Não autorizado"
```

**CTC-028_API** (API): Atualizar uma sala (Theater) existente com sucesso (requer auth)

```gherkin
Dado que eu estou autenticado com um token de usuário válido
E existe uma sala com um ID conhecido
Quando eu envio uma requisição PUT para "/theaters/{id_da_sala}" com um novo nome
Então a resposta deve ter o status code 200
E o corpo da resposta deve conter os dados da sala com o nome atualizado
```

**CTC-029_API** (API): Tentar atualizar uma sala (Theater) sem autenticação

```gherkin
Dado que eu não estou autenticado
E existe uma sala com um ID conhecido
Quando eu envio uma requisição PUT para "/theaters/{id_da_sala}" com novos dados
Então a resposta deve ter o status code 401
E o corpo da resposta deve conter uma mensagem de erro de "Não autorizado"
```

**CTC-030_API** (API): Deletar uma sala (Theater) existente com sucesso (requer auth)

```gherkin
Dado que eu estou autenticado com um token de usuário válido
E existe uma sala com um ID conhecido (que não possui sessões futuras atreladas)
Quando eu envio uma requisição DELETE para o endpoint "/theaters/{id_da_sala}"
Então a resposta deve ter o status code 200 (ou 204 No Content)
E a sala não deve mais ser encontrada em uma busca por ID
```

**CTC-031_API** (API): Tentar deletar uma sala (Theater) sem autenticação

```gherkin
Dado que eu não estou autenticado
E existe uma sala com um ID conhecido
Quando eu envio uma requisição DELETE para o endpoint "/theaters/{id_da_sala}"
Então a resposta deve ter o status code 401
E o corpo da resposta deve conter uma mensagem de erro de "Não autorizado"
```

## 9. Priorização da Execução dos Cenários de Teste

| Prioridade | Critérios de Seleção | Exemplos de Cenários Priorizados |
|------------|---------------------|-----------------------------------|
| **ALTA** | Testes de Caminho Feliz e funcionalidades críticas que habilitam outros testes. | Login (API/UI), Cadastro de Filme (API), Listagem de Filmes (API/UI). |
| **MÉDIA** | Testes de regras de negócio negativas e validações de permissão. | Tentar cadastrar filme como usuário comum, tentar avaliar o mesmo filme duas vezes. |
| **BAIXA** | Testes de casos de borda e validações de campos específicos. | Testar limites de caracteres em campos de texto, enviar tipos de dados incorretos na API. |

## 10. Matriz de Risco

| Risco Identificado | Impacto | Probabilidade | Plano de Contingência |
|-------------------|---------|---------------|----------------------|
| Ambiente local instável ou com bugs | Alto | Média | Isolar o problema (front, back, automação). Reportar issues claras no GitHub. Conteinerizar as partes da aplicação|
| Dados de teste inconsistentes entre execuções | Médio | Média | Criar usuários e filmes via API no Setup de cada suíte/teste para garantir um estado limpo. |
| Mudanças na aplicação sem aviso prévio | Médio | Baixa | Manter comunicação com os desenvolvedores. Focar em seletores de elementos (locators) robustos no UI. |

## 11. Cobertura de Testes

### 11.1 Cobertura por Requisitos (Regras de Negócio)
O objetivo é atingir 100% de cobertura das regras de negócio implícitas e explícitas da aplicação, como as permissões de admin, a unicidade de avaliações por usuário/filme, etc.

### 11.2 Cobertura por Endpoints e Métodos HTTP (API)
**[SEÇÃO ATUALIZADA]**

Esta métrica garante que todas as rotas e verbos HTTP disponíveis na API, conforme o mapa mental, sejam exercitados.

| Rota | Método | Coberto |
|------|--------|--------|
| /auth/login | POST | Sim |
| /users | GET, POST, PUT, DELETE | Sim |
| /movies | GET, POST, PUT, DELETE | Sim |
| /theaters | GET, POST, PUT, DELETE | Sim |
| /sessions | GET, POST, PUT, DELETE | Sim |
| /reservations | GET, POST, PUT, DELETE | Sim |

### 11.3 Cobertura por Fluxos de Usuário (UI)

| Fluxo de Usuário | Coberto |
|------------------|--------|
| Login | Sim |
| Visualização da Home com Filmes | Sim |
| Acesso à Página de Detalhes | Sim |
| Seleção de Assentos e Reserva | Sim |
| Visualização de "Minhas Reservas" | Sim |

## 12. Estratégia de Automação (Robot Framework)

A automação será o entregável principal, utilizando Robot Framework para cobrir tanto a API quanto a UI.

**Estrutura do Projeto:** O projeto seguirá padrões de boas práticas como Page Objects para a automação de UI e Service Objects (camada de keywords para a API), separando a lógica de teste da implementação técnica.

**Bibliotecas:**
- **RequestsLibrary:** Para todas as interações com a API REST.
- **BrowserLibrary:** Para a automação dos fluxos no navegador web.
- **FakerLibrary:** Para geração de massa de dados dinâmica e única.
- **JSONLibrary:** Para manipulação de arquivos JSON.

**Estratégia de Execução:**
- **Testes de API primeiro:** A automação da API será priorizada por ser mais rápida e estável. Ela será usada para criar o estado necessário para os testes de UI (ex: criar um usuário, um filme e uma sessão via API antes de testar a reserva via UI).
- **Testes de UI focados em fluxos:** Os testes de UI validarão os caminhos críticos do usuário, integrando as diferentes telas da aplicação.
- **Independência dos Testes:** Serão usadas rotinas de Suite Setup e Suite Teardown para garantir que os dados de teste sejam criados e destruídos a cada execução, evitando que um teste interfira no outro.