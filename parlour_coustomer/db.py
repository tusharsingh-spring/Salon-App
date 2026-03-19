from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
import os 
if os.getenv("RENDER") is None:
    load_dotenv()
# Get DATABASE_URL from Render environment
DATABASE_URL = os.getenv("DATABASE_URL")

# Safety check (very important)
if not DATABASE_URL:
    raise ValueError("DATABASE_URL is not set in environment variables")

print("ACTUAL DATABASE_URL =", DATABASE_URL)
# Create engine (with connection safety)
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,     # avoids broken connections
    pool_recycle=300        # refresh connections every 5 min
)

# Session config
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

# Base model
Base = declarative_base()

# Dependency (for FastAPI routes)
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Create tables
def create_table():
    try:
        Base.metadata.create_all(bind=engine)
        print("✅ Tables created successfully")
    except Exception as e:
        print("❌ Error creating tables:", e)
        raise e

# IMPORTANT: ensures models are registered
import models