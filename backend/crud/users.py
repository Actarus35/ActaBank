from sqlalchemy.orm import Session
from models.users import User
from schemas.users import UserCreate
from security import hash_password


def get_user(db: Session, user_id: int):
    return db.query(User).filter(User.user_id == user_id).first()


def get_user_by_username(db:Session, username: str):
    return db.query(User).filter(User.user_username == username).first()


def create_user(db: Session, user: UserCreate):
    db_user = User(
        user_username=user.user_username,
        user_password_hash=hash_password(user.user_password),
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


