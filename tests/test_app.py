import os
import sys
import pytest
from app.src import app as myapp

@pytest.fixture
def client():
    myapp.app.testing = True
    with myapp.app.test_client() as client:
        yield client

def test_index(client):
    resp = client.get('/')
    assert resp.status_code == 200
    data = resp.get_json()
    assert 'status' in data and data['status'] == 'ok'

def test_health(client):
    resp = client.get('/health')
    assert resp.status_code == 200
    assert resp.get_data(as_text=True) == 'ok'

def test_ready_default(client):
    # default READY should be true
    if 'APP_READY' in os.environ:
        os.environ.pop('APP_READY')
    resp = client.get('/ready')
    assert resp.status_code == 200
    assert resp.get_data(as_text=True) == 'ready'

def test_metrics(client):
    resp = client.get('/metrics')
    assert resp.status_code == 200
    text = resp.get_data(as_text=True)
    assert 'myapp_requests_total' in text or 'python_gc_objects_collected' in text
