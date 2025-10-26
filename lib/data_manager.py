from robot.api.deco import keyword
from pymongo import MongoClient, errors
from bson.objectid import ObjectId
import bcrypt
import os

# Configuração da Conexão
MONGO_URI = os.environ.get('MONGO_URI', 'mongodb://localhost:27017/')
MONGO_DB_NAME = os.environ.get('MONGO_DB_NAME', 'cinema-app')

def _get_db_connection():
    """Estabelece conexão com MongoDB."""
    try:
        client = MongoClient(MONGO_URI)
        client.admin.command('ping')
        print(f"Conectado ao MongoDB: {MONGO_URI}, Banco: {MONGO_DB_NAME}")
        return client, client[MONGO_DB_NAME]
    except errors.ConnectionFailure as e:
        print(f"ERRO: Não foi possível conectar ao MongoDB: {e}")
        raise ConnectionError(f"Falha ao conectar ao MongoDB: {e}")

client, db = _get_db_connection()

# KEYWORDS DE GERENCIAMENTO DE CONEXÃO

@keyword('Close MongoDB Connection')
def close_mongodb_connection():
    """Fecha a conexão com o MongoDB."""
    try:
        if client:
            client.close()
            print("-> Conexão com MongoDB fechada com sucesso.")
        else:
            print("-> Nenhuma conexão ativa encontrada.")
    except Exception as e:
        print(f"ERRO ao fechar conexão MongoDB: {e}")

# KEYWORDS DE REMOÇÃO
@keyword('Remove User And Related Data')
def remove_user_and_related_data(email: str):
    """Remove usuário pelo email e suas reservas associadas."""
    print(f"Tentando remover usuário e dados relacionados para: {email}")
    try:
        users_collection = db['users']
        reservations_collection = db['reservations']

        user = users_collection.find_one({'email': email})

        if user:
            user_id = user['_id']
            # Remove reservas primeiro
            delete_reservations_result = reservations_collection.delete_many({'user': user_id})
            print(f"-> Removidas {delete_reservations_result.deleted_count} reservas associadas.")

            # Remove usuário
            delete_user_result = users_collection.delete_one({'_id': user_id})
            if delete_user_result.deleted_count > 0:
                print(f"-> Usuário {email} removido com sucesso.")
            else:
                print(f"-> AVISO: Usuário {email} encontrado mas não pôde ser removido.")
        else:
            print(f"-> Usuário {email} não encontrado no banco de dados.")

    except Exception as e:
        print(f"ERRO durante a remoção do usuário {email}: {e}")

@keyword('Remove Movie By ID')
def remove_movie_by_id(movie_id_str: str):
    """Remove filme pelo _id."""
    print(f"Tentando remover filme com ID: {movie_id_str}")
    try:
        movies_collection = db['movies']
        result = movies_collection.delete_one({'_id': ObjectId(movie_id_str)})
        if result.deleted_count > 0:
            print(f"-> Filme {movie_id_str} removido com sucesso.")
        else:
            print(f"-> Filme {movie_id_str} não encontrado para remoção.")
    except Exception as e:
        print(f"ERRO durante a remoção do filme {movie_id_str}: {e}")

@keyword('Remove Theater By ID')
def remove_theater_by_id(theater_id_str: str):
    """Remove sala pelo _id."""
    print(f"Tentando remover sala com ID: {theater_id_str}")
    try:
        theaters_collection = db['theaters']
        result = theaters_collection.delete_one({'_id': ObjectId(theater_id_str)})
        if result.deleted_count > 0:
            print(f"-> Sala {theater_id_str} removida com sucesso.")
        else:
            print(f"-> Sala {theater_id_str} não encontrada para remoção.")
    except Exception as e:
        print(f"ERRO durante a remoção da sala {theater_id_str}: {e}")

@keyword('Remove Session By ID')
def remove_session_by_id(session_id_str: str):
    """Remove sessão pelo _id."""
    print(f"Tentando remover sessão com ID: {session_id_str}")
    try:
        sessions_collection = db['sessions']
        result = sessions_collection.delete_one({'_id': ObjectId(session_id_str)})
        if result.deleted_count > 0:
            print(f"-> Sessão {session_id_str} removida com sucesso.")
        else:
            print(f"-> Sessão {session_id_str} não encontrada para remoção.")
    except Exception as e:
        print(f"ERRO durante a remoção da sessão {session_id_str}: {e}")

