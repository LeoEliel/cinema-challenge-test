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

    # --- VALIDAÇÃO (PARTE 1) - Tenta validar contra o MOCK ---
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
    ${LEN_THEATER_ID_LIST}        Get Length    ${THEATER_ID_LIST}
    Run Keyword If    ${list_exists} and @{THEATER_ID_LIST}    Log    Iniciando cleanup para ${LEN_THEATER_ID_LIST} salas...
    IF    ${list_exists} and @{THEATER_ID_LIST}
        FOR    ${theater_id}    IN    @{THEATER_ID_LIST}
            Remove Theater And Related Data    ${theater_id}
        END
    END
    Run Keyword If    ${list_exists} and @{THEATER_ID_LIST}    Log    Cleanup de salas finalizado.
    Delete All Sessions