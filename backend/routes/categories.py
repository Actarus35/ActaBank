from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from dependencies import get_db, get_current_user

from models.users import User
from crud import categories as crud
from schemas import categories as schema


router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("/", response_model=list[schema.CategoryRead])
def read_categories(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return crud.get_categories(db, current_user.user_id)


@router.get("/{category_id}", response_model=schema.CategoryRead)
def read_category(category_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    category = crud.get_category(db, category_id, current_user.user_id)
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    return category


@router.post("/", response_model=schema.CategoryRead, status_code=201)
def create_category(category: schema.CategoryCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return crud.create_category(db, category, current_user.user_id)


@router.delete("/{category_id}", status_code=204)
def delete_category(category_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    category = crud.delete_category(db, category_id, current_user.user_id)
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")


@router.patch("/{category_id}", response_model=schema.CategoryRead)
def update_category(category_id: int, category_update: schema.CategoryUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    category = crud.modify_category(db, category_id, current_user.user_id, category_update)
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    return category
