from __future__ import annotations  # ! KEEP AT TOP OF ALL SCRIPTS
from TableConfig.entrypoints import app
from os import environ
import uvicorn

def apis() -> None:
  host: str = environ("TABLE_CONFIG_API_HOST")
  port: str = environ("TABLE_CONFIG_API_PORT")
  uvicorn.run(app, host=host, port=port)
