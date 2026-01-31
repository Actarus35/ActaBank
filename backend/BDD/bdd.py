from sqlalchemy import String, ForeignKey, create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import Mapped, sessionmaker, mapped_column

DATABASE_URL = "sqlite:///./BDD/bdd.db"
engine = create_engine(DATABASE_URL, echo=True, connect_args={"check_same_thread": False})


Base = declarative_base()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Bank(Base):
    __tablename__ = "banks"
    bank_id: Mapped[int] = mapped_column(primary_key=True)
    bank_name: Mapped[str] = mapped_column(String(30), nullable=False)
    bank_account_type: Mapped[str] = mapped_column(unique=True, nullable=False)
    bank_description: Mapped[str] = mapped_column(nullable=True)

    def __repr__(self) -> str:
        return f"Bank(id={self.bank_id!r}, name={self.bank_name!r}, account_type={self.bank_account_type!r}, description={self.bank_description!r})"


class Label(Base):
    __tablename__ = "labels"
    label_id: Mapped[int] = mapped_column(primary_key=True)
    label_name: Mapped[str] = mapped_column(nullable=False)
    label_color: Mapped[str] = mapped_column(nullable=False, default="white")

    def __repr__(self) -> str:
        return f"Label(id={self.label_id!r}, name={self.label_name!r}, color={self.label_color!r})"


class TransactionMethod(Base):
    __tablename__ = "transaction_methods"
    transmet_id: Mapped[int] = mapped_column(primary_key=True)
    transmet_type: Mapped[str] = mapped_column(nullable=False)
    bank_id: Mapped[int] = mapped_column(ForeignKey("banks.bank_id"))

    def __repr__(self) -> str:
        return f"TransactionMethod(id={self.transmet_id!r}, type={self.transmet_type!r}, bank_id={self.bank_id!r})"


class Transaction(Base):
    __tablename__ = "transactions"
    transac_id: Mapped[int] = mapped_column(primary_key=True)
    transac_name: Mapped[str] = mapped_column(nullable=False)
    transac_title: Mapped[str] = mapped_column(nullable=True)
    transac_date: Mapped[str] = mapped_column(nullable=False)
    transac_amount: Mapped[float] = mapped_column(nullable=False)
    transac_description: Mapped[str] = mapped_column(nullable=True)
    transac_is_recurring: Mapped[int] = mapped_column(nullable=False, default=0)
    transmet_id: Mapped[int] = mapped_column(ForeignKey("transaction_methods.transmet_id"))
    label_id: Mapped[int] = mapped_column(ForeignKey("labels.label_id"))

    def __repr__(self) -> str:
        return f"Transaction(id={self.transac_id!r}, name={self.transac_name!r}, title={self.transac_title!r}, date={self.transac_date!r}, amount={self.transac_amount!r}, description={self.transac_description!r}, is_recurring={self.transac_is_recurring!r}, transmet_id={self.transmet_id!r}, label_id={self.label_id!r})"


class RecurringTransaction(Base):
    __tablename__ = "recurring_transactions"
    rectransac_id: Mapped[int] = mapped_column(primary_key=True)
    rectransac_frequency: Mapped[str] = mapped_column(nullable=False)
    rectransac_day: Mapped[str] = mapped_column(nullable=True)
    rectransac_start_date: Mapped[str] = mapped_column(nullable=False)
    rectransac_end_date: Mapped[float] = mapped_column(nullable=False)
    transac_id: Mapped[int] = mapped_column(ForeignKey("transactions.transac_id"))

    def __repr__(self) -> str:
        return f"RecurringTransaction(id={self.rectransac_id!r}, frequency={self.rectransac_frequency!r}, day={self.rectransac_day!r}, start_date={self.rectransac_start_date!r}, end_date={self.rectransac_end_date!r}, transac_id={self.transac_id!r})"


# Create the database table
Base.metadata.create_all(bind=engine)
