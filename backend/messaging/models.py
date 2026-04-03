import uuid

from django.conf import settings
from django.db import models

from bookings.models import Booking
from professionals.models import ProfessionalProfile


class MessageType(models.TextChoices):
    TEXT = "text", "Text"
    IMAGE = "image", "Image"
    FILE = "file", "File"
    SYSTEM = "system", "System"


class Conversation(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking = models.ForeignKey(Booking, null=True, blank=True, on_delete=models.SET_NULL, related_name="conversations")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="conversations")
    professional = models.ForeignKey(ProfessionalProfile, on_delete=models.CASCADE, related_name="conversations")
    created_at = models.DateTimeField(auto_now_add=True)
    archived_by_user = models.BooleanField(default=False)
    archived_by_professional = models.BooleanField(default=False)
    deleted_by_user = models.BooleanField(default=False)
    deleted_by_professional = models.BooleanField(default=False)


class Message(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name="messages")
    sender = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="sent_messages")
    message_type = models.CharField(max_length=16, choices=MessageType.choices, default=MessageType.TEXT)
    content = models.TextField(blank=True)
    attachment_url = models.URLField(blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
