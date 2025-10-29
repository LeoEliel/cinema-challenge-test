from robot.api.deco import keyword
from pymongo import MongoClient, errors
from bson.objectid import ObjectId
import bcrypt
import os
import jwt
from datetime import datetime, timedelta, timezone # <-- Para expiração para geração de tokens!

# Configuração da Conexão
MONGO_URI = os.environ.get('MONGO_URI', 'mongodb://localhost:27017/')
MONGO_DB_NAME = os.environ.get('MONGO_DB_NAME', 'cinema-app')
JWT_SECRET = os.environ.get('JWT_SECRET', 'seu_jwt_secret_aqui') # <-- Use variável de ambiente!

# KEYWORDS DE GERENCIAMENTO DE CONEXÃO
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

@keyword('Remove Session And Related Data')
def remove_session_and_related_data(session_id_str: str):
    """Remove sessão e suas reservas associadas."""
    print(f"Tentando remover sessão e dados relacionados para: {session_id_str}")
    try:
        sessions_collection = db['sessions']
        reservations_collection = db['reservations']
        
        session_id = ObjectId(session_id_str)
        
        # Remove reservas da sessão primeiro
        delete_reservations_result = reservations_collection.delete_many({'session': session_id})
        print(f"-> Removidas {delete_reservations_result.deleted_count} reservas associadas.")
        
        # Remove sessão
        delete_session_result = sessions_collection.delete_one({'_id': session_id})
        if delete_session_result.deleted_count > 0:
            print(f"-> Sessão {session_id_str} removida com sucesso.")
        else:
            print(f"-> Sessão {session_id_str} não encontrada para remoção.")
            
    except Exception as e:
        print(f"ERRO durante a remoção da sessão {session_id_str}: {e}")

@keyword('Remove Movie And Related Data')
def remove_movie_and_related_data(movie_id_str: str):
    """Remove filme, suas sessões e reservas associadas."""
    print(f"Tentando remover filme e dados relacionados para: {movie_id_str}")
    try:
        movies_collection = db['movies']
        sessions_collection = db['sessions']
        reservations_collection = db['reservations']
        
        movie_id = ObjectId(movie_id_str)
        
        # Busca sessões do filme
        sessions = list(sessions_collection.find({'movie': movie_id}))
        session_ids = [session['_id'] for session in sessions]
        
        # Remove reservas das sessões
        if session_ids:
            delete_reservations_result = reservations_collection.delete_many({'session': {'$in': session_ids}})
            print(f"-> Removidas {delete_reservations_result.deleted_count} reservas associadas.")
        
        # Remove sessões do filme
        delete_sessions_result = sessions_collection.delete_many({'movie': movie_id})
        print(f"-> Removidas {delete_sessions_result.deleted_count} sessões associadas.")
        
        # Remove filme
        delete_movie_result = movies_collection.delete_one({'_id': movie_id})
        if delete_movie_result.deleted_count > 0:
            print(f"-> Filme {movie_id_str} removido com sucesso.")
        else:
            print(f"-> Filme {movie_id_str} não encontrado para remoção.")
            
    except Exception as e:
        print(f"ERRO durante a remoção do filme {movie_id_str}: {e}")

@keyword('Remove Theater And Related Data')
def remove_theater_and_related_data(theater_id_str: str):
    """Remove sala, suas sessões e reservas associadas."""
    print(f"Tentando remover sala e dados relacionados para: {theater_id_str}")
    try:
        theaters_collection = db['theaters']
        sessions_collection = db['sessions']
        reservations_collection = db['reservations']
        
        theater_id = ObjectId(theater_id_str)
        
        # Busca sessões da sala
        sessions = list(sessions_collection.find({'theater': theater_id}))
        session_ids = [session['_id'] for session in sessions]
        
        # Remove reservas das sessões
        if session_ids:
            delete_reservations_result = reservations_collection.delete_many({'session': {'$in': session_ids}})
            print(f"-> Removidas {delete_reservations_result.deleted_count} reservas associadas.")
        
        # Remove sessões da sala
        delete_sessions_result = sessions_collection.delete_many({'theater': theater_id})
        print(f"-> Removidas {delete_sessions_result.deleted_count} sessões associadas.")
        
        # Remove sala
        delete_theater_result = theaters_collection.delete_one({'_id': theater_id})
        if delete_theater_result.deleted_count > 0:
            print(f"-> Sala {theater_id_str} removida com sucesso.")
        else:
            print(f"-> Sala {theater_id_str} não encontrada para remoção.")
            
    except Exception as e:
        print(f"ERRO durante a remoção da sala {theater_id_str}: {e}")

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
@keyword('Insert User Directly Into DB')
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

