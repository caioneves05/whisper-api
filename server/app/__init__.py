from flask import Flask
from flask_cors import CORS 
from config import Config

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)
    
    from app.auth import bp as auth_bp
    cors = CORS(auth_bp, resources={r"/auth/*": {"origins": "*"}})
    app.register_blueprint(auth_bp)

    return app