from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from dependencies import get_db

from schemas import labels as schema
from crud import labels as crud


router = APIRouter(prefix="/labels", tags=["labels"])


@router.get("/", response_model=list[schema.LabelRead])
def read_labels(db: Session = Depends(get_db)):
    return crud.get_labels(db)


@router.get("/{label_id}", response_model=schema.LabelRead)
def read_label(label_id: int, db: Session = Depends(get_db)):
    label = crud.get_label(db, label_id)
    if not label:
        raise HTTPException(status_code=404, detail="Label not found")
    return label


@router.post("/", response_model=schema.LabelRead, status_code=201)
def create_label(label: schema.LabelCreate, db: Session = Depends(get_db)):
    return crud.create_label(db, label)


@router.delete("/{label_id}", status_code=204)
def delete_label(label_id: int, db: Session = Depends(get_db)):
    label = crud.delete_label(db, label_id)
    if not label:
        raise HTTPException(status_code=404, detail="Label not found")


@router.patch("/{label_id}", response_model=schema.LabelRead)
def update_label(label_id: int, label_update: schema.LabelUpdate, db: Session = Depends(get_db)):
    label = crud.modify_label(db, label_id, label_update)
    if not label:
        raise HTTPException(status_code=404, detail="Label not found")
    return label
