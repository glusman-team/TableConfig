from __future__ import annotations  # ! KEEP AT TOP OF ALL SCRIPTS
from pydantic import BaseModel
from pydantic import Field
from pathlib import Path

class NewConfig(BaseModel):
  yaml: Path = Field(...)
