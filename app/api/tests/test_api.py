import os

os.environ["DATABASE_URL"] = "sqlite:///./test.db"

from fastapi.testclient import TestClient  # noqa: E402

from main import Base, app, engine  # noqa: E402

client = TestClient(app)


def setup_function():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)


def test_health():
    assert client.get("/health").json() == {"status": "ok"}


def test_ready():
    assert client.get("/ready").status_code == 200


def test_crud():
    r = client.post("/api/todos", json={"title": "ship it"})
    assert r.status_code == 201
    todo_id = r.json()["id"]

    assert len(client.get("/api/todos").json()) == 1

    r = client.put(f"/api/todos/{todo_id}", json={"title": "ship it", "done": True})
    assert r.json()["done"] is True

    assert client.delete(f"/api/todos/{todo_id}").status_code == 204
    assert client.get("/api/todos").json() == []


def test_empty_title_rejected():
    assert client.post("/api/todos", json={"title": "  "}).status_code == 422


def test_metrics_exposed():
    client.get("/health")
    assert "http_requests_total" in client.get("/metrics").text
