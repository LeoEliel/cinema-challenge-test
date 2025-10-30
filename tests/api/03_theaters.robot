*** Settings ***
Documentation    Suíte de testes de API para a feature de Salas (Theaters).
...              Cobre casos de teste públicos e de admin para /theaters.

Resource    ../../resources/common.resource
Resource    ../../resources/api/theaters_service.resource

Test Setup        API Test Setup
Test Teardown     API Test Teardown For Theater Collection

*** Variables ***
#Schemas
${THEATER_FIXTURES}       ../../fixtures/theaters.json
${THEATER_SCHEMA_LIST}          list_theaters_response.schema.json
${THEATER_SCHEMA_DETAIL}        get_theater_details_response.schema.json
${THEATER_NOT_FOUND_SCHEMA}     theater_not_found_error.schema.json
${THEATER_CREATE_SCHEMA}        create_theater_response.schema.json
${THEATER_UPDATE_SCHEMA}        update_theater_response.schema.json
${THEATER_DELETE_SCHEMA}        delete_theater_response.schema.json
${FORBIDDEN_ERROR_SCHEMA}       forbidden_error_response.schema.json
${UNAUTHORIZED_ERROR_SCHEMA}    unauthorized_error_response.schema.json

${NON_EXISTENT_THEATER_ID}      111111111111111111111111
${ADMIN_EMAIL_FIXTURE}          admin@example.com
# ... (outros schemas e variáveis)

*** Test Cases ***
CTC-100_API (API): Listar salas com sucesso (filtrando por tipo e ordenando)
    [Tags]    API    Smoke    Theaters    CTC-100_API
    [Documentation]
    ...              Dado que as salas específicas de teste foram criadas
    ...              Quando envio GET para "/theaters" com filtro "type=VIP"
    ...              Então a resposta deve ter status 200 e conter 1 sala
    # Setup específico: cria as 3 salas do fixture 'three_theaters_for_filtering'
    [Setup]    Setup Theaters For Test    three_theaters_for_filtering

    # Define os query params para buscar a sala "VIP" (a "Sala Teste C")
    ${QUERY_PARAMS}=    Create Dictionary
    ...    type=VIP        # Filtra pelo tipo
    ...    sort=capacity   # Ordena por capacidade
    ...    limit=1
    ...    page=1

    # Ação
    ${response}=    List Theaters    params=${QUERY_PARAMS}

    # Validação
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=200
    ...    schema_file=${THEATER_SCHEMA_LIST}

    # Validação Extra
    #${body}=    Set Variable    ${response.json()}
    #Should Be Equal As Strings    ${body['count']}    1    msg=A contagem total deveria ser 9.
    #Length Should Be            ${body['data']}    1    msg=A lista 'data' deveria conter 1 sala.
    # Valida se a sala retornada é a correta (a VIP com nome específico)
    #Should Be Equal As Strings    ${body['data'][0]['name']}    SALA_TESTE_FILTRO_C_VIP

CTC-23_API (API): Buscar detalhes de sala por ID com sucesso
    [Tags]    API    Smoke    Theaters    CTC-101_API # (Novo CTC-ID de exemplo)
    [Documentation]
    ...              Dado que uma sala específica foi criada
    ...              Quando envio GET para "/theaters/{id_da_sala}"
    ...              Então a resposta deve ter status 200 e conter os detalhes da sala
    # Setup específico: cria 1 sala do fixture 'base_valid_theater'
    [Setup]    Setup Theaters For Test    base_valid_theater

    # Dado (ID do setup)
    ${theater_id_to_get}=    Set Variable    ${THEATER_ID_LIST}[0]

    # Ação
    ${response}=    Get Theater By ID    theater_id=${theater_id_to_get}

    # Validação (PRECISAMOS DO SCHEMA DE DETALHES DE THEATER)
    # Validate Successful API Response
    # ...    response=${response}
    # ...    expected_status_code=200
    # ...    schema_file=get_theater_details_response.schema.json # <-- PENDENTE

    # Validação de Valores
    ${fixture_data}=   Get Fixture From Collection   theaters    base_valid_theater
    ${body}=           Set Variable                  ${response.json()}
    # Ajuste o path se a resposta for {success: true, data: {...}}
    Should Be Equal As Strings    ${body['data']['_id']}      ${theater_id_to_get}
    Should Be Equal As Strings    ${body['data']['name']}      ${fixture_data}[name]
    Should Be Equal As Strings    ${body['data']['type']}      ${fixture_data}[type]

