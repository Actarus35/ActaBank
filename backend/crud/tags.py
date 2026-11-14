from sqlalchemy.orm import Session
from models.tags import Tag
from schemas.tags import TagCreate, TagUpdate


def get_tags(db: Session, user_id: int):
    return db.query(Tag).filter(Tag.user_id == user_id).all()


def get_tag(db: Session, tag_id: int, user_id: int):
    return db.query(Tag).filter(Tag.tag_id == tag_id, Tag.user_id == user_id).first()


def create_tag(db: Session, tag: TagCreate, user_id: int):
    db_tag = Tag(**tag.model_dump(), user_id=user_id)
    db.add(db_tag)
    db.commit()
    db.refresh(db_tag)
    return db_tag


def delete_tag(db: Session, tag_id: int, user_id: int):
    tag = get_tag(db, tag_id, user_id)
    if tag:
        db.delete(tag)
        db.commit()
    return tag


def modify_tag(db: Session, tag_id: int, user_id: int, tag_update: TagUpdate):
    db_tag = get_tag(db, tag_id, user_id)
    if not db_tag:
        return None

    update_data = tag_update.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(db_tag, key, value)

    db.commit()
    db.refresh(db_tag)
    return db_tag

def get_tags_by_ids(db: Session, tag_ids: list[int], user_id: int):
    if not tag_ids:
        return []
    return db.query(Tag).filter(Tag.tag_id.in_(tag_ids), Tag.user_id == user_id).all()