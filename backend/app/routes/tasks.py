"""Task routes — ward-scoped task management."""
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import Task, User
from app.auth import get_current_user
from app.schemas import TaskCreate, TaskUpdate, TaskResponse
import uuid

router = APIRouter(prefix="/tasks", tags=["Tasks"])


@router.get("/ward/{ward_number}", response_model=list[TaskResponse])
def get_tasks_for_ward(
    ward_number: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    tasks = (
        db.query(Task)
        .filter(Task.ward_number == ward_number)
        .order_by(Task.is_completed.asc(), Task.due_date.asc())
        .all()
    )
    return tasks


@router.post("", response_model=TaskResponse, status_code=201)
def create_task(
    data: TaskCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    task = Task(
        id=str(uuid.uuid4()),
        title=data.title,
        description=data.description,
        due_date=data.due_date,
        patient_id=data.patient_id,
        patient_name=data.patient_name,
        ward_number=data.ward_number,
        assigned_nurse_id=user.id,
        assigned_nurse_name=user.name,
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


@router.patch("/{task_id}", response_model=TaskResponse)
def update_task_status(
    task_id: str,
    data: TaskUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(404, "Task not found")

    task.is_completed = data.is_completed
    if data.is_completed:
        task.completed_by_nurse_id = user.id
        task.completed_by_nurse_name = user.name
        task.completed_at = datetime.utcnow()
    else:
        task.completed_by_nurse_id = None
        task.completed_by_nurse_name = None
        task.completed_at = None

    db.commit()
    db.refresh(task)
    return task


@router.delete("/{task_id}")
def delete_task(
    task_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(404, "Task not found")
    db.delete(task)
    db.commit()
    return {"message": "Task deleted"}
