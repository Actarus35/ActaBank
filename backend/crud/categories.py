from sqlalchemy.orm import Session
from models.categories import Category
from schemas.categories import CategoryCreate, CategoryUpdate


def get_categories(db: Session, user_id: int):
    return db.query(Category).filter(Category.user_id == user_id).all()


def get_category(db: Session, category_id: int, user_id: int):
    return db.query(Category).filter(Category.category_id == category_id, Category.user_id == user_id).first()


def create_category(db: Session, category: CategoryCreate, user_id: int):
    db_category = Category(**category.model_dump(), user_id=user_id)
    db.add(db_category)
    db.commit()
    db.refresh(db_category)
    return db_category


def delete_category(db: Session, category_id: int, user_id: int):
    category = get_category(db, category_id, user_id)
    if category:
        db.delete(category)
        db.commit()
    return category


def modify_category(db: Session, category_id: int, user_id: int, category_update: CategoryUpdate):
    db_category = get_category(db, category_id, user_id)
    if not db_category:
        return None

    update_data = category_update.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(db_category, key, value)

    db.commit()
    db.refresh(db_category)
    return db_category