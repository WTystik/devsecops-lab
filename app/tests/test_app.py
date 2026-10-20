from app import app


def test_index_returns_message():
    response = app.test_client().get("/")
    assert response.status_code == 200
    assert "message" in response.get_json()


def test_health_is_ok():
    response = app.test_client().get("/health")
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}

