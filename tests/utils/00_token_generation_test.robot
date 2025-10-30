*** Settings ***
Documentation    Teste rápido para a keyword Generate Admin Token.
...              Verifica se a keyword roda sem erros e retorna um token.
...              Assume que o usuário admin@example.com existe no DB.

Resource    ../../resources/common.resource  # Importa common, que importa o data_manager.py
Test Setup      API Test Setup               # Cria a sessão API (pode não ser necessária aqui)
Suite Teardown   Close MongoDB Connection     # Fecha a conexão DB no final

*** Variables ***
${ADMIN_EMAIL_PARA_TESTE}    admin@example.com

*** Test Cases ***
Verificar Geração de Token de Admin
    [Documentation]    Chama Generate Admin Token e verifica se retorna um token válido (formato Bearer ...).
    [Tags]    Utils    Token

    # Garante que o admin exista (OPCIONAL, mas mais robusto)
    # Poderia usar Insert User Directly aqui se quisesse garantir,
    # mas por agora, vamos assumir que ele existe (como no seu DB).

    ${fixture}    Get Fixture From Collection    users    admin_user_inserted

    Set Test Variable    ${ADMIN_EMAIL_PARA_TESTE}    ${fixture}[email]
    ${admin_id}=    Get User Id by Email    ${ADMIN_EMAIL_PARA_TESTE}
    Should Not Be Equal    ${admin_id}    
    ...    ${None}    msg=Usuário admin ${ADMIN_EMAIL_PARA_TESTE} não encontrado no DB. Setup necessário.

    # Ação: Chama a keyword para gerar o token
    ${admin_token}=    Generate Admin Token    admin_email=${ADMIN_EMAIL_PARA_TESTE}

    # Validações Básicas:
    # 1. Verifica se não é vazio
    Should Not Be Empty    ${admin_token}
    # 2. Verifica se começa com "Bearer "
    Should Start With    ${admin_token}    Bearer
    # 3. Verifica se tem mais do que apenas "Bearer " (um token real)
    ${token_part}=    Split String    ${admin_token}    ${SPACE}    max_split=1
    Should Not Be Empty    ${token_part}[1]
    # 4. Verifica se o token tem um comprimento razoável (JWTs são longos)
    ${token_length}=    Get Length    ${token_part}[1]
    Should Be True    ${token_length} > 50 
    # Um valor arbitrário, JWTs são geralmente > 100 caracteres

    Log    Token de Admin gerado com sucesso: ${admin_token}
    # Guarda para ver no log
    Set Suite Variable    ${GENERATED_ADMIN_TOKEN_FOR_DEBUG}    ${admin_token}     
