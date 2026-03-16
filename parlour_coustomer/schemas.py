from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

# Customer Schemas
class CustomerBase(BaseModel):
    name: str
    phone: Optional[str] = None
    email: Optional[str] = None

class CustomerCreate(CustomerBase):
    pass

class Customer(CustomerBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Service Schemas
class ServiceBase(BaseModel):
    name: str
    description: Optional[str] = None
    base_price: float
    duration_minutes: Optional[int] = None

class ServiceCreate(ServiceBase):
    pass

class Service(ServiceBase):
    id: int
    
    class Config:
        from_attributes = True

# Appointment Service Schemas
class AppointmentServiceBase(BaseModel):
    service_id: int
    price_charged: float
    notes: Optional[str] = None

class AppointmentServiceCreate(AppointmentServiceBase):
    pass

class AppointmentService(AppointmentServiceBase):
    id: int
    appointment_id: int
    service: Optional[Service] = None
    
    class Config:
        from_attributes = True

# Appointment Schemas
class AppointmentBase(BaseModel):
    customer_id: int
    appointment_date: Optional[datetime] = None
    discount: Optional[float] = 0
    payment_method: Optional[str] = None
    payment_status: Optional[str] = "Pending"
    notes: Optional[str] = None

class AppointmentCreate(AppointmentBase):
    services: List[AppointmentServiceCreate]

class Appointment(AppointmentBase):
    id: int
    total_amount: float
    final_amount: float
    created_at: datetime
    customer: Optional[Customer] = None
    services: List[AppointmentService] = []
    
    class Config:
        from_attributes = True

# Analytics Schemas
class DailyEarnings(BaseModel):
    date: str
    total_earnings: float
    appointment_count: int

class ServicePopularity(BaseModel):
    service_name: str
    count: int
    total_revenue: float

class MonthlySummary(BaseModel):
    year: int
    month: int
    total_earnings: float
    total_appointments: int
    unique_customers: int
    average_per_appointment: float