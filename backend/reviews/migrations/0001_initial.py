import uuid
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):
    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ("bookings", "0001_initial"),
        ("professionals", "0001_initial"),
    ]

    operations = [
        migrations.CreateModel(
            name="Review",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("rating", models.PositiveSmallIntegerField()),
                ("comment", models.TextField(blank=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("booking", models.OneToOneField(on_delete=models.deletion.CASCADE, related_name="review", to="bookings.booking")),
                ("professional", models.ForeignKey(on_delete=models.deletion.CASCADE, related_name="reviews", to="professionals.professionalprofile")),
                ("user", models.ForeignKey(on_delete=models.deletion.CASCADE, related_name="reviews", to=settings.AUTH_USER_MODEL)),
            ],
        ),
    ]