CTC-24_API (API): Buscar detalhes de sala por ID existente
    [Tags]    API    Smoke    Theaters    CTC-24_API    CN-48
    [Documentation]
    ...              Dado que existe uma sala com um ID conhecido
    ...              Quando eu envio uma requisição GET para o endpoint "/theaters/{id_da_sala}"
    ...              Então a resposta deve ter o status code 200
    ...              E o corpo da resposta deve conter os dados da sala específica (e suas sessões)
    # Setup específico: cria 1 sala do fixture 'base_valid_theater'
    [Setup]    Setup Theaters For Test    base_valid_theater

    # Dado (ID do setup)
    # Pega o ID da sala criada na lista @{THEATER_ID_LIST}
    ${theater_id_to_get}=    Set Variable    ${THEATER_ID_LIST}[0]

    # Ação: Chama a keyword do theaters_service
    ${response}=    Get Theater By ID    theater_id=${theater_id_to_get}
    
    Log To Console    ${response}
    # Validação (AGORA PODEMOS USAR A KEYWORD PADRÃO!)
    # A resposta tem o wrapper "success": true, "data": {...}
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=200
    ...    schema_file=${THEATER_SCHEMA_DETAIL}

    # Validações Extras de Valores
    ${fixture_data}=   Get Fixture From Collection   theaters    base_valid_theater
    ${body}=           Set Variable                  ${response.json()}
    Should Be Equal As Strings    ${body['data']['_id']}      ${theater_id_to_get}
    Should Be Equal As Strings    ${body['data']['name']}      ${fixture_data}[name]
    Should Be Equal As Strings    ${body['data']['type']}      ${fixture_data}[type]
    # Valida que as sessões (pelo menos a lista) estão lá
    Dictionary Should Contain Key    ${body['data']}    sessions

CTC-25_API (API): Tentar buscar sala com ID inexistente
    [Tags]    API    Negative    Theaters    CTC-25_API    CN-49
    [Documentation]
    ...              Dado que um ID de sala não existe no banco de dados
    ...              Quando eu envio uma requisição GET para o endpoint "/theaters/{id_inexistente}"
    ...              Então a resposta deve ter o status code 404
    ...              E o corpo da resposta deve conter a mensagem "Theater not found"
    # [Setup] Nenhum [Setup] específico é usado, então o Test Setup padrão (API Test Setup) roda.

    # Cria uma lista vazia para a variável de teardown @{THEATER_ID_LIST}
    # Isso é crucial para que o 'Test Teardown' padrão (API Test Teardown For Theater Collection)
    # rode sem falhar, pois ele espera que essa variável exista.
    @{EMPTY_LIST}=    Create List
    Set Test Variable    @{THEATER_ID_LIST}    @{EMPTY_LIST}

    # Ação: Chama a keyword do theaters_service usando um ID inexistente
    ${response}=    Get Theater By ID    theater_id=${NON_EXISTENT_THEATER_ID}

    # Validação: Usa a keyword de validação de erro e o schema 404
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=404
    ...    schema_file=${THEATER_NOT_FOUND_SCHEMA}

CTC-26_API (API): Admin cria nova sala (Theater) com sucesso
    [Tags]    API    AdminOnly    TheatersCRUD    CTC-26_API    CN-50
    [Documentation]
    ...              Dado que estou autenticado como Admin
    ...              Quando envio POST para "/theaters" com um payload válido
    ...              Então a resposta deve ter status 201 Created
    ...              E o corpo da resposta deve conter a sala criada (com wrapper 'data')
    
    # Setup: Chama a keyword global que gera ${ADMIN_TOKEN_BEARER}
    Generate Admin Token For Test

    # --- PREPARAÇÃO DA AÇÃO ---
    # Carrega o payload base da sala do fixture
    ${fixture_payload}=    Get Fixture From Collection   theaters    base_valid_theater
    # Gera um nome dinâmico
    ${random_suffix}=      Generate Random String    8    [LOWER]
    ${dynamic_name}=       Set Variable              ${fixture_payload}[name] - ${random_suffix}
    ${payload_com_nome_unico}=  Set To Dictionary    ${fixture_payload}    name=${dynamic_name}
    # Monta os headers com o token de Admin
    &{admin_headers}=      Create Dictionary    Authorization=${ADMIN_TOKEN_BEARER}
    # Inicializa a lista de IDs de cleanup
    @{ids_to_clean}=       Create List
    Set Test Variable      @{THEATER_ID_LIST}    @{ids_to_clean}
    # --- FIM PREPARAÇÃO ---

    # Ação: Tenta criar a sala
    ${response}=    Create Theater    payload=${payload_com_nome_unico}    admin_headers=${admin_headers}

    # Validação (CORRIGIDA): Agora usamos a keyword padrão
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=201
    ...    schema_file=${THEATER_CREATE_SCHEMA}

    # Validação Extra de Valores (Acessando dentro de 'data')
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal As Strings    ${body['data']['name']}    ${payload_com_nome_unico}[name]

    # PREPARA O TEARDOWN (CORRIGIDO: Acessando _id dentro de 'data')
    ${created_theater_id}=    Set Variable    ${body['data']['_id']}
    Append To List    ${THEATER_ID_LIST}    ${created_theater_id}
    Set Test Variable    @{THEATER_ID_LIST}