@keyword('Insert Movie Directly Into DB')
def insert_movie_directly(movie: dict):
    """Insere filme diretamente no banco. Use com cautela - prefira API."""
    print(f"Tentando inserir filme diretamente no DB: {movie.get('title')}")
    try:
        doc = {
            "title": movie['title'],
            "synopsis": movie['synopsis'],
            "director": movie['director'],
            "genres": movie['genres'],
            "duration": movie['duration'],
            "classification": movie['classification'],
            "poster": movie['poster'],
            "releaseDate": movie['releaseDate']
        }

        movies_collection = db['movies']
        insert_result = movies_collection.insert_one(doc)
        inserted_id = insert_result.inserted_id
        print(f"-> Filme inserido diretamente com _id: {inserted_id}")
        return str(inserted_id)

    except KeyError as e:
        print(f"ERRO: Campo obrigatório faltando no dicionário 'movie': {e}")
        raise ValueError(f"Payload do filme inválido: {e}")
    except Exception as e:
        print(f"ERRO durante a inserção direta do filme {movie.get('title')}: {e}")
        raise e

@keyword('Insert Theater Directly Into DB')
def insert_theater_directly(theater: dict):
    """Insere sala diretamente no banco. Use com cautela - prefira API."""
    print(f"Tentando inserir sala diretamente no DB: {theater.get('name')}")
    try:
        doc = {
            "name": theater['name'],
            "capacity": theater['capacity'],
            "type": theater['type']
        }

        theaters_collection = db['theaters']
        insert_result = theaters_collection.insert_one(doc)
        inserted_id = insert_result.inserted_id
        print(f"-> Sala inserida diretamente com _id: {inserted_id}")
        return str(inserted_id)

    except KeyError as e:
        print(f"ERRO: Campo obrigatório faltando no dicionário 'theater': {e}")
        raise ValueError(f"Payload da sala inválido: {e}")
    except Exception as e:
        print(f"ERRO durante a inserção direta da sala {theater.get('name')}: {e}")
        raise e

@keyword('Insert Session Directly Into DB')
def insert_session_directly(session: dict, movie_data: dict, theater_data: dict):
    """Insere sessão diretamente no banco criando filme e sala antes. Use com cautela - prefira API."""
    print(f"Tentando inserir sessão diretamente no DB")
    try:
        # Cria filme primeiro
        movie_id = insert_movie_directly(movie_data)
        print(f"-> Filme criado com ID: {movie_id}")
        
        # Cria sala depois
        theater_id = insert_theater_directly(theater_data)
        print(f"-> Sala criada com ID: {theater_id}")
        
        # Cria sessão com os IDs
        doc = {
            "movie": ObjectId(movie_id),
            "theater": ObjectId(theater_id),
            "datetime": session['datetime'],
            "fullPrice": session['fullPrice'],
            "halfPrice": session['halfPrice'],
        }

        sessions_collection = db['sessions']
        insert_result = sessions_collection.insert_one(doc)
        inserted_id = insert_result.inserted_id
        print(f"-> Sessão inserida diretamente com _id: {inserted_id}")
        return str(inserted_id)

    except KeyError as e:
        print(f"ERRO: Campo obrigatório faltando no dicionário 'session': {e}")
        raise ValueError(f"Payload da sessão inválido: {e}")
    except Exception as e:
        print(f"ERRO durante a inserção direta da sessão: {e}")
        raise e

