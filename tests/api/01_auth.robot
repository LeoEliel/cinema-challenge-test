*** Settings ***
Documentation    Suíte de testes de API para a feature de Autenticação.
...              Cobre os casos de teste da US-AUTH-001 (Registro).
...              Testes de API são marcados com a tag 'API'.

Resource    ../../resources/common.resource 

Test Setup       API Test Setup
Test Teardown     API Test Teardown For User Collection    ${MOVIE_ID_LIST}

*** Test Cases ***
CTC-001_API (API): Registro de novo usuário com sucesso pela API
    [Tags]    API    Smoke    US-AUTH-001    CTC-001_API
    [Documentation]
...              Dado que eu possuo dados válidos de um novo usuário (nome, e-mail único, senha)
...              Quando eu envio uma requisição POST para o endpoint "/auth/register" com esses dados
...              Então a resposta deve ter o status code 201
...              E o corpo da resposta deve conter os dados do usuário criado (sem a senha)

    ${fixture}        Get Fixture From Collection   users    valid_user_register
    ${endpoint}            Set Variable    /auth/register
    
    Set Test Variable    ${MOVIE_ID_LIST}    ${fixture}[email]
    
    # Garante que usuário a ser inserido não existe
    Remove User And Related Data    ${MOVIE_ID_LIST}

    # 3. Registra o usuário
    ${response}    Register User    ${fixture}

    # 4. Valida
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=201
    ...    schema_file=users_valid_user_register.schema.json

    ${body}=    Set Variable    ${response.json()}
    Should Be Equal As Strings    ${body}[data][name]      ${fixture}[name]
    Should Be Equal As Strings    ${body}[data][email]     ${fixture}[email]

CTC-002_API (API): Tentativa de registro com e-mail já existente
    [Tags]    API    Negative    US-AUTH-001    CTC-002_API
    [Documentation]
    ...              Dado que o e-mail "duplicado.static@test.cinema.com" já está cadastrado
    ...              Quando eu envio uma requisição POST para "/auth/register" com o mesmo e-mail
    ...              Então a resposta deve ter o status code 400 (ou 409)
    ...              E o corpo da resposta deve conter a mensagem "User already exists"

    # Carrega os dados do fixture para a *tentativa* de registro
    ${fixture}        Get Fixture From Collection   users    user_for_duplicate_email_test
    
    # 1. Dado (Given) - Usuário duplicado existe (feito abaixo Setup)
    Set Test Variable    ${MOVIE_ID_LIST}    ${fixture}[email]
    Remove User And Related Data    ${MOVIE_ID_LIST}
    ${user_id}        Insert User Directly Into DB    ${fixture}
    Should Not Be Equal    ${USER_ID}    ${EMPTY}

    # 2. Quando (When) - Tenta registrar novamente com o mesmo email
    ${response}=    Register User    ${fixture}

    # 3. Então (Then) - Valida o erro
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=400
    ...    schema_file=register_duplicate_email_error.schema.json

CTC-003_API (API): Tentativa de registro com formato de e-mail inválido
    [Tags]    API    Negative    US-AUTH-001    CTC-003_API
    [Documentation]
    ...              Dado que eu tenho um payload de registro com email mal formatado
    ...              Quando eu envio uma requisição POST para "/auth/register"
    ...              Então a resposta deve ter o status code 400
    ...              E o corpo da resposta deve conter uma mensagem de erro sobre o formato do e-mail
    
    # 1. Dado (Given) - Carrega os dados do fixture com email inválido
    ${fixture}        Get Fixture From Collection   users    user_with_invalid_email_format

    Set Test Variable    ${MOVIE_ID_LIST}    ${EMPTY}

    # 2. Quando (When) - Tenta registrar com o payload inválido
    ${response}=    Register User    ${fixture}
    
    ${expected_errors_dict}        Create Dictionary    email=Please provide a valid email

    # 3. Então (Then) - Valida o erro 400
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=400
    ...    expected_error_message=Validation failed
    ...    expected_errors_dict=${expected_errors_dict}
    ...    schema_file=register_invalid_email_error.schema.json

