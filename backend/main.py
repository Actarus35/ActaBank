from database import engine
from database import Base, SessionLocal

from fastapi import FastAPI


app = FastAPI()

Base.metadata.create_all(bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
