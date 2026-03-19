from fastapi import FastAPI, Depends, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
import models, schemas, services
from db import get_db, create_table, engine
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date, datetime

app = FastAPI(title="Mom's Salon Management System")

# ✅ Move DB init to startup event
@app.on_event("startup")
def startup():
    create_table()
    print("✅ Tables created successfully!")

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Customer Routes
@app.post("/customers/", response_model=schemas.Customer)
def create_customer(customer: schemas.CustomerCreate, db: Session = Depends(get_db)):
    return services.create_customer(db, customer)

@app.get("/customers/", response_model=List[schemas.Customer])
def get_customers(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return services.get_customers(db, skip=skip, limit=limit)

@app.get("/customers/{customer_id}", response_model=schemas.Customer)
def get_customer(customer_id: int, db: Session = Depends(get_db)):
    db_customer = services.get_customer(db, customer_id)
    if db_customer is None:
        raise HTTPException(status_code=404, detail="Customer not found")
    return db_customer

@app.put("/customers/{customer_id}", response_model=schemas.Customer)
def update_customer(customer_id: int, customer: schemas.CustomerCreate, db: Session = Depends(get_db)):
    db_customer = services.update_customer(db, customer_id, customer)
    if db_customer is None:
        raise HTTPException(status_code=404, detail="Customer not found")
    return db_customer

@app.delete("/customers/{customer_id}")
def delete_customer(customer_id: int, db: Session = Depends(get_db)):
    db_customer = services.delete_customer(db, customer_id)
    if db_customer is None:
        raise HTTPException(status_code=404, detail="Customer not found")
    return {"message": "Customer deleted successfully"}

# Service Routes
@app.post("/services/", response_model=schemas.Service)
def create_service(service: schemas.ServiceCreate, db: Session = Depends(get_db)):
    return services.create_service(db, service)

@app.get("/services/", response_model=List[schemas.Service])
def get_services(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return services.get_services(db, skip=skip, limit=limit)

@app.get("/services/{service_id}", response_model=schemas.Service)
def get_service(service_id: int, db: Session = Depends(get_db)):
    db_service = services.get_service(db, service_id)
    if db_service is None:
        raise HTTPException(status_code=404, detail="Service not found")
    return db_service

@app.put("/services/{service_id}", response_model=schemas.Service)
def update_service(service_id: int, service: schemas.ServiceCreate, db: Session = Depends(get_db)):
    db_service = services.update_service(db, service_id, service)
    if db_service is None:
        raise HTTPException(status_code=404, detail="Service not found")
    return db_service

@app.delete("/services/{service_id}")
def delete_service(service_id: int, db: Session = Depends(get_db)):
    db_service = services.delete_service(db, service_id)
    if db_service is None:
        raise HTTPException(status_code=404, detail="Service not found")
    return {"message": "Service deleted successfully"}

# Appointment Routes
@app.post("/appointments/", response_model=schemas.Appointment)
def create_appointment(appointment: schemas.AppointmentCreate, db: Session = Depends(get_db)):
    return services.create_appointment(db, appointment)

@app.get("/appointments/", response_model=List[schemas.Appointment])
def get_appointments(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return services.get_appointments(db, skip=skip, limit=limit)

@app.get("/appointments/{appointment_id}", response_model=schemas.Appointment)
def get_appointment(appointment_id: int, db: Session = Depends(get_db)):
    db_appointment = services.get_appointment(db, appointment_id)
    if db_appointment is None:
        raise HTTPException(status_code=404, detail="Appointment not found")
    return db_appointment

@app.get("/customers/{customer_id}/appointments/", response_model=List[schemas.Appointment])
def get_customer_appointments(customer_id: int, db: Session = Depends(get_db)):
    return services.get_customer_appointments(db, customer_id)

@app.patch("/appointments/{appointment_id}/payment")
def update_payment(
    appointment_id: int, 
    payment_status: str, 
    payment_method: Optional[str] = None, 
    db: Session = Depends(get_db)
):
    db_appointment = services.update_appointment_payment(db, appointment_id, payment_status, payment_method)
    if db_appointment is None:
        raise HTTPException(status_code=404, detail="Appointment not found")
    return db_appointment

@app.delete("/appointments/{appointment_id}")
def delete_appointment(appointment_id: int, db: Session = Depends(get_db)):
    db_appointment = services.delete_appointment(db, appointment_id)
    if db_appointment is None:
        raise HTTPException(status_code=404, detail="Appointment not found")
    return {"message": "Appointment deleted successfully"}

# Analytics Routes
@app.get("/analytics/daily/")
def get_daily_earnings(
    start_date: date = Query(...), 
    end_date: date = Query(...), 
    db: Session = Depends(get_db)
):
    return services.get_daily_earnings(db, start_date, end_date)

@app.get("/analytics/service-popularity/")
def get_service_popularity(days: int = 30, db: Session = Depends(get_db)):
    return services.get_service_popularity(db, days)

@app.get("/analytics/monthly/{year}/{month}")
def get_monthly_summary(year: int, month: int, db: Session = Depends(get_db)):
    if month < 1 or month > 12:
        raise HTTPException(status_code=400, detail="Month must be between 1 and 12")
    return services.get_monthly_summary(db, year, month)

# Dashboard Summary
@app.get("/dashboard/")
def get_dashboard_summary(db: Session = Depends(get_db)):
    today = date.today()
    
    # Today's earnings
    today_earnings = services.get_daily_earnings(db, today, today)
    
    # This month's summary
    monthly_summary = services.get_monthly_summary(db, today.year, today.month)
    
    # Total customers
    total_customers = len(services.get_customers(db))
    
    # Total services
    total_services = len(services.get_services(db))
    
    return {
        "today_earnings": today_earnings[0] if today_earnings else {"total_earnings": 0, "appointment_count": 0},
        "monthly_summary": monthly_summary,
        "total_customers": total_customers,
        "total_services": total_services
    }

@app.get("/")
def root():
    return {
        "message": "Welcome to Mom's Salon Management System",
        "docs": "/docs",
        "endpoints": {
            "customers": "/customers/",
            "services": "/services/",
            "appointments": "/appointments/",
            "analytics": "/analytics/",
            "dashboard": "/dashboard/"
        }
    }

# Health check endpoint
@app.get("/health")
def health_check():
    return {"status": "healthy"}