CTC-28_API (API): Admin atualiza sala (Theater) existente com sucesso
    [Tags]    API    AdminOnly    TheatersCRUD    CTC-28_API    CN-53
    [Documentation]
    ...              Dado que estou autenticado como Admin e uma sala existe
    ...              Quando envio PUT para "/theaters/{id_da_sala}" com um novo nome
    ...              Então a resposta deve ter status 200 OK
    ...              E o corpo da resposta deve conter os dados da sala atualizados
    
    # --- SETUP INLINE ---
    # Gera o token de Admin
    Generate Admin Token For Test
    # Monta os headers com o token
    &{admin_headers}=      Create Dictionary    Authorization=${ADMIN_TOKEN_BEARER}

    # Carrega o fixture da sala base
    ${fixture_payload}=    Get Fixture From Collection   theaters    base_valid_theater
    # Garante limpeza prévia (caso tenha sobrado de outro teste)
    Remove Theater And Related Data    ${fixture_payload}[name]
    
    # Insere a sala que será o "alvo" da atualização
    ${theater_id_to_update}=    Insert Theater Directly Into DB    ${fixture_payload}
    Should Not Be Equal    ${theater_id_to_update}    ${None}    msg=Falha ao inserir sala pré-requisito no DB
    Log    Sala alvo para atualização criada com ID: ${theater_id_to_update}

    # Prepara o Teardown para limpar esta sala
    @{ids_to_clean}=       Create List    ${theater_id_to_update}
    Set Test Variable      @{THEATER_ID_LIST}    @{ids_to_clean}
    # --- FIM SETUP INLINE ---

    # --- PREPARAÇÃO DA AÇÃO ---
    # Gera um novo nome dinâmico para a atualização
    ${random_suffix}=      Generate Random String    8    [LOWER]
    ${novo_nome}=          Set Variable              ${fixture_payload}[name] - ATUALIZADA - ${random_suffix}
    # Cria o payload de atualização (apenas com o campo a ser mudado)
    &{update_payload}=     Create Dictionary    name=${novo_nome}
    # --- FIM PREPARAÇÃO ---

    # Ação: Tenta atualizar a sala
    ${response}=    Update Theater
    ...    theater_id=${theater_id_to_update}
    ...    payload=${update_payload}
    ...    admin_headers=${admin_headers}
    
    Log To Console    ${response.json()}

    # Validação (Assumindo wrapper 'success/data' e reutilizando o schema)
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=200
    ...    schema_file=${THEATER_UPDATE_SCHEMA}

    # Validação Extra de Valores (Acessando dentro de 'data')
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal As Strings    ${body['data']['name']}    ${novo_nome}
    # Valida que o ID permaneceu o mesmo
    Should Be Equal As Strings    ${body['data']['_id']}   ${theater_id_to_update}

