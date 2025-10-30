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
    [Arguments]        ${user_data}=&{EMPTY}
    
    ${response}=    POST To    endpoint=/auth/register    json=${user_data}
    RETURN    ${response}

Login User
    [Documentation]    Autentica um usuário no sistema.
    [Arguments]        ${credentials}=&{EMPTY}
    
    ${response}=    POST To    endpoint=/auth/login    json=${credentials}
    RETURN    ${response}


# Logout User
#     [Documentation]    Faz logout do usuário.
#     [Arguments]        ${headers}=&{EMPTY}
    
#     ${response}=    POST To    endpoint=/auth/logout    headers=${headers}
#     RETURN    ${response}

Get User Profile
    [Documentation]    Retorna profile do usuário atualmente logado.
    [Arguments]    ${headers}

    ${response}=    GET From    endpoint=/auth/me    headers=${headers}
    RETURN    ${response}

Update User Profile
    [Documentation]    Atualiza os dados do perfil do usuário autenticado (PUT /auth/profile).
    [Arguments]    ${payload}    ${headers}

    ${response}=    PUT To    endpoint=/auth/profile    json=${payload}    headers=${headers}
    RETURN    ${response}
