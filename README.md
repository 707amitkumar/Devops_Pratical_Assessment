# DevOps Python Appliaction - Quick Setup and Run Guide  🚀


## 1) Clone repository

```bash
git clone https://github.com/707amitkumar/Devops_Pratical_Assessment.git
```
## 2) Create virtual environment and install requirements

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r app/requirements.txt
```
## 3) Build and run Docker container

```bash
docker build -t devops-interview-python:latest .
docker run -d --name devops-app -p 5000:5000 devops-interview-python:latest
```
## 4) Test endpoints

```bash
curl http://localhost:5000/
curl http://localhost:5000/health
curl http://localhost:5000/ready
curl http://localhost:5000/metrics
```
