*** Settings ***
Documentation    Keywords de serviço para a API de Autenticação (Auth)
...
...    Este resource implementa o padrão Service Objects.
...    Ele contém keywords para interagir com os endpoints de autenticação.

Resource    ../common.resource

*** Keywords ***
# AUTH SERVICE OBJECTS - Específicos do domínio de Autenticação

Register User
    [Documentation]    Registra um novo usuário no sistema.
    [Arguments]        ${user_data}    ${headers}=&{EMPTY}
    
    ${response}=    POST To    /auth/register    ${user_data}    ${headers}
    RETURN    ${response}

Login User
    [Documentation]    Autentica um usuário no sistema.
    [Arguments]        ${credentials}    ${headers}=&{EMPTY}
    
    ${response}=    POST To    /auth/login    ${credentials}    ${headers}
    RETURN    ${response}

Refresh Auth Token
    [Documentation]    Renova o token de autenticação.
    [Arguments]        ${refresh_token}    ${headers}=&{EMPTY}
    
    ${payload}=    Create Dictionary    refreshToken=${refresh_token}
    ${response}=    POST To    /auth/refresh    ${payload}    ${headers}
    RETURN    ${response}

Logout User
    [Documentation]    Faz logout do usuário.
    [Arguments]        ${headers}=&{EMPTY}
    
    ${response}=    POST To    /auth/logout    ${EMPTY}    ${headers}
    RETURN    ${response}