CTC-004_API (API): Login com credenciais válidas pela API
    [Tags]    API    Smoke    US-AUTH-002    CTC-004_API
    [Documentation]
    ...              Dado que eu tenho as credenciais de um usuário válido
    ...              Quando eu envio uma requisição POST para o endpoint "/auth/login"
    ...              Então a resposta deve ter o status code 200
    ...              E o corpo da resposta deve conter um "accessToken"
    # [Setup]     # REMOVIDO o [Setup] específico

    # --- SETUP INLINE ---
    # 1. Dado (Given) - Garante que o usuário para login exista
    ${fixture}=    Get Fixture From Collection   users    valid_user_register
    Set Test Variable        ${MOVIE_ID_LIST}     ${fixture}[email]
    
    # Pré-limpeza
    Remove User And Related Data    ${fixture}[email] 

    ${user_id}=    Insert User Directly Into DB    ${fixture}
    
    Should Not Be Equal    ${USER_ID}    ${EMPTY}    msg=Falha ao inserir usuário pré-requisito para login no DB
    
    Log    Usuário pré-requisito para login ${fixture}[email] inserido com ID ${USER_ID}
    # --- FIM DO SETUP INLINE ---

    # Monta o payload específico para login (apenas email e senha)
    &{login_payload}=    Create Dictionary
    ...    email=${fixture}[email]
    ...    password=${fixture}[password]

    # 2. Quando (When) - Envia a requisição de login
    ${response}=    Login User   ${login_payload}

    # 3. Então (Then) - Valida a resposta de sucesso
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=200
    ...    schema_file=login_success_response.schema.json

CTC-005_API (API): Tentativa de login com credenciais inválidas pela API
    [Tags]    API    Negative    US-AUTH-002    CTC-005_API
    [Documentation]
    ...              Dado que eu tenho as credenciais de um usuário com senha incorreta
    ...              Quando eu envio uma requisição POST para o endpoint "/auth/login"
    ...              Então a resposta deve ter o status code 401
    ...              E o corpo da resposta deve conter uma mensagem de "Invalid email or password"

    # --- SETUP INLINE ---
    # Carrega os dados do fixture que será usado como base (usuário válido)
    ${fixture_user_data}=    Get Fixture From Collection   users    valid_user_register
    # Define o e-mail que será limpo pelo Teardown padrão
    Set Test Variable        ${MOVIE_ID_LIST}     ${fixture_user_data}[email]
    # Garante que o usuário de teste exista, limpando qualquer versão anterior
    Remove User And Related Data    ${fixture_user_data}[email]
    # Insere o usuário de teste diretamente no banco de dados
    ${user_id}=    Insert User Directly Into DB    ${fixture_user_data}
    # Verifica se a inserção no banco de dados foi bem-sucedida
    Should Not Be Equal    ${USER_ID}    ${EMPTY}    msg=Falha ao inserir usuário pré-requisito para teste de login inválido no DB
    # Log para registrar a criação do usuário de pré-requisito
    Log    Usuário pré-requisito ${fixture_user_data}[email] inserido com ID ${USER_ID}
    # --- FIM DO SETUP INLINE ---

    # Monta o payload (credenciais) para a tentativa de login usando o e-mail correto e uma senha inválida
    &{login_credentials}=    Get Fixture From Collection    users    login_invalid_password

    # Envia a requisição de login usando a keyword correta do serviço de autenticação
    ${response}=    Login User    credentials=${login_credentials}

    # Valida a resposta de erro recebida da API
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=401
    ...    schema_file=login_invalid_credentials_error.schema.json

CTC-007_API (API): Tentativa de acesso a rota protegida com token inválido
    [Tags]    API    Negative    US-AUTH-003    CTC-007_API
    [Documentation]
    ...              Dado que eu tenho um token de autenticação inválido
    ...              Quando eu tento enviar uma requisição GET para a rota protegida "/auth/me" com esse token
    ...              Então a resposta deve ter o status code 401
    ...              E o corpo da resposta deve conter a mensagem "Not authorized to access this route"
    # Sobrescreve o Setup padrão
    Set Test Variable    ${INVALID_TOKEN}    Bearer INVALIDTOKEN
    # Sobrescreve o Teardown padrão
    [Teardown]  No Operation

    # Loga o token inválido que será utilizado
    Log    Usando token inválido: ${INVALID_TOKEN}

    # Monta o dicionário de Headers que será enviado na requisição
    &{invalid_auth_token}=    Create Dictionary    Authorization=${INVALID_TOKEN}

    # **AÇÃO ATUALIZADA:** Envia a requisição GET usando a nova keyword do serviço
    # Passamos apenas os headers, pois é o que define a autenticação neste teste
    ${response}=    Get User Profile    headers=${invalid_auth_token}

    # Valida se a API retornou o erro 401 Unauthorized esperado
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=401
    ...    schema_file=unauthorized_error_response.schema.json

