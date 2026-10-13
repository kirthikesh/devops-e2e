import os

from fastapi import Depends, FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel
from sqlalchemy import Boolean, Column, Integer, String, create_engine, text
from sqlalchemy.orm import Session, declarative_base, sessionmaker

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./todos.db")

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    connect_args={"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {},
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)
Base = declarative_base()


class Todo(Base):
    __tablename__ = "todos"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    done = Column(Boolean, default=False, nullable=False)


class TodoIn(BaseModel):
    title: str
    done: bool = False


class TodoOut(TodoIn):
    id: int

    model_config = {"from_attributes": True}


Base.metadata.create_all(bind=engine)

app = FastAPI(title="devops-e2e-api", version=os.getenv("APP_VERSION", "dev"))
Instrumentator().instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.get("/health")
def health():
    """Liveness: process is up."""
    return {"status": "ok"}


@app.get("/ready")
def ready(db: Session = Depends(get_db)):
    """Readiness: database reachable."""
    try:
        db.execute(text("SELECT 1"))
    except Exception as exc:
        raise HTTPException(status_code=503, detail="database unavailable") from exc
    return {"status": "ready"}


@app.get("/api/version")
def version():
    return {"version": app.version}


@app.get("/api/todos", response_model=list[TodoOut])
def list_todos(db: Session = Depends(get_db)):
    return db.query(Todo).order_by(Todo.id).all()


@app.post("/api/todos", response_model=TodoOut, status_code=201)
def create_todo(todo: TodoIn, db: Session = Depends(get_db)):
    if not todo.title.strip():
        raise HTTPException(status_code=422, detail="title must not be empty")
    item = Todo(title=todo.title.strip(), done=todo.done)
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@app.put("/api/todos/{todo_id}", response_model=TodoOut)
def update_todo(todo_id: int, todo: TodoIn, db: Session = Depends(get_db)):
    item = db.get(Todo, todo_id)
    if not item:
        raise HTTPException(status_code=404, detail="not found")
    item.title, item.done = todo.title, todo.done
    db.commit()
    db.refresh(item)
    return item


@app.delete("/api/todos/{todo_id}", status_code=204)
def delete_todo(todo_id: int, db: Session = Depends(get_db)):
    item = db.get(Todo, todo_id)
    if not item:
        raise HTTPException(status_code=404, detail="not found")
    db.delete(item)
    db.commit()
