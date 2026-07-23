from sqlalchemy.orm import Session
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm

from models.users import User
from crud import users as crud
from schemas import users as schema
from dependencies import get_db, get_current_user
from security import verify_password, create_access_token


router = APIRouter(prefix="/auth", tags=["auth"])

DUMMY_HASH = "$2b$12$2Kus718s38qOwg/umswVNulVXwjm69JsPaEJzXr6SOvYff2AdOvuO"


@router.post("/register", response_model=schema.UserRead, status_code=201)
def register(user: schema.UserCreate, db: Session = Depends(get_db)):
    if crud.get_user_by_username(db, user.user_username):
        raise HTTPException(status_code=409, detail="Ce nom d'utilisateur est déjà pris")
    return crud.create_user(db, user)


@router.post("/login", response_model=schema.Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = crud.get_user_by_username(db, form_data.username)

    password_hash = user.user_password_hash if user else DUMMY_HASH
    password_ok = verify_password(form_data.password, password_hash)

    if not user or not password_ok:
        raise HTTPException(
            status_code=401,
            detail="Identifiant ou mot de passe incorrect",
            headers={"WWW-Authenticate": "Bearer"},
            )
    return schema.Token(access_token=create_access_token(user.user_id))


@router.get("/me", response_model=schema.UserRead)
def read_me(current_user: User = Depends(get_current_user)):
    return current_user