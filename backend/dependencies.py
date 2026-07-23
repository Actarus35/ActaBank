from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException

from database import SessionLocal
from crud import users as users_crud
from security import decode_access_token, oauth2_scheme


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    credentials_exception = HTTPException(
        status_code=401,
        detail="Identifiants invalides",
        headers={"WWW-Authenticate": "Bearer"},
    )

    user_id = decode_access_token(token)
    if user_id is None:
        raise credentials_exception

    user = users_crud.get_user(db, user_id)
    if user is None:
        raise credentials_exception

    return user