@keyword('Remove Reservation By ID')
def remove_reservation_by_id(reservation_id_str: str):
    """Remove reserva pelo _id."""
    print(f"Tentando remover reserva com ID: {reservation_id_str}")
    try:
        reservations_collection = db['reservations']
        result = reservations_collection.delete_one({'_id': ObjectId(reservation_id_str)})
        if result.deleted_count > 0:
            print(f"-> Reserva {reservation_id_str} removida com sucesso.")
        else:
            print(f"-> Reserva {reservation_id_str} não encontrada para remoção.")
    except Exception as e:
        print(f"ERRO durante a remoção da reserva {reservation_id_str}: {e}")

# KEYWORDS DE INSERÇÃO
@keyword('Insert User Directly Into DB (Use With Caution)')
def insert_user_directly(user: dict):
    """Insere usuário diretamente no banco. Use com cautela - prefira API."""
    print(f"Tentando inserir usuário diretamente no DB: {user.get('email')}")
    try:
        salt_rounds = 10
        hashed_password = bcrypt.hashpw(user['password'].encode('utf-8'), bcrypt.gensalt(salt_rounds))

        doc = {
            "name": user['name'],
            "email": user['email'],
            "password": hashed_password,
        }

        users_collection = db['users']
        insert_result = users_collection.insert_one(doc)
        inserted_id = insert_result.inserted_id
        print(f"-> Usuário inserido diretamente com _id: {inserted_id}")
        return str(inserted_id)

    except KeyError as e:
        print(f"ERRO: Campo obrigatório faltando no dicionário 'user': {e}")
        raise ValueError(f"Payload do usuário inválido: {e}")
    except Exception as e:
        print(f"ERRO durante a inserção direta do usuário {user.get('email')}: {e}")
        raise e

# KEYWORDS DE BUSCA
@keyword('Get User Id by Email')
def get_user_id_by_email(email: str):
    """Busca usuário pelo email e retorna _id como string."""
    print(f"Buscando ID do usuário com email: {email}")
    try:
        users_collection = db['users']
        user = users_collection.find_one({'email': email})
        if user:
            user_id = str(user['_id'])
            print(f"-> Usuário encontrado com ID: {user_id}")
            return user_id
        else:
            print(f"-> Usuário {email} não encontrado.")
            return None
    except Exception as e:
        print(f"ERRO ao buscar usuário {email}: {e}")
        raise e

@keyword('Get Movie Id By Title')
def get_movie_id_by_title(title: str):
    """Busca filme pelo título e retorna _id como string."""
    print(f"Buscando _id do filme com título: {title}")
    try:
        movies_collection = db['movies']
        movie = movies_collection.find_one({'title': title})
        if movie:
            movie_id = str(movie['_id'])
            print(f"-> Filme encontrado. _id: {movie_id}")
            return movie_id
        else:
            print(f"-> Filme com título {title} não encontrado.")
            return None
    except Exception as e:
        print(f"ERRO ao buscar filme {title}: {e}")
        return None

@keyword('Get Theater Id By Name')
def get_theater_id_by_name(name: str):
    """Busca sala pelo nome e retorna _id como string."""
    print(f"Buscando _id da sala com nome: {name}")
    try:
        theaters_collection = db['theaters']
        theater = theaters_collection.find_one({'name': name})
        if theater:
            theater_id = str(theater['_id'])
            print(f"-> Sala encontrada. _id: {theater_id}")
            return theater_id
        else:
            print(f"-> Sala com nome {name} não encontrada.")
            return None
    except Exception as e:
        print(f"ERRO ao buscar sala {name}: {e}")
        return None

# # KEYWORDS DE CLEANUP
# @keyword('Cleanup Test Users By Email Domain')
# def cleanup_test_users_by_email_domain(domain: str = "@test.cinema.com"):
#     """Remove todos os usuários com email terminado no domínio especificado."""
#     print(f"Iniciando cleanup geral de usuários com domínio: {domain}")
#     try:
#         users_collection = db['users']
#         reservations_collection = db['reservations']

#         test_users = list(users_collection.find({'email': {'$regex': f'{domain}$'}}))

#         if not test_users:
#             print("-> Nenhum usuário de teste encontrado para limpar.")
#             return

#         print(f"-> Encontrados {len(test_users)} usuários de teste para remover.")

#         for user in test_users:
#             user_id = user['_id']
#             email = user['email']
#             reservations_collection.delete_many({'user': user_id})
#             users_collection.delete_one({'_id': user_id})
#             print(f"--> Usuário {email} e suas reservas removidos.")

#         print("Cleanup geral de usuários finalizado.")

#     except Exception as e:
#         print(f"ERRO durante o cleanup geral de usuários: {e}")