import os
import time

import psycopg2
from psycopg2.extras import RealDictCursor
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="DevOps Practical API")

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "devopsdb")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")


def get_connection():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        connect_timeout=3,
    )


@app.on_event("startup")
def create_table():
    # Retry briefly while PostgreSQL starts.
    for attempt in range(10):
        try:
            with get_connection() as connection:
                with connection.cursor() as cursor:
                    cursor.execute("""
                        CREATE TABLE IF NOT EXISTS records (
                            id SERIAL PRIMARY KEY,
                            name VARCHAR(100) NOT NULL,
                            message TEXT NOT NULL
                        )
                    """)
            return
        except psycopg2.OperationalError:
            if attempt == 9:
                raise
            time.sleep(5)


class Record(BaseModel):
    name: str
    message: str


@app.get("/")
def home():
    return {"message": "DevOps Practical API is running"}


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/ready")
def readiness():
    try:
        with get_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
        return {"status": "ready", "database": "connected"}
    except psycopg2.Error:
        raise HTTPException(status_code=503, detail="Database unavailable")


@app.post("/records")
def create_record(record: Record):
    try:
        with get_connection() as connection:
            with connection.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(
                    "INSERT INTO records (name, message) VALUES (%s, %s) RETURNING *",
                    (record.name, record.message),
                )
                return cursor.fetchone()
    except psycopg2.Error:
        raise HTTPException(status_code=500, detail="Could not save record")


@app.get("/records")
def get_records():
    try:
        with get_connection() as connection:
            with connection.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("SELECT * FROM records ORDER BY id")
                return cursor.fetchall()
    except psycopg2.Error:
        raise HTTPException(status_code=500, detail="Could not retrieve records")