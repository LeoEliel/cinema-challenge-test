*** Settings ***
Documentation    Suíte de testes de API para a feature de Salas (Theaters).
...              Cobre casos de teste públicos e de admin para /theaters.

Resource    ../../resources/common.resource
Resource    ../../resources/api/theaters_service.resource

Test Setup        API Test Setup
Test Teardown     API Test Teardown For Theater Collection

*** Variables ***
${THEATER_FIXTURES}       ../../fixtures/theaters.json
${THEATER_SCHEMA_LIST}    list_theaters_response.schema.json
${THEATER_SCHEMA_DETAIL}  get_movie_details_response.schema.json
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
    ...    schema_file=${THEATER_SCHEMA_LIST} # Schema que já corrigimos

    # Validação Extra
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal As Strings    ${body['count']}    1    msg=A contagem total deveria ser 1.
    Length Should Be            ${body['data']}    1    msg=A lista 'data' deveria conter 1 sala.
    # Valida se a sala retornada é a correta (a VIP com nome específico)
    Should Be Equal As Strings    ${body['data'][0]['name']}    SALA_TESTE_FILTRO_C_VIP

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
    ${LEN_THEATER_ID_LIST}    Get Length    @{THEATER_ID_LIST}
    Run Keyword If    ${list_exists} and @{THEATER_ID_LIST}    Log    Iniciando cleanup para ${LEN_THEATER_ID_LIST} salas...
    IF    ${list_exists} and @{THEATER_ID_LIST}
        FOR    ${theater_id}    IN    @{THEATER_ID_LIST}
            Remove Theater And Related Data    ${theater_id}
        END
    END
    Run Keyword If    ${list_exists} and @{THEATER_ID_LIST}    Log    Cleanup de salas finalizado.
    Delete All Sessions