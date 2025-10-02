from __future__ import annotations  # ! KEEP AT TOP OF ALL SCRIPTS
from TableConfig.replies import SingleSection
from TableConfig.requests import NewConfig
from TableConfig.replies import Healthz
from TableConfig.replies import Error
from pydantic import ValidationError
from TableConfig.replies import Ok
from TableConfig.yaml import load
from fastapi import FastAPI
from typing import Union
from pathlib import Path
from typing import Any

app: FastAPI = FastAPI()

@app.get("/healthz", response_model=Healthz)
def healthz() -> Healthz:
  return Healthz(ok=True)

@app.post("/table-config", response_model=Union[Ok, Error])
def table_config(request: NewConfig) -> Union[Ok, Error]:
  yaml_p: Path = request.yaml
  sections: list[dict[str, Any]] = load(yaml_p)
  sections = [section.update({"origin": yaml_p, "section_number": i}) for i, section in enumerate(sections, start=1)]
  try:
    return Ok(sections=sections)
  except ValidationError as e:
    return Error(code=0, message=e)  # pydantic coerces types... like e

@app.get("/schema/single-section")
def single_section_schema() -> dict[str, Any]:
  return SingleSection.model_json_schema()
