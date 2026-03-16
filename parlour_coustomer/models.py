from db import Base
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime

class Customer(Base):
    __tablename__ = "customers"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    phone = Column(String, nullable=True)
    email = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationship
    appointments = relationship("Appointment", back_populates="customer", cascade="all, delete-orphan")

class Service(Base):
    __tablename__ = "services"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    description = Column(Text, nullable=True)
    base_price = Column(Float, nullable=False)
    duration_minutes = Column(Integer, nullable=True)
    
    # Relationship
    appointment_services = relationship("AppointmentService", back_populates="service", cascade="all, delete-orphan")

class Appointment(Base):
    __tablename__ = "appointments"
    
    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("customers.id", ondelete="CASCADE"), nullable=False)
    appointment_date = Column(DateTime, default=datetime.utcnow)
    total_amount = Column(Float, default=0)
    discount = Column(Float, default=0)
    final_amount = Column(Float, default=0)
    payment_method = Column(String, nullable=True)  # Cash, Card, UPI, etc.
    payment_status = Column(String, default="Pending")  # Pending, Paid, Partial
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    customer = relationship("Customer", back_populates="appointments")
    services = relationship("AppointmentService", back_populates="appointment", cascade="all, delete-orphan")

class AppointmentService(Base):
    __tablename__ = "appointment_services"
    
    id = Column(Integer, primary_key=True, index=True)
    appointment_id = Column(Integer, ForeignKey("appointments.id", ondelete="CASCADE"), nullable=False)
    service_id = Column(Integer, ForeignKey("services.id", ondelete="CASCADE"), nullable=False)
    price_charged = Column(Float, nullable=False)  # Price at time of service
    notes = Column(Text, nullable=True)
    
    # Relationships
    appointment = relationship("Appointment", back_populates="services")
    service = relationship("Service", back_populates="appointment_services")