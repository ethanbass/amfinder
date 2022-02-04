#! /bin/bash

PYTHON="${PYTHON:-$(which python3.8.5)}"

python -m pip install --upgrade pip && \
python -m pip install -r requirements.txt && \
deactivate && \
echo "The AMFinder tool <amf> was successfully installed."
