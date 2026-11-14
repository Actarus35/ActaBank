from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from dependencies import get_db, get_current_user

from models.users import User
from schemas.stats import StatsSummary, CategoryStat, BalanceOverTime, TransactionNameStat
from crud import stats as crud
from enums.stats_period import StatsPeriod


router = APIRouter(prefix="/stats", tags=["stats"])


@router.get("/summary", response_model=StatsSummary)
def read_summary(period: StatsPeriod = StatsPeriod.MONTH, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return crud.get_summary(db, current_user.user_id, period)


@router.get("/by-category", response_model=list[CategoryStat])
def read_by_category(period: StatsPeriod = StatsPeriod.MONTH, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return crud.get_by_category(db, current_user.user_id, period)


@router.get("/balance-over-time", response_model=BalanceOverTime)
def read_balance_over_time(period: StatsPeriod = StatsPeriod.MONTH, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return crud.get_balance_over_time(db, current_user.user_id, period)


@router.get("/by-name", response_model=list[TransactionNameStat])
def read_by_name(period: StatsPeriod = StatsPeriod.MONTH, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return crud.get_by_name(db, current_user.user_id, period)