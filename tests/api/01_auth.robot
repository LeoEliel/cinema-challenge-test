*** Settings ***
Documentation    Suíte de testes de API para a feature de Autenticação.
...              Cobre os casos de teste da US-AUTH-001 (Registro).
...              Testes de API são marcados com a tag 'API'.
...              --
...              Dado que eu possuo dados válidos de um novo usuário (nome, e-mail único, senha)
...              Quando eu envio uma requisição POST para o endpoint "/auth/register" com esses dados
...              Então a resposta deve ter o status code 201
...              E o corpo da resposta deve conter os dados do usuário criado (sem a senha)

Resource    ../../resources/common.resource 

Suite Setup       API Test Setup
Test Teardown     Clean Up Test User From Fixture

*** Test Cases ***
CTC-001_API (API): Registro de novo usuário com sucesso pela API
    [Tags]    API    Smoke    US-AUTH-001
    
    # Caminho para SEU arquivo JSON
    ${fixtures_file}    Set Variable     ../../fixtures/payloads.json
    
    # 1. Carrega TODO o JSON e seleciona o bloco deste teste
    ${json_data}=             Load Json From File    ${fixtures_file}    encoding=UTF-8
    ${test_data_block}        Set Variable           ${json_data['ctc-001_api]}

    # 2. Extrai o payload de usuário específico deste bloco
    ${payload}        Set Variable    ${test_data_block['user']}
    
    # Guarda para o Teardown
    Set Test Variable   ${USER_EMAIL_TO_CLEAN}   ${payload['email']} 

    # 3. Executa a ação
    ${response}=    POST Register    payload=${payload}

    # 4. Valida
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=201
    ...    schema_path=../../schemas/auth/register_response.json

    ${body}=    Set Variable    ${response.json()}
    Should Be Equal As Strings    ${body['data']['name']}      ${payload['name']}
    Should Be Equal As Strings    ${body['data']['email']}     ${payload['email']}

*** Keywords ***
Clean Up Test User From Fixture
    Run Keyword If    '${USER_EMAIL_TO_CLEAN}' != '${None}'
    ...    Remove User And Related Data    ${USER_EMAIL_TO_CLEAN}