
import os
import sys
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.abspath("app"))

from main import app


@pytest.fixture(scope="module")
def client():
    with TestClient(app) as test_client:
        yield test_client


def test_root_endpoint(client):
    response = client.get("/")

    assert response.status_code == 200
    assert response.json()["message"] == "DevOps Practical API is running"


def test_health_endpoint(client):
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_database_readiness(client):
    response = client.get("/ready")

    assert response.status_code == 200
    assert response.json()["status"] == "ready"
    assert response.json()["database"] == "connected"


def test_create_and_retrieve_record(client):
    name = f"CI-Test-{uuid4().hex[:8]}"

    payload = {
        "name": name,
        "message": "GitHub Actions integration test"
    }

    create_response = client.post("/records", json=payload)

    assert create_response.status_code == 200

    created_record = create_response.json()

    assert created_record["name"] == name
    assert created_record["message"] == payload["message"]

    get_response = client.get("/records")

    assert get_response.status_code == 200

    records = get_response.json()

    assert any(
        record["id"] == created_record["id"]
        for record in records
    )
