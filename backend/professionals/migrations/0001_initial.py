import uuid
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):
    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name="ProfessionalProfile",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("profession_type", models.CharField(choices=[("avocat", "Avocat"), ("huissier", "Huissier"), ("notaire", "Notaire")], max_length=32)),
                ("bio", models.TextField(blank=True)),
                ("city", models.CharField(max_length=120)),
                ("address", models.CharField(blank=True, max_length=255)),
                ("years_experience", models.PositiveIntegerField(default=0)),
                ("languages", models.JSONField(blank=True, default=list)),
                ("specialties", models.JSONField(blank=True, default=list)),
                ("office_name", models.CharField(blank=True, max_length=255)),
                ("verification_status", models.CharField(choices=[("draft", "Brouillon"), ("submitted", "Soumis"), ("under_review", "En cours d examen"), ("verified", "Verifie"), ("rejected", "Rejete"), ("needs_completion", "A completer"), ("suspended", "Suspendu")], default="draft", max_length=32)),
                ("verified_at", models.DateTimeField(blank=True, null=True)),
                ("rating_average", models.DecimalField(decimal_places=2, default=0, max_digits=3)),
                ("total_reviews", models.PositiveIntegerField(default=0)),
                ("is_active", models.BooleanField(default=True)),
                ("user", models.OneToOneField(on_delete=models.deletion.CASCADE, related_name="professional_profile", to=settings.AUTH_USER_MODEL)),
            ],
        ),
        migrations.CreateModel(
            name="VerificationDocument",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("cni_front_url", models.URLField(blank=True)),
                ("cni_back_url", models.URLField(blank=True)),
                ("bar_number", models.CharField(blank=True, max_length=120)),
                ("diploma_url", models.URLField(blank=True)),
                ("full_body_photo_url", models.URLField(blank=True)),
                ("portrait_photo_url", models.URLField(blank=True)),
                ("additional_docs", models.JSONField(blank=True, default=list)),
                ("status", models.CharField(choices=[("draft", "Brouillon"), ("submitted", "Soumis"), ("under_review", "En cours d examen"), ("verified", "Verifie"), ("rejected", "Rejete"), ("needs_completion", "A completer"), ("suspended", "Suspendu")], default="draft", max_length=32)),
                ("rejection_reason", models.TextField(blank=True)),
                ("reviewed_at", models.DateTimeField(blank=True, null=True)),
                ("professional", models.ForeignKey(on_delete=models.deletion.CASCADE, related_name="verification_documents", to="professionals.professionalprofile")),
                ("reviewed_by", models.ForeignKey(blank=True, null=True, on_delete=models.deletion.SET_NULL, related_name="reviewed_verifications", to=settings.AUTH_USER_MODEL)),
            ],
        ),
    ]