@keyword('Insert Reservation Directly Into DB')
def insert_reservation_directly(reservation: dict, user_data: dict, session_data: dict, movie_data: dict, theater_data: dict):
    """Insere reserva diretamente no banco criando usuário e sessão antes. Use com cautela - prefira API."""
    print(f"Tentando inserir reserva diretamente no DB")
    try:
        # Cria usuário primeiro
        user_id = insert_user_directly(user_data)
        print(f"-> Usuário criado com ID: {user_id}")
        
        # Cria sessão depois
        session_id = insert_session_directly(session_data, movie_data, theater_data)
        print(f"-> Sessão criada com ID: {session_id}")
        
        # Cria reserva com os IDs
        doc = {
            "user": ObjectId(user_id),
            "session": ObjectId(session_id),
            "seats": reservation['seats'],
            "totalPrice": reservation['totalPrice'],
            "paymentMethod": reservation['paymentMethod'],
        }

        reservations_collection = db['reservations']
        insert_result = reservations_collection.insert_one(doc)
        inserted_id = insert_result.inserted_id
        print(f"-> Reserva inserida diretamente com _id: {inserted_id}")
        return str(inserted_id)

    except KeyError as e:
        print(f"ERRO: Campo obrigatório faltando no dicionário 'reservation': {e}")
        raise ValueError(f"Payload da reserva inválido: {e}")
    except Exception as e:
        print(f"ERRO durante a inserção direta da reserva: {e}")
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

@keyword('Get Session Id By Movie And Theater')
def get_session_id_by_movie_and_theater(movie_id: str, theater_id: str):
    """Busca sessão pelo movie_id e theater_id e retorna _id como string."""
    print(f"Buscando _id da sessão com movie: {movie_id} e theater: {theater_id}")
    try:
        sessions_collection = db['sessions']
        session = sessions_collection.find_one({
            'movie': ObjectId(movie_id),
            'theater': ObjectId(theater_id)
        })
        if session:
            session_id = str(session['_id'])
            print(f"-> Sessão encontrada. _id: {session_id}")
            return session_id
        else:
            print(f"-> Sessão não encontrada para movie {movie_id} e theater {theater_id}.")
            return None
    except Exception as e:
        print(f"ERRO ao buscar sessão: {e}")
        return None

@keyword('Get Reservation Id By User And Session')
def get_reservation_id_by_user_and_session(user_id: str, session_id: str):
    """Busca reserva pelo user_id e session_id e retorna _id como string."""
    print(f"Buscando _id da reserva com user: {user_id} e session: {session_id}")
    try:
        reservations_collection = db['reservations']
        reservation = reservations_collection.find_one({
            'user': ObjectId(user_id),
            'session': ObjectId(session_id)
        })
        if reservation:
            reservation_id = str(reservation['_id'])
            print(f"-> Reserva encontrada. _id: {reservation_id}")
            return reservation_id
        else:
            print(f"-> Reserva não encontrada para user {user_id} e session {session_id}.")
            return None
    except Exception as e:
        print(f"ERRO ao buscar reserva: {e}")
        return None

@keyword("Generate Admin Token")
def generate_admin_token(admin_email: str = "admin@example.com") -> str:
    """
    Busca o ID do admin pelo email e gera um token JWT válido para ele,
    espelhando a lógica do backend (payload com 'id').
    Retorna o token completo (incluindo 'Bearer ').
    """
    print(f"Gerando token de Admin para: {admin_email}")
    if not JWT_SECRET or JWT_SECRET != 'seu_jwt_secret_aqui':
         raise ValueError("ERRO: JWT_SECRET não está configurada corretamente!")

    admin_id = get_user_id_by_email(admin_email) # Reutiliza sua keyword de busca
    if not admin_id:
        raise ValueError(f"Usuário admin com email {admin_email} não encontrado no banco.")

    # Define o payload do token - APENAS com 'id'
    payload = {
        'id': admin_id, # <-- CORRIGIDO: Apenas o ID
        # Adiciona expiração (ex: 1 hora) e iat (issued at) - Boas práticas
        'exp': datetime.now(timezone.utc) + timedelta(hours=1),
        'iat': datetime.now(timezone.utc)
    }
    print(f"Payload do token: {payload}")

    try:
        # Gera o token usando a chave secreta e HS256
        token = jwt.encode(payload, JWT_SECRET, algorithm="HS256")
        print(f"Token gerado com sucesso.")
        return f"Bearer {token}"
    except Exception as e:
        print(f"ERRO ao gerar token JWT: {e}")
        raise RuntimeError(f"Falha ao gerar token JWT: {e}")
    