CTC-030_API (API): Deletar uma sala (Theater) existente com sucesso (requer Admin)
    [Tags]    API    AdminOnly    TheatersCRUD    CTC-30_API    CN-75
    [Documentation]
    ...              Dado que estou autenticado como Admin e uma sala existe
    ...              Quando envio DELETE para "/theaters/{id_da_sala}"
    ...              Então a resposta deve ter status 200 OK (ou 204)
    ...              E o filme não deve mais ser encontrado

    # --- SETUP INLINE ---
    # Gera o token de Admin
    Generate Admin Token For Test
    # Monta os headers com o token
    &{admin_headers}=      Create Dictionary    Authorization=${ADMIN_TOKEN_BEARER}

    # Carrega o fixture da sala base
    ${fixture_payload}=    Get Fixture From Collection   theaters    base_valid_theater
    # Garante limpeza prévia (caso tenha sobrado de outro teste)
    Remove Theater And Related Data    ${fixture_payload}[name]

    # Insere a sala que será o "alvo" da deleção
    ${theater_id_to_delete}=    Insert Theater Directly Into DB    ${fixture_payload}
    Should Not Be Equal    ${theater_id_to_delete}    ${None}    msg=Falha ao inserir sala pré-requisito no DB
    Log    Sala alvo para deleção criada com ID: ${theater_id_to_delete}

    # Prepara o Teardown para limpar esta sala (caso o DELETE falhe)
    @{ids_to_clean}=       Create List    ${theater_id_to_delete}
    Set Test Variable      @{THEATER_ID_LIST}    @{ids_to_clean}
    # --- FIM SETUP INLINE ---

    # Ação: Tenta deletar a sala
    ${response}=    Delete Theater
    ...    theater_id=${theater_id_to_delete}
    ...    admin_headers=${admin_headers}

    # Esperamos 200 OK (se 204, esta keyword falhará, o que também é informativo)
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=200
    ...    schema_file=${THEATER_DELETE_SCHEMA}

    # --- VALIDAÇÃO (PARTE 2) - Se a Parte 1 passar, valida o 404 ---
    Log    Validando se a sala ${theater_id_to_delete} foi realmente deletada...
    ${response_after}=    Get Theater By ID    theater_id=${theater_id_to_delete}
    Validate Error API Response
    ...    response=${response_after}
    ...    expected_status_code=404
    ...    schema_file=${THEATER_NOT_FOUND_SCHEMA}

    # --- LIMPEZA (OPCIONAL) ---
    # Limpa a lista de Teardown, pois o DELETE já funcionou
    @{empty_list}=    Create List
    Set Test Variable    @{THEATER_ID_LIST}    @{empty_list}
    Log    ID da sala removido da lista de cleanup do Teardown (deleção principal bem-sucedida).

CTC-030_NEGATIVE_FORBIDDEN_API (API): Tentar deletar uma sala (Theater) como usuário normal
    [Tags]    API    Negative    AdminOnly    TheatersCRUD    CTC-043_Negative    CN-77
    [Documentation]
    ...              Dado que estou autenticado como usuário NORMAL e uma sala existe
    ...              Quando envio DELETE para "/theaters/{id}" com token de usuário normal
    ...              Então a resposta deve ter status 403 Forbidden
    # [Setup] O setup padrão 'API Test Setup' é executado.

    # --- SETUP INLINE ---
    # 1. Cria um usuário normal e obtém seu token
    # (Reutiliza a keyword global 'Setup User And Get Valid Token' de common.resource)
    Setup User And Get Valid Token
    # Armazena o token e o e-mail para cleanup (a keyword já define ${CLEANUP_EMAIL})
    ${normal_user_token_bearer}=    Set Variable    ${VALID_TOKEN}
    Log    Token de Usuário Normal obtido.

    # 2. Cria uma sala (theater) para ser o alvo
    ${fixture_payload}=    Get Fixture From Collection   theaters    base_valid_theater
    ${random_suffix}=      FakerLibrary.Street Suffix
    ${dynamic_name}=       Set Variable              ${fixture_payload}[name] - ${random_suffix}
    ${payload_sala}=       Set To Dictionary         ${fixture_payload}    name=${dynamic_name}
    ${theater_id_to_delete}=    Insert Theater Directly Into DB    ${payload_sala}
    Should Not Be Equal    ${theater_id_to_delete}    ${None}    msg=Falha ao inserir sala pré-requisito no DB
    Log    Sala alvo para deleção criada com ID: ${theater_id_to_delete}

    # 3. Prepara o Teardown da Sala
    @{ids_to_clean}=       Create List    ${theater_id_to_delete}
    Set Test Variable      @{THEATER_ID_LIST}    @{ids_to_clean}

    # 4. Monta os headers com o token de USUÁRIO NORMAL
    &{normal_user_headers}=    Create Dictionary    Authorization=Bearer ${normal_user_token_bearer}
    # --- FIM SETUP INLINE ---

    # Ação: Tenta deletar a sala usando o token de usuário normal
    ${response}=    Delete Theater
    ...    theater_id=${theater_id_to_delete}
    ...    admin_headers=${normal_user_headers}     # Passando o token normal

    # --- LOG DE DESCOBERTA ---
    # Loga a resposta real ANTES de tentar validar
    #Log To Console    \n\n--- RESPOSTA REAL (CTC-043_API 403) ---\nStatus: ${response.status_code}\nCorpo: ${response.text}\n--------------------------------------\n

    # Validação (ESPERAMOS QUE FALHE AQUI E MOSTRE O ERRO REAL)
    # Tenta validar contra o schema mockado
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=403
    ...    schema_file=${FORBIDDEN_ERROR_SCHEMA}

