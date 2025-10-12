from __future__ import annotations  # ! KEEP AT TOP OF ALL SCRIPTS
from yaml import CLoader as Loader
from pydantic import BaseModel
from pydantic import Field
from pathlib import Path
from typing import Any
import yaml

def fastmerge(a: Any, b: Any) -> Any:
  # streamlined (fast) implementation of deepmerge config
  if isinstance(a, dict) and isinstance(b, dict):
    for k, v in b.items():
      if k in a:
        av: Any = a[k]
        if isinstance(av, dict) and isinstance(v, dict):
          fastmerge(av, v)
        elif isinstance(av, list) and isinstance(v, list):
          av.extend(v)
        else:
          a[k] = v
      else:
        a[k] = v
    return a
  elif isinstance(a, list) and isinstance(b, list):
    a.extend(b)
    return a
  else:
    return b

class TableConfig(BaseModel):
  template: dict[str, Any] = Field(...)
  sections: list[dict[str, Any]] = Field(...)

def load(yaml_p: Path) -> list[dict[str, Any]]:
  with yaml_p.open("r") as f:
    raw: Any = yaml.load(f, Loader=Loader)
    tc: TableConfig = TableConfig.model_validate(raw)
    template: dict[str, Any] = tc.template
    return [fastmerge(template, section) for section in tc.section]
