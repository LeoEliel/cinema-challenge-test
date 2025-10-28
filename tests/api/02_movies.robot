*** Settings ***
Documentation    Suíte de testes de API para a feature de Filmes (Movies).
...              Cobre casos de teste das US-MOVIE-001 e US-MOVIE-002.

Resource    ../../resources/common.resource

Test Setup       API Test Setup
Test Teardown    API Test Teardown For Movie Collection

*** Variables ***
#${MOVIE_SCHEMA_DETAIL_FILE}    get_movie_details_response.schema.json

*** Test Cases ***
CTC-010_API (API): Listar filmes com sucesso (sem filtros)
    [Tags]    API    Smoke    US-MOVIE-001    CTC-010_API
    [Documentation]
    ...              Dado que existem filmes cadastrados
    ...              Quando envio uma requisição GET para "/movies"
    ...              Então a resposta deve ter o status code 200
    ...              E o corpo da resposta deve ser uma lista paginada de filmes
        
    # Setup: Garante que há filmes cadastrados via API
    ${payload}    Get Fixture From Collection    movies    three_base_valid_movies

    Log    ${payload}

    Set Test Variable    ${id_movie}    ${EMPTY}
    
    @{MOVIE_ID_LIST}    Create List
    Set Test Variable    @{MOVIE_ID_LIST}

    FOR    ${index}    ${element}    IN ENUMERATE    @{payload}        
        Log    Inserindo no DB >>> ${index}: ${element}
        ${id_movie}    Insert Movie Directly Into DB    ${element}
        Append To List    ${MOVIE_ID_LIST}    ${id_movie}    
    END
    

    #Editar dict na keyword para adicionar e/ou retirar pares chave-valor
    ${QUERY_PARAMS}        Create Dictionary    
    ...              title=Fixture Movie Title Out Of Three With Duration: 100       #string    
    ...              genre=Three Movies Genre                                        #string
    ...              sort=duration                                                   #string
    ...              limit=3                                                         #integer
    ...              page=1                                                          #integer

    # Ação: Chama a keyword do movies_service
    ${response}=    List Movies    params=${QUERY_PARAMS}

    # Validação: Usa a keyword de validação e o schema correto
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=200
    ...    schema_file=list_movies_response.schema.json

    # Validação Extra: Verifica se a lista 'data' não está vazia (pois o Setup criou um filme)
    ${body}=    Set Variable    ${response.json()}
    
    Should Not Be Empty    ${body['data']}    
    ...    msg=A lista de filmes retornada está vazia, mas o Setup deveria ter criado dados.
    
    Log    Lista de filmes retornada com ${body['count']} itens no total.
    Evaluate   ${body['count']} == 3    