CTC-008_API (API): Visualizar informações do perfil pela API com sucesso
    [Tags]    API    Smoke    US-AUTH-004    CTC-008_API
    [Documentation]
    ...              Dado que eu estou autenticado com um token de usuário válido
    ...              Quando eu envio uma requisição GET para o endpoint "/auth/me"
    ...              Então a resposta deve ter o status code 200
    ...              E o corpo da resposta deve conter meu nome, e-mail e função (role) dentro do objeto 'data'


    [Setup]    Setup User And Get Valid Token

    # Monta o dicionário de Headers com o token VÁLIDO obtido no Setup Inline
    &{headers}=    Create Dictionary    Authorization=Bearer ${VALID_TOKEN}

    # Envia a requisição GET para buscar o perfil usando a keyword do serviço de autenticação
    ${response}=    Get User Profile    headers=${headers}

    # Valida se a API retornou sucesso (200 OK) e se a estrutura da resposta está correta
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=200
    ...    schema_file=get_profile_response.schema.json

    # Extrai o corpo da resposta JSON para validações de valor
    ${body}=    Set Variable    ${response.json()}

    # Valida se os valores retornados dentro do objeto 'data' correspondem aos dados do usuário criado
    Should Be Equal As Strings    ${body['data']['_id']}      ${USER_ID}
    Should Be Equal As Strings    ${body['data']['name']}      ${fixture_user_data}[name]
    Should Be Equal As Strings    ${body['data']['email']}     ${fixture_user_data}[email]
    # Assume que o usuário criado no setup tem a role 'user'
    Should Be Equal As Strings    ${body['data']['role']}      user

CTC-009_API (API): Atualizar nome do perfil pela API com sucesso
    [Tags]    API    Smoke    US-AUTH-004    CTC-009_API
    [Documentation]
    ...              Dado que estou autenticado com um token de usuário válido
    ...              Quando envio uma requisição PUT para "/auth/profile" com um novo nome e senha atual
    ...              Então a resposta deve ter o status code 200
    ...              E o corpo da resposta deve conter os dados atualizados com o novo nome
    
    # --- SETUP INLINE (Preparação dos dados para a Ação) ---

    # Reutiliza setup para ter usuário e token válidos (${VALID_TOKEN})
    [Setup]     Setup User And Get Valid Token

    # Gera um novo nome dinâmico para garantir a atualização
    ${novo_nome}=        FakerLibrary.Name

    # Pega nova senha dinâmica
    ${nova_senha}=        FakerLibrary.Password

    # Cria o payload para PUT /auth/profile
    &{update_payload}=    Create Dictionary
    ...    name=${novo_nome}
    ...    newPassword=${nova_senha}

    # Monta os Headers com o token VÁLIDO obtido no Setup
    &{auth_headers}=    Create Dictionary    Authorization=Bearer ${VALID_TOKEN}
    # --- FIM SETUP INLINE ---

    # Envia a requisição PUT para atualizar o perfil
    ${response}=    Update User Profile    payload=${update_payload}    headers=${auth_headers}

    # Valida se a API retornou sucesso (200 OK) e se a estrutura está correta
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=200
    ...    schema_file=update_profile_response.schema.json

    # Extrai o corpo da resposta para validações de valor
    ${body}=    Set Variable    ${response.json()}

    # Valida se o nome retornado DENTRO de 'data' é o NOVO nome enviado
    Should Be Equal As Strings    ${body['data']['name']}    ${novo_nome}
    # Valida se outro campo email permaneceu inalterado
    Should Be Equal As Strings    ${body['data']['email']}   ${fixture_user_data}[email]


