from flask import Flask
from flask_cors import CORS 
from config import Config

import sentry_sdk

sentry_sdk.init(
    dsn="https://4073d12312795b804a5d789894c1bdb7@o4506355076431872.ingest.sentry.io/4506593436762112",
)

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)
    
    from app.auth import bp as auth_bp
    cors = CORS(auth_bp, resources={r"/auth/*": {"origins": "*"}})
    app.register_blueprint(auth_bp)

    return app