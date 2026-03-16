from sqlalchemy.orm import Session
from sqlalchemy import func, extract
from models import Customer, Service, Appointment, AppointmentService
from schemas import CustomerCreate, ServiceCreate, AppointmentCreate, AppointmentServiceCreate
from datetime import datetime, date, timedelta
from typing import List, Optional

# Customer Services
def create_customer(db: Session, customer: CustomerCreate):
    db_customer = Customer(**customer.model_dump())
    db.add(db_customer)
    db.commit()
    db.refresh(db_customer)
    return db_customer

def get_customers(db: Session, skip: int = 0, limit: int = 100):
    return db.query(Customer).offset(skip).limit(limit).all()

def get_customer(db: Session, customer_id: int):
    return db.query(Customer).filter(Customer.id == customer_id).first()

def update_customer(db: Session, customer_id: int, customer: CustomerCreate):
    db_customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if db_customer:
        for key, value in customer.model_dump().items():
            setattr(db_customer, key, value)
        db.commit()
        db.refresh(db_customer)
    return db_customer

def delete_customer(db: Session, customer_id: int):
    db_customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if db_customer:
        db.delete(db_customer)
        db.commit()
    return db_customer

# Service Services
def create_service(db: Session, service: ServiceCreate):
    db_service = Service(**service.model_dump())
    db.add(db_service)
    db.commit()
    db.refresh(db_service)
    return db_service

def get_services(db: Session, skip: int = 0, limit: int = 100):
    return db.query(Service).offset(skip).limit(limit).all()

def get_service(db: Session, service_id: int):
    return db.query(Service).filter(Service.id == service_id).first()

def update_service(db: Session, service_id: int, service: ServiceCreate):
    db_service = db.query(Service).filter(Service.id == service_id).first()
    if db_service:
        for key, value in service.model_dump().items():
            setattr(db_service, key, value)
        db.commit()
        db.refresh(db_service)
    return db_service

def delete_service(db: Session, service_id: int):
    db_service = db.query(Service).filter(Service.id == service_id).first()
    if db_service:
        db.delete(db_service)
        db.commit()
    return db_service

# Appointment Services
def create_appointment(db: Session, appointment: AppointmentCreate):
    # Calculate total amount from services
    total_amount = sum(service.price_charged for service in appointment.services)
    final_amount = total_amount - appointment.discount
    
    # Create appointment
    db_appointment = Appointment(
        customer_id=appointment.customer_id,
        appointment_date=appointment.appointment_date or datetime.utcnow(),
        total_amount=total_amount,
        discount=appointment.discount,
        final_amount=final_amount,
        payment_method=appointment.payment_method,
        payment_status=appointment.payment_status,
        notes=appointment.notes
    )
    
    db.add(db_appointment)
    db.flush()  # Get appointment ID without committing
    
    # Add services
    for service_data in appointment.services:
        db_appointment_service = AppointmentService(
            appointment_id=db_appointment.id,
            service_id=service_data.service_id,
            price_charged=service_data.price_charged,
            notes=service_data.notes
        )
        db.add(db_appointment_service)
    
    db.commit()
    db.refresh(db_appointment)
    return db_appointment

def get_appointments(db: Session, skip: int = 0, limit: int = 100):
    return db.query(Appointment).order_by(Appointment.appointment_date.desc()).offset(skip).limit(limit).all()

def get_appointment(db: Session, appointment_id: int):
    return db.query(Appointment).filter(Appointment.id == appointment_id).first()

def get_customer_appointments(db: Session, customer_id: int):
    return db.query(Appointment).filter(Appointment.customer_id == customer_id).order_by(Appointment.appointment_date.desc()).all()

def update_appointment_payment(db: Session, appointment_id: int, payment_status: str, payment_method: str = None):
    db_appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if db_appointment:
        db_appointment.payment_status = payment_status
        if payment_method:
            db_appointment.payment_method = payment_method
        db.commit()
        db.refresh(db_appointment)
    return db_appointment

# Analytics Services
def get_daily_earnings(db: Session, start_date: date, end_date: date):
    results = db.query(
        func.date(Appointment.appointment_date).label('date'),
        func.sum(Appointment.final_amount).label('total_earnings'),
        func.count(Appointment.id).label('appointment_count')
    ).filter(
        func.date(Appointment.appointment_date) >= start_date,
        func.date(Appointment.appointment_date) <= end_date
    ).group_by(
        func.date(Appointment.appointment_date)
    ).all()
    
    return [{"date": str(r.date), "total_earnings": float(r.total_earnings), "appointment_count": r.appointment_count} for r in results]

def get_service_popularity(db: Session, days: int = 30):
    results = db.query(
        Service.name,
        func.count(AppointmentService.id).label('count'),
        func.sum(AppointmentService.price_charged).label('total_revenue')
    ).join(AppointmentService).join(Appointment).filter(
        Appointment.appointment_date >= datetime.utcnow() - timedelta(days=days)
    ).group_by(Service.name).all()
    
    return [{"service_name": r.name, "count": r.count, "total_revenue": float(r.total_revenue)} for r in results]

def get_monthly_summary(db: Session, year: int, month: int):
    total_earnings = db.query(func.sum(Appointment.final_amount)).filter(
        extract('year', Appointment.appointment_date) == year,
        extract('month', Appointment.appointment_date) == month
    ).scalar() or 0
    
    total_appointments = db.query(func.count(Appointment.id)).filter(
        extract('year', Appointment.appointment_date) == year,
        extract('month', Appointment.appointment_date) == month
    ).scalar() or 0
    
    unique_customers = db.query(func.count(func.distinct(Appointment.customer_id))).filter(
        extract('year', Appointment.appointment_date) == year,
        extract('month', Appointment.appointment_date) == month
    ).scalar() or 0
    
    return {
        "year": year,
        "month": month,
        "total_earnings": float(total_earnings),
        "total_appointments": total_appointments,
        "unique_customers": unique_customers,
        "average_per_appointment": float(total_earnings / total_appointments) if total_appointments > 0 else 0
    }