CTC-043_API (API): Tentar deletar sala como usuário normal (Forbidden)
    [Tags]    API    Negative    AdminOnly    TheatersCRUD    CTC-043_Negative    CN-77
    [Documentation]
    ...              Dado que estou autenticado como usuário NORMAL e uma sala existe
    ...              Quando envio DELETE para "/theaters/{id}" com token de usuário normal
    ...              Então a resposta deve ter status 403 Forbidden
    # Teardown EXPLÍCITO e DUPLO para este teste
    [Teardown]    Run Keywords
    ...           API Test Teardown For Theater Collection     # Limpa a sala
    ...    AND    API Test Teardown For User Collection     # Limpa o usuário

    # --- SETUP INLINE (Usuário) ---
    # Chama a keyword global de common.resource para criar user e token
    Setup User And Get Valid Token
    ${normal_user_token_bearer}=    Set Variable    ${VALID_TOKEN}
    # (Setup User... já define ${CLEANUP_EMAIL} para o teardown)
    
    # --- SETUP INLINE (Sala) ---
    ${fixture_sala}=    Get Fixture From Collection   theaters    base_valid_theater
    ${existing_id}=     Get Theater Id By Name        ${fixture_sala}[name]
    Run Keyword If      '${existing_id}' != '${None}'  Remove Theater And Related Data    ${existing_id}
    ${theater_id}=      Insert Theater Directly Into DB    ${fixture_sala}
    Should Not Be Equal    ${theater_id}    ${None}
    @{ids_to_clean}=    Create List    ${theater_id}
    Set Test Variable    @{THEATER_ID_LIST}    @{ids_to_clean}
    # --- FIM SETUP INLINE ---

    &{normal_user_headers}=    Create Dictionary    Authorization=Bearer ${normal_user_token_bearer}

    ${response}=    Delete Theater
    ...    theater_id=${theater_id}
    ...    admin_headers=${normal_user_headers}

    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=403
    ...    schema_file=${FORBIDDEN_ERROR_SCHEMA}

CN-76 (API): Tentar deletar uma sala (Theater) sem autenticação
    [Tags]    API    Negative    Security    TheatersCRUD    CTC-030_Negative    CN-76
    [Documentation]
    ...              Dado que eu não estou autenticado
    ...              E existe uma sala com um ID conhecido
    ...              Quando eu envio uma requisição DELETE para o endpoint "/theaters/{id_da_sala}"
    ...              Então a resposta deve ter o status code 401
    ...              E o corpo da resposta deve conter uma mensagem de erro de "Não autorizado"
    # Setup específico: cria 1 sala (usando 'base_valid_theater')
    # Esta keyword já define @{THEATER_ID_LIST} para o Teardown
    [Setup]    Setup Theaters For Test    base_valid_theater

    # Dado (Given) - Pega o ID da sala que foi criada no Setup
    ${theater_id_to_delete}=    Set Variable    ${THEATER_ID_LIST}[0]
    Log    Sala alvo para tentativa de DELETE (sem token): ${theater_id_to_delete}

    # Ação: Tenta deletar a sala SEM passar o header 'admin_headers'
    # A keyword 'Delete Theater' (do service) deve lidar com headers=${EMPTY}
    ${response}=    Delete Theater
    ...    theater_id=${theater_id_to_delete}
    ...    admin_headers=${None}     # Envia headers vazios
    
    #Log To Console    ${response.json()}

    # Validação: Usa a keyword de validação de erro e o schema 401
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=401
    ...    schema_file=${UNAUTHORIZED_ERROR_SCHEMA}     # Reutiliza o schema de 401

    # [Teardown] O Teardown padrão ('API Test Teardown For Theater Collection')
    # definido no *** Settings *** rodará automaticamente e limpará a sala
    # que foi criada pelo [Setup], pois @{THEATER_ID_LIST} está definida.

