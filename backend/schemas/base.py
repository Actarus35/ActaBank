from decimal import Decimal
from typing import Annotated, ClassVar

from pydantic import BaseModel, ConfigDict, Field, model_validator


Money = Annotated[Decimal, Field(max_digits=10, decimal_places=2)]
Name30 = Annotated[str, Field(min_length=1, max_length=30)]
Name50 = Annotated[str, Field(min_length=1, max_length=50)]
Name100 = Annotated[str, Field(min_length=1, max_length=100)]


class CreateModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class UpdateModel(BaseModel):
    model_config = ConfigDict(extra="forbid")

    non_nullable: ClassVar[frozenset[str]] = frozenset()

    @model_validator(mode="after")
    def reject_explicit_null(self):
        for name in self.model_fields_set:
            if name in self.non_nullable and getattr(self, name) is None:
                raise ValueError(f"{name} ne peut pas être nul")
        return self