CTC-009_NEGATIVE_INVALID_NAME_API (API): Tentativa de atualizar perfil com nome vazio (API aceita mas não altera)
    [Tags]    API    Negative    US-AUTH-004    CTC-009_Negative    InvalidData    NonStrictValidation
    [Documentation]
    ...              Dado que estou autenticado com um token de usuário válido
    ...              Quando envio uma requisição PUT para "/auth/profile" com 'name' vazio
    ...              Então a resposta deve ter o status code 200 # API não rejeita
    ...              E o corpo da resposta deve conter os dados do usuário com o nome *original* inalterado
    # Reutiliza setup para ter usuário (${fixture_user_data}) e token válidos (${VALID_TOKEN})
    [Setup]     Setup User And Get Valid Token

    # --- SETUP INLINE (Preparação dos dados para a Ação) ---
    # Define o payload com o nome VAZIO.
    &{update_payload_invalid_name}=    Create Dictionary    name=${EMPTY}
    # Monta os Headers com o token VÁLIDO obtido no Setup
    &{auth_headers}=              Create Dictionary    Authorization=Bearer ${VALID_TOKEN}
    # Guarda o nome ORIGINAL para validação posterior
    ${fixture_user_data}=         Get Fixture From Collection   users    valid_user_register
    ${original_name}=             Set Variable                  ${fixture_user_data}[name]
    # --- FIM SETUP INLINE ---

    # Envia a requisição PUT para tentar atualizar o perfil com nome inválido
    ${response}=    Update User Profile    payload=${update_payload_invalid_name}    headers=${auth_headers}

    # Valida se a API retornou 200 OK e se a estrutura da resposta está correta (schema de sucesso)
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=200
    ...    schema_file=update_profile_response.schema.json

    # Extrai o corpo da resposta para validação de valor
    ${body}=    Set Variable    ${response.json()}

    # *** VALIDAÇÃO CRUCIAL ***
    # Verifica se o nome retornado DENTRO de 'data' é o nome ORIGINAL, e NÃO o vazio
    Should Be Equal As Strings    ${body['data']['name']}    ${original_name}    msg=API aceitou nome vazio, mas o nome retornado deveria ser o original!
    Log    Verificado: Nome do usuário (${body['data']['name']}) permaneceu inalterado após tentativa de atualização com nome vazio.

    # Opcional: Validar outros campos
    Should Be Equal As Strings    ${body['data']['_id']}   ${USER_ID}
    Should Be Equal As Strings    ${body['data']['email']}   ${fixture_user_data}[email]
    Should Be Equal As Strings    ${body['data']['role']}    user

CTC-009_NEGATIVE_FORBIDDEN_FIELD_API (API): Tentativa de atualizar campos proibidos (email, role)
    [Tags]    API    Negative    US-AUTH-004    CTC-009_Negative    ForbiddenField    NonStrictValidation
    [Documentation]
    ...              Dado que estou autenticado com um token de usuário válido
    ...              Quando envio uma requisição PUT para "/auth/profile" tentando alterar 'email' e 'role'
    ...              Então a resposta deve ter o status code 200 # API não rejeita
    ...              E o corpo da resposta deve conter os dados do usuário com email e role *originais* inalterados
    # Reutiliza setup para ter usuário (${fixture_user_data}) e token válidos (${VALID_TOKEN})
    [Setup]     Setup User And Get Valid Token

    # --- SETUP INLINE (Preparação dos dados para a Ação) ---
    # Define valores "proibidos" que tentaremos enviar
    ${novo_email_proibido}=    FakerLibrary.Email
    ${nova_role_proibida}=     Set Variable    admin
    
    # Pega os dados ORIGINAIS do fixture para comparação posterior
    ${fixture_user_data}=     Get Fixture From Collection   users    valid_user_register
    ${original_email}=        Set Variable                  ${fixture_user_data}[email]
    
    # Role padrão do usuário criado no setup
    ${original_role}=         Set Variable                  user 

    # Cria o payload tentando alterar campos permitidos (name) e proibidos (email, role)
    ${nome_permitido}=        FakerLibrary.Name
    &{update_payload_forbidden}=    Create Dictionary
    ...    name=${nome_permitido}          # Campo permitido
    ...    email=${novo_email_proibido}    # Campo PROIBIDO
    ...    role=${nova_role_proibida}      # Campo PROIBIDO

    # Monta os Headers com o token VÁLIDO obtido no Setup
    &{auth_headers}=              Create Dictionary    Authorization=Bearer ${VALID_TOKEN}
    # --- FIM SETUP INLINE ---

    # Envia a requisição PUT para tentar atualizar o perfil com campos proibidos
    ${response}=    Update User Profile    payload=${update_payload_forbidden}    headers=${auth_headers}

    # Valida se a API retornou 200 OK e se a estrutura da resposta está correta (schema de sucesso)
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=200
    ...    schema_file=update_profile_response.schema.json

    # Extrai o corpo da resposta para validação de valor
    ${body}=    Set Variable    ${response.json()}

    # *** VALIDAÇÃO CRUCIAL ***
    # Verifica se os campos proibidos ('email' e 'role') retornados são os ORIGINAIS
    Should Be Equal As Strings    ${body['data']['email']}    ${original_email}    msg=API aceitou payload com email proibido, mas o email retornado deveria ser o original!
    Should Be Equal As Strings    ${body['data']['role']}     ${original_role}     msg=API aceitou payload com role proibida, mas a role retornada deveria ser a original!
    Log    Verificado: Email (${body['data']['email']}) e Role (${body['data']['role']}) permaneceram inalterados.

    # Valida se o campo permitido ('name') FOI atualizado corretamente
    Should Be Equal As Strings    ${body['data']['name']}     ${nome_permitido}    msg=O campo 'name' permitido não foi atualizado como esperado.