CTC-030_NEGATIVE_NOT_FOUND_API (API): Admin tenta deletar sala com ID inexistente
    [Tags]    API    Negative    AdminOnly    TheatersCRUD    CTC-030_Negative # Adicione ID Jira (ex: CN-90)
    [Documentation]
    ...              Dado que estou autenticado como Admin
    ...              Quando envio DELETE para "/theaters/{id_inexistente}"
    ...              Então a resposta deve ter status 404 Not Found
    ...              E o corpo da resposta deve conter "Theater not found"
    # Setup: Roda o setup padrão E gera o token de Admin
    [Setup]    Run Keywords
    ...    API Test Setup
    ...    AND    Generate Admin Token For Test

    # Cria uma lista vazia para a variável de teardown @{THEATER_ID_LIST}
    # Isso é crucial para que o 'Test Teardown' padrão (API Test Teardown For Theater Collection)
    # rode sem falhar, pois ele espera que essa variável exista.
    @{EMPTY_LIST}=    Create List
    Set Test Variable    @{THEATER_ID_LIST}    @{EMPTY_LIST}

    # Monta os headers com o token de Admin obtido no Setup
    &{admin_headers}=    Create Dictionary    Authorization=${ADMIN_TOKEN_BEARER}

    # Ação: Tenta deletar uma sala usando um ID inexistente
    ${response}=    Delete Theater
    ...    theater_id=${NON_EXISTENT_THEATER_ID}
    ...    admin_headers=${admin_headers}

    # Validação: Usa a keyword de validação de erro e o schema 404
    # Reutiliza o schema 'theater_not_found_error.schema.json'
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=404
    ...    schema_file=${THEATER_NOT_FOUND_SCHEMA}

CN-52 (API): Tentar criar uma nova sala (Theater) como usuário normal
    [Tags]    API    Negative    AdminOnly    TheatersCRUD    CTC-026_Negative    CN-52
    [Documentation]
    ...              Dado que estou autenticado com um token de usuário normal (não-Admin)
    ...              Quando envio uma requisição POST para o endpoint "/theaters" com dados de uma nova sala
    ...              Então a resposta deve ter o status code 403
    ...              E o corpo da resposta deve conter a mensagem "User role user is not authorized to access this route"
    # Setup: Cria um usuário normal e obtém seu token (${VALID_TOKEN})
    # Esta keyword (de common.resource) também define ${CLEANUP_EMAIL} para o teardown
    [Setup]    Setup User And Get Valid Token

    # Cria uma lista vazia para a variável de teardown @{THEATER_ID_LIST}
    # (Necessário para o 'Test Teardown' padrão desta suíte rodar sem erros)
    @{EMPTY_LIST}=    Create List
    Set Test Variable    @{THEATER_ID_LIST}    @{EMPTY_LIST}

    # --- PREPARAÇÃO DA AÇÃO ---
    # Carrega o payload base da sala do fixture
    ${fixture_payload}=    Get Fixture From Collection   theaters    base_valid_theater
    # Monta os headers com o token de USUÁRIO NORMAL obtido no Setup
    &{normal_user_headers}=    Create Dictionary    Authorization=Bearer ${VALID_TOKEN}
    # --- FIM PREPARAÇÃO ---

    # Ação: Tenta criar a sala usando o token de usuário normal
    ${response}=    Create Theater
    ...    payload=${fixture_payload}
    ...    admin_headers=${normal_user_headers}     # Passando o token normal

    # Validação: Usa a keyword de validação de erro e o schema 403
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=403
    ...    schema_file=${FORBIDDEN_ERROR_SCHEMA}     # Reutiliza o schema de 403
    #Log To Console    \n\n--- RESPOSTA REAL (CTC-043_API 403) ---\nStatus: ${response.status_code}\nCorpo: ${response.text}\n--------------------------------------\n
    
    # [Teardown] O Teardown padrão ('Run Keywords ... AND ...') rodará:
    # 1. Cleanup Theaters... (encontrará lista vazia, pulará)
    # 2. Cleanup User... (encontrará ${CLEANUP_EMAIL} do setup, limpará o usuário)

