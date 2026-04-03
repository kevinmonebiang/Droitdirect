import uuid
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):
    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ("professionals", "0001_initial"),
        ("services", "0001_initial"),
    ]

    operations = [
        migrations.CreateModel(
            name="AvailabilitySlot",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("day_of_week", models.PositiveSmallIntegerField()),
                ("start_time", models.TimeField()),
                ("end_time", models.TimeField()),
                ("is_available", models.BooleanField(default=True)),
                ("slot_duration", models.PositiveIntegerField(default=30)),
                ("professional", models.ForeignKey(on_delete=models.deletion.CASCADE, related_name="availability_slots", to="professionals.professionalprofile")),
            ],
        ),
        migrations.CreateModel(
            name="Booking",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("booking_type", models.CharField(choices=[("online", "Online"), ("onsite", "Onsite")], max_length=16)),
                ("appointment_date", models.DateField()),
                ("start_time", models.TimeField()),
                ("end_time", models.TimeField()),
                ("amount", models.DecimalField(decimal_places=2, max_digits=12)),
                ("status", models.CharField(choices=[("pending", "Pending"), ("accepted", "Accepted"), ("rejected", "Rejected"), ("cancelled", "Cancelled"), ("completed", "Completed"), ("expired", "Expired"), ("disputed", "Disputed")], default="pending", max_length=16)),
                ("payment_status", models.CharField(choices=[("pending", "Pending"), ("paid", "Paid"), ("failed", "Failed"), ("refunded", "Refunded")], default="pending", max_length=16)),
                ("meeting_link", models.URLField(blank=True)),
                ("onsite_address", models.CharField(blank=True, max_length=255)),
                ("note", models.TextField(blank=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("professional", models.ForeignKey(on_delete=models.deletion.CASCADE, related_name="bookings", to="professionals.professionalprofile")),
                ("service", models.ForeignKey(on_delete=models.deletion.CASCADE, related_name="bookings", to="services.serviceoffer")),
                ("user", models.ForeignKey(on_delete=models.deletion.CASCADE, related_name="bookings", to=settings.AUTH_USER_MODEL)),
            ],
        ),
    ]
