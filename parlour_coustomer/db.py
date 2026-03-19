from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
import os

# 🔹 Always load dotenv (local dev)
load_dotenv()

# 🔹 Fetch DATABASE_URL from environment
DATABASE_URL = os.getenv("DATABASE_URL")

# 🔹 Safety check
if not DATABASE_URL:
    raise ValueError("DATABASE_URL is not set in environment variables")

# 🔹 Fix for SQLAlchemy (postgres:// → postgresql://)
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# 🔹 Create engine
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,   # avoid broken connections
    pool_recycle=300      # refresh connections every 5 min
)

# 🔹 Session configuration
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

# 🔹 Base model
Base = declarative_base()

# 🔹 Dependency (for FastAPI routes)
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 🔹 Create tables
def create_table():
    try:
        Base.metadata.create_all(bind=engine)
        print("✅ Tables created successfully")
    except Exception as e:
        print("❌ Error creating tables:", e)
        raise e

# 🔹 Ensure models are imported
import models