# DevOps Interview — Python App (Step 1)

## Run locally
1. Create virtualenv:
   python -m venv venv
   source venv/bin/activate
2. Install:
   pip install -r app/requirements.txt
3. Run (dev):
   python app/src/app.py
   or (prod dev): gunicorn --bind 0.0.0.0:5000 app.app:app

## Tests
pytest -q

## Docker
docker build -t devops-interview-python:local .
docker run -p 5000:5000 devops-interview-python:local

