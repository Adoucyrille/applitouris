
from pathlib import Path
from dotenv import load_dotenv
from datetime import timedelta
import os

# ── Chemin absolu forcé vers le .env ─────────────────────────
BASE_DIR    = Path(__file__).resolve().parent.parent
DOTENV_PATH = BASE_DIR / '.env'

# Affichage de débogage
print("Chemin .env :", DOTENV_PATH)
print("Fichier trouvé :", DOTENV_PATH.exists())

# Charger le .env
load_dotenv(dotenv_path=DOTENV_PATH, override=True)

# Vérification
print("=== TEST CHARGEMENT .env ===")
print("SITE ID :", os.getenv('SITE_ID_CINETPAY'))
print("API KEY :", os.getenv('CLE_API_CINETPAY'))
print("============================")

# ── Clés CinetPay ─────────────────────────────────────────────
CINETPAY_API_KEY        = os.getenv('CLE_API_CINETPAY')
CINETPAY_SITE_ID        = os.getenv('SITE_ID_CINETPAY')
CINETPAY_URL_RETOUR     = os.getenv('URL_CONFIRMATION_PAIEMENT')
CINETPAY_URL_ANNULATION = os.getenv('URL_ANNULATION_PAIEMENT')

# ── Sécurité Django ───────────────────────────────────────────
SECRET_KEY = os.getenv('CLE_SECRETE_DJANGO', 'django-insecure-tourisme-ci-2025')
DEBUG      = os.getenv('MODE_DEBUG', 'True') == 'True'
ALLOWED_HOSTS = []

# ── Applications installées ───────────────────────────────────
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework_simplejwt.token_blacklist',
    'corsheaders',
    'apptourism',
]

# ── Middleware ────────────────────────────────────────────────
MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # doit être en premier
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

# ── CORS — autoriser Flutter à appeler l'API ──────────────────
CORS_ALLOW_ALL_ORIGINS = True  # en développement seulement

# ── URLs ──────────────────────────────────────────────────────
ROOT_URLCONF = 'tourisme.urls'

# ── Templates ─────────────────────────────────────────────────
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'tourisme.wsgi.application'

# ── Base de données PostgreSQL ────────────────────────────────
DATABASES = {
    'default': {
        'ENGINE'  : 'django.db.backends.postgresql',
        'NAME'    : 'bd_tourisme',
        'USER'    : 'postgres',
        'PASSWORD': 'adou2026',
        'HOST'    : 'localhost',
        'PORT'    : '5432',
    }
}

# ── Modèle utilisateur personnalisé ──────────────────────────
AUTH_USER_MODEL = 'apptourism.Utilisateur'

# ── Authentification JWT ──────────────────────────────────────
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
}

# Durée de vie des tokens JWT
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME'   : timedelta(hours=24),
    'REFRESH_TOKEN_LIFETIME'  : timedelta(days=7),
    'ROTATE_REFRESH_TOKENS'   : True,
    'BLACKLIST_AFTER_ROTATION': True,
}

# ── Validation des mots de passe ──────────────────────────────
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# ── Internationalisation ──────────────────────────────────────
LANGUAGE_CODE = 'fr-fr'
TIME_ZONE     = 'Africa/Abidjan'
USE_I18N      = True
USE_TZ        = True

# ── Fichiers statiques ────────────────────────────────────────
STATIC_URL = 'static/'

# ── Fichiers media (photos des sites et des profils) ──────────
MEDIA_URL  = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# ── Clé primaire par défaut ───────────────────────────────────
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'