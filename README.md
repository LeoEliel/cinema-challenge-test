Projeto de Automação de Testes - Cinema Challenge (PB AWS & AI for QE)

Este projeto contém a automação de testes de API para a aplicação "Cinema Challenge", desenvolvido com Robot Framework, Python e uma arquitetura focada em escalabilidade, reutilização e isolamento.

## Apresentação Pessoal

* **Nome:** [Seu Nome Completo]
* **Idade:** [Sua Idade]
* **Curso:** [Seu Curso]
* **Semestre:** [Seu Semestre]
* **Cidade:** [Sua Cidade]
* *(Opcional: Descrição de aparência, conforme solicitado no desafio)*
    * **Cor dos Olhos:** [Cor]
    * **Cor dos Cabelos:** [Cor]
    * **Cor da Pele:** [Cor]
    * **Roupa Utilizada:** [Descrição]

---

## 1. Visão Geral e Estratégia

O objetivo deste projeto não foi atingir 100% de cobertura de casos de teste, mas sim construir uma **"fábrica de testes" (framework)** robusta, aderente aos princípios de Engenharia de Qualidade (QE).

A estratégia priorizou a **API-First** e garantiu que cada caso de teste fosse **100% independente e idempotente** (pode rodar várias vezes sem falhar) através de um gerenciamento avançado de setup e teardown.

## 2. Estrutura do Projeto

A arquitetura do framework foi projetada para máxima organização e manutenibilidade:

```
cinema-challenge-test/
├── .github/
│   └── workflows/
│       └── run-tests.yml           # Pipeline de CI/CD (GitHub Actions)
├── fixtures/                       # Massa de dados estática (JSON) por entidade
│   ├── users.json
│   ├── movies.json
│   ├── theaters.json
│   └── sessions.json
├── lib/
│   └── data_manager.py             # Biblioteca Python (pymongo) para Setup/Teardown no DB
├── resources/
│   ├── api/                        # Service Objects (Keywords de Ação da API)
│   │   ├── auth_service.resource
│   │   ├── movies_service.resource
│   │   ├── theaters_service.resource
│   │   └── sessions_service.resource
│   ├── ui/                         # Page Objects (Planejado para UI)
│   │   ├── components/
│   │   └── pages/
│   ├── validation/                 # Keywords de Validação Reutilizáveis
│   │   └── api_validation.resource
│   └── common.resource             # Hub de imports e keywords globais
├── results/                        # Relatórios do Robot (Ignorado pelo .gitignore)
├── schemas/                        # Schemas JSON para validação de contrato da API
│   ├── auth/
│   ├── movies/
│   ├── theaters/
│   └── sessions/
├── tests/
│   ├── api/                        # Suítes de Testes de API (47 casos de teste)
│   │   ├── 01_auth.robot           # 15 casos de teste de autenticação
│   │   ├── 02_movies.robot         # 8 casos de teste de filmes
│   │   ├── 03_theaters.robot       # 19 casos de teste de salas
│   │   └── 04_sessions.robot       # 5 casos de teste de sessões
│   ├── ui/                         # Suítes de Testes de UI (Planejado)
│   └── utils/
│       └── 00_token_generation_test.robot  # 1 caso de teste utilitário
├── variables/
│   └── env_vars.py                 # Variáveis de ambiente (URLs)
├── .gitignore
├── README.md                       # Esta documentação
└── requirements.txt                # Dependências do projeto
```
## 3. Tecnologias, Padrões e Inovação

Este projeto aplica diversos padrões de engenharia e inovação:

* **Padrões de Código:**
    * **Service Objects:** Abstração das chamadas de API (ex: `resources/api/movies_service.resource`).
    * **Page Objects:** Estrutura pronta para os testes de UI (ex: `resources/ui/pages/`).
    * **Testes Independentes:** Cada teste é responsável por criar e destruir seus próprios dados, usando keywords de "bloco de construção" (`Create Test Movie`) e "orquestradoras" (`Setup Para Teste de Filtro de Sessão`).
* **Validação Robusta:**
    * **JSON Schema Validation (`JsonSchemaLibrary`):** Em vez de validar campos individuais, o framework valida o *contrato* completo da API (estrutura, tipos de dados, campos obrigatórios e opcionais) usando os arquivos em `schemas/`.
* **Gerenciamento de Dados Avançado (Inovação):**
    * **`lib/database_manager.py`:** Uma biblioteca Python customizada que usa `pymongo` para se conectar diretamente ao MongoDB.
    * **Setup e Teardown Idempotentes:** Keywords como `Remove Movie And Related Data` garantem a pré-limpeza e a limpeza em cascata (removendo sessões e reservas dependentes), tornando os testes 100% isolados da "sujeira" do banco.
* **Descoberta e Workaround (TDD):**
    * A rota `POST /auth/login` **não autentica Admins**. Isso foi reportado como uma issue [CN-85](LINK_PARA_SUA_ISSUE_AQUI).
    * **Solução (Inovação):** Foi criada a keyword `Generate Admin Token` (em `database_manager.py`) que usa `PyJWT` e a `JWT_SECRET` (via variável de ambiente) para gerar manualmente um token de Admin válido, desbloqueando todos os testes de rotas administrativas.
* **CI/CD (Inovação):**
    * Um pipeline básico do **GitHub Actions** (`.github/workflows/run-tests.yml`) está configurado para rodar os testes de API a cada Pull Request para a branch `dev`.

## 4. Pré-requisitos e Instalação

1.  Clone este repositório:
    ```bash
    git clone [URL_DO_SEU_REPO]
    cd cinema-challenge-test
    ```
2.  Crie e ative um ambiente virtual:
    ```bash
    python -m venv venv
    # Windows: venv\Scripts\activate
    # Mac/Linux: source venv/bin/activate
    ```
3.  Instale as dependências:
    ```bash
    pip install -r requirements.txt
    ```
4.  **Variáveis de Ambiente:** Configure as seguintes variáveis de ambiente no seu sistema (ou em um arquivo `.env` se você adaptar `data_manager.py` para usar `python-dotenv`):
    * `MONGO_URI`: A string de conexão do MongoDB.
    * `MONGO_DB_NAME`: O nome do banco de dados (ex: `cinema-app`).
    * `JWT_SECRET`: A chave secreta do JWT (necessária para a keyword `Generate Admin Token`).

## 5. Como Executar os Testes

**Rodar Todas as Suítes de API:**
```bash
robot -d results tests/api/