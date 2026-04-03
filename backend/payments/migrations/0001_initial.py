import uuid
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):
    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ("bookings", "0001_initial"),
    ]

    operations = [
        migrations.CreateModel(
            name="Payment",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("amount", models.DecimalField(decimal_places=2, max_digits=12)),
                ("currency", models.CharField(default="XAF", max_length=8)),
                ("provider", models.CharField(max_length=64)),
                ("transaction_ref", models.CharField(max_length=128, unique=True)),
                ("status", models.CharField(choices=[("pending", "Pending"), ("paid", "Paid"), ("failed", "Failed"), ("refunded", "Refunded")], default="pending", max_length=16)),
                ("paid_at", models.DateTimeField(blank=True, null=True)),
                ("booking", models.OneToOneField(on_delete=models.deletion.CASCADE, related_name="payment", to="bookings.booking")),
                ("user", models.ForeignKey(on_delete=models.deletion.CASCADE, related_name="payments", to=settings.AUTH_USER_MODEL)),
            ],
        ),
    ]
