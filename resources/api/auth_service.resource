*** Settings ***
Documentation    Keywords de serviço para a API de Autenticação (Auth)
...
...    Este resource implementa o padrão Service Objects.
...    Ele contém keywords para interagir com os endpoints /auth/login e /auth/register.

Resource    ../common.resource

*** Keywords ***
POST Login
    [Documentation]    Envia uma requisição POST para /auth/login e retorna a resposta.
    [Arguments]    ${payload}

    ${response}=    POST On Session
    ...    api                     # Nome da sessão que criamos no common.resource
    ...    /auth/login             # Endpoint
    ...    json=${payload}          # O corpo (body) da requisição
    ...    expected_status=any     # Não queremos que o teste falhe aqui, vamos validar no teste

    RETURN    ${response}

POST Register
    [Documentation]    Envia uma requisição POST para /auth/register e retorna a resposta.
    [Arguments]    ${payload}

    ${response}=    POST On Session
    ...    api
    ...    /auth/register          # <-- Endpoint correto para registro
    ...    json=${payload}
    ...    expected_status=any     # <-- Validaremos o status no teste

    RETURN    ${response}