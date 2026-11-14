from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from dependencies import get_db, get_current_user

from models.users import User
from crud import tags as crud
from schemas import tags as schema


router = APIRouter(prefix="/tags", tags=["tags"])


@router.get("/", response_model=list[schema.TagRead])
def read_tags(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return crud.get_tags(db, current_user.user_id)


@router.get("/{tag_id}", response_model=schema.TagRead)
def read_tag(tag_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    tag = crud.get_tag(db, tag_id, current_user.user_id)
    if not tag:
        raise HTTPException(status_code=404, detail="Tag not found")
    return tag


@router.post("/", response_model=schema.TagRead, status_code=201)
def create_tag(tag: schema.TagCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return crud.create_tag(db, tag, current_user.user_id)


@router.delete("/{tag_id}", status_code=204)
def delete_tag(tag_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    tag = crud.delete_tag(db, tag_id, current_user.user_id)
    if not tag:
        raise HTTPException(status_code=404, detail="Tag not found")


@router.patch("/{tag_id}", response_model=schema.TagRead)
def update_tag(tag_id: int, tag_update: schema.TagUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    tag = crud.modify_tag(db, tag_id, current_user.user_id, tag_update)
    if not tag:
        raise HTTPException(status_code=404, detail="Tag not found")
    return tag
