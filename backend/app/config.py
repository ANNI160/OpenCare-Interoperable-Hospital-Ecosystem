from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Database
    database_url: str = "postgresql://hospital:hospital123@localhost:5432/hospital_db"

    # App
    secret_key: str = "opencare-super-secret-key-change-in-production"
    upload_dir: str = "uploads"

    class Config:
        env_file = ".env"


@lru_cache()
def get_settings() -> Settings:
    return Settings()
