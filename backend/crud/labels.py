from sqlalchemy.orm import Session
from models.labels import Label
from schemas.labels import LabelCreate, LabelUpdate


def get_labels(db: Session):
    return db.query(Label).all()


def get_label(db: Session, label_id: int):
    return db.query(Label).filter(Label.label_id == label_id).first()


def create_label(db: Session, label: LabelCreate):
    db_label = Label(**label.model_dump())
    db.add(db_label)
    db.commit()
    db.refresh(db_label)
    return db_label


def delete_label(db: Session, label_id: int):
    label = get_label(db, label_id)
    if label:
        db.delete(label)
        db.commit()
    return label


def modify_label(db: Session, label_id: int, label_update: LabelUpdate):
    db_label = get_label(db, label_id)
    if not db_label:
        return None

    update_data = label_update.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(db_label, key, value)

    db.commit()
    db.refresh(db_label)
    return db_label
