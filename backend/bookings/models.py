import uuid

from django.conf import settings
from django.db import models

from professionals.models import ProfessionalProfile
from services.models import ServiceOffer


class BookingType(models.TextChoices):
    ONLINE = "online", "Online"
    ONSITE = "onsite", "Onsite"


class BookingStatus(models.TextChoices):
    PENDING = "pending", "Pending"
    ACCEPTED = "accepted", "Accepted"
    REJECTED = "rejected", "Rejected"
    CANCELLED = "cancelled", "Cancelled"
    COMPLETED = "completed", "Completed"
    EXPIRED = "expired", "Expired"
    DISPUTED = "disputed", "Disputed"


class PaymentStatus(models.TextChoices):
    PENDING = "pending", "Pending"
    PAID = "paid", "Paid"
    FAILED = "failed", "Failed"
    REFUNDED = "refunded", "Refunded"


class BookingUrgency(models.TextChoices):
    URGENT = "urgent", "Urgent"
    MEDIUM = "medium", "Medium"


class AvailabilitySlot(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    professional = models.ForeignKey(ProfessionalProfile, on_delete=models.CASCADE, related_name="availability_slots")
    day_of_week = models.PositiveSmallIntegerField()
    start_time = models.TimeField()
    end_time = models.TimeField()
    is_available = models.BooleanField(default=True)
    slot_duration = models.PositiveIntegerField(default=30)


class Booking(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="bookings")
    professional = models.ForeignKey(ProfessionalProfile, on_delete=models.CASCADE, related_name="bookings")
    service = models.ForeignKey(ServiceOffer, on_delete=models.CASCADE, related_name="bookings")
    issue_title = models.CharField(max_length=160, blank=True, default="")
    issue_summary = models.TextField(blank=True, default="")
    urgency = models.CharField(max_length=16, choices=BookingUrgency.choices, default=BookingUrgency.MEDIUM)
    booking_type = models.CharField(max_length=16, choices=BookingType.choices)
    appointment_date = models.DateField()
    start_time = models.TimeField()
    end_time = models.TimeField()
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    status = models.CharField(max_length=16, choices=BookingStatus.choices, default=BookingStatus.PENDING)
    payment_status = models.CharField(max_length=16, choices=PaymentStatus.choices, default=PaymentStatus.PENDING)
    meeting_link = models.URLField(blank=True)
    onsite_address = models.CharField(max_length=255, blank=True)
    note = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class BookingIssueReportStatus(models.TextChoices):
    OPEN = "open", "Open"
    UNDER_REVIEW = "under_review", "Under review"
    RESOLVED = "resolved", "Resolved"
    REFUND_APPROVED = "refund_approved", "Refund approved"
    REFUND_REJECTED = "refund_rejected", "Refund rejected"


class BookingIssueReport(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking = models.OneToOneField(
        Booking,
        on_delete=models.CASCADE,
        related_name="issue_report",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="booking_issue_reports",
    )
    reason = models.CharField(max_length=180)
    details = models.TextField(blank=True)
    wants_refund = models.BooleanField(default=False)
    status = models.CharField(
        max_length=32,
        choices=BookingIssueReportStatus.choices,
        default=BookingIssueReportStatus.OPEN,
    )
    admin_note = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
