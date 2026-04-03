import uuid

from django.conf import settings
from django.db import models


class ProfessionType(models.TextChoices):
    AVOCAT = "avocat", "Avocat"
    HUISSIER = "huissier", "Huissier"
    NOTAIRE = "notaire", "Notaire"


class VerificationStatus(models.TextChoices):
    DRAFT = "draft", "Brouillon"
    SUBMITTED = "submitted", "Soumis"
    UNDER_REVIEW = "under_review", "En cours d examen"
    VERIFIED = "verified", "Verifie"
    REJECTED = "rejected", "Rejete"
    NEEDS_COMPLETION = "needs_completion", "A completer"
    SUSPENDED = "suspended", "Suspendu"


class ProfessionalProfile(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="professional_profile")
    profession_type = models.CharField(max_length=32, choices=ProfessionType.choices)
    professional_number = models.CharField(max_length=120, blank=True)
    bio = models.TextField(blank=True)
    city = models.CharField(max_length=120)
    intervention_zone = models.CharField(max_length=255, blank=True)
    address = models.CharField(max_length=255, blank=True)
    years_experience = models.PositiveIntegerField(default=0)
    languages = models.JSONField(default=list, blank=True)
    specialties = models.JSONField(default=list, blank=True)
    office_name = models.CharField(max_length=255, blank=True)
    verification_status = models.CharField(max_length=32, choices=VerificationStatus.choices, default=VerificationStatus.DRAFT)
    verified_at = models.DateTimeField(null=True, blank=True)
    rating_average = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    total_reviews = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    is_online = models.BooleanField(default=False)
    last_seen_at = models.DateTimeField(null=True, blank=True)


class VerificationDocument(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    professional = models.ForeignKey(ProfessionalProfile, on_delete=models.CASCADE, related_name="verification_documents")
    cni_front_url = models.URLField(blank=True)
    cni_back_url = models.URLField(blank=True)
    bar_number = models.CharField(max_length=120, blank=True)
    diploma_url = models.URLField(blank=True)
    full_body_photo_url = models.URLField(blank=True)
    portrait_photo_url = models.URLField(blank=True)
    additional_docs = models.JSONField(default=list, blank=True)
    status = models.CharField(max_length=32, choices=VerificationStatus.choices, default=VerificationStatus.DRAFT)
    rejection_reason = models.TextField(blank=True)
    reviewed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="reviewed_verifications",
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)


class FavoriteProfessional(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="favorite_professionals",
    )
    professional = models.ForeignKey(
        ProfessionalProfile,
        on_delete=models.CASCADE,
        related_name="followers",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=("user", "professional"),
                name="unique_favorite_professional",
            )
        ]
