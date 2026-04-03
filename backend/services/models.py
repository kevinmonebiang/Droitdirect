import uuid

from django.db import models

from professionals.models import ProfessionalProfile
from taxonomy.models import Category


class ServiceMode(models.TextChoices):
    ONLINE = "online", "Online"
    ONSITE = "onsite", "Onsite"
    BOTH = "both", "Both"


class PriceType(models.TextChoices):
    FIXED = "fixed", "Fixed"
    STARTING_FROM = "starting_from", "Starting From"
    NEGOTIABLE = "negotiable", "Negotiable"


class ServiceOffer(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    professional = models.ForeignKey(ProfessionalProfile, on_delete=models.CASCADE, related_name="services")
    title = models.CharField(max_length=255)
    description = models.TextField()
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, related_name="services")
    mode = models.CharField(max_length=16, choices=ServiceMode.choices)
    price_type = models.CharField(max_length=32, choices=PriceType.choices, default=PriceType.FIXED)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=8, default="XAF")
    duration_minutes = models.PositiveIntegerField(default=30)
    city = models.CharField(max_length=120)
    address = models.CharField(max_length=255, blank=True)
    is_published = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