CN-51 (API): Tentar criar uma nova sala (Theater) sem autenticação
    [Tags]    API    Negative    Security    TheatersCRUD    CTC-026_Negative    CN-51
    [Documentation]
    ...              Dado que eu não estou autenticado
    ...              Quando eu envio uma requisição POST para o endpoint "/theaters" com dados de uma nova sala
    ...              Então a resposta deve ter o status code 401
    ...              E o corpo da resposta deve conter uma mensagem de erro de "Não autorizado"
    # [Setup] Nenhum [Setup] específico é usado, então o Test Setup padrão (API Test Setup) roda.

    # --- PREPARAÇÃO DO TEARDOWN ---
    # Garante que as variáveis de limpeza existam e estejam vazias
    # para que o Teardown Padrão da suíte (Run Keywords... AND...) execute sem falhas.
    @{EMPTY_LIST}=    Create List
    Set Test Variable    @{THEATER_ID_LIST}    @{EMPTY_LIST}
    Set Test Variable    ${CLEANUP_EMAIL}      ${None}
    # --- FIM PREPARAÇÃO DO TEARDOWN ---

    # --- PREPARAÇÃO DA AÇÃO ---
    # Carrega o payload base da sala do fixture
    ${fixture_payload}=    Get Fixture From Collection   theaters    base_valid_theater
    # (Não precisamos de nome dinâmico, pois a API deve falhar antes de verificar duplicidade)
    # --- FIM PREPARAÇÃO ---

    # Ação: Tenta criar a sala SEM passar o header 'admin_headers'
    ${response}=    Create Theater
    ...    payload=${fixture_payload}
    ...    admin_headers=${None}     # Envia headers vazios

    # Validação: Usa a keyword de validação de erro e o schema 401
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=401
    ...    schema_file=${UNAUTHORIZED_ERROR_SCHEMA}     # Reutiliza o schema de 401

*** Keywords ***
Setup Theaters For Test
    [Documentation]    Carrega dados do fixture, limpa dados antigos, insere sala(s) via DB
    ...              e armazena os IDs criados na variável de teste @{THEATER_ID_LIST}.
    [Arguments]    ${fixture_key}
    
    API Test Setup
    
    # Carrega os dados do fixture (pode ser um dict ou uma lista de dicts)
    ${fixture_data}=    Get Fixture From Collection    theaters    ${fixture_key}

    # Transforma em lista, mesmo se for um único dict
    @{data_list}=    Run Keyword If    isinstance($fixture_data, list)
    ...    Set Variable    @{fixture_data}
    ...    ELSE
    ...    Create List    ${fixture_data}

    Log    Dados carregados para setup: @{data_list}

    # Garante limpeza prévia (o passo chave!)
    FOR    ${element}    IN    @{data_list}
        ${existing_id}=    Get Theater Id By Name    ${element}[name]
        Run Keyword If    '${existing_id}' != '${None}'    Remove Theater And Related Data    ${existing_id}
    END

    @{ids_created_in_setup}=    Create List

    # Insere as salas via DB
    FOR    ${element}    IN    @{data_list}
        Log    Inserindo Sala no DB: ${element}[name]
        ${id_theater}=    Insert Theater Directly Into DB    ${element}
        Should Not Be Equal    ${id_theater}    ${None}    msg=Falha ao inserir sala '${element}[name]' no DB
        Append To List    ${ids_created_in_setup}    ${id_theater}
    END

    # Define a variável de TESTE para o Teardown
    Set Test Variable    @{THEATER_ID_LIST}    @{ids_created_in_setup}
    Log    IDs das salas criadas para este teste (@{THEATER_ID_LIST}): @{ids_created_in_setup}

API Test Teardown For Theater Collection
    [Documentation]    Remove as salas cujos IDs estão na lista @{THEATER_ID_LIST}.
    ${list_exists}=    Run Keyword And Return Status    Variable Should Exist    @{THEATER_ID_LIST}
    IF    ${list_exists} and @{THEATER_ID_LIST}
        ${LEN_THEATER_ID_LIST}=    Get Length    ${THEATER_ID_LIST}
        Log    Iniciando cleanup para ${LEN_THEATER_ID_LIST} salas...
    END
    IF    ${list_exists} and @{THEATER_ID_LIST}
        FOR    ${theater_id}    IN    @{THEATER_ID_LIST}
            Remove Theater And Related Data    ${theater_id}
        END
        Log    Cleanup de salas finalizado.
    END
    Delete All Sessions

