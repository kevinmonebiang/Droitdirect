import uuid
from django.db import migrations, models


class Migration(migrations.Migration):
    initial = True

    dependencies = [
        ("professionals", "0001_initial"),
        ("taxonomy", "0001_initial"),
    ]

    operations = [
        migrations.CreateModel(
            name="ServiceOffer",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("title", models.CharField(max_length=255)),
                ("description", models.TextField()),
                ("mode", models.CharField(choices=[("online", "Online"), ("onsite", "Onsite"), ("both", "Both")], max_length=16)),
                ("price_type", models.CharField(choices=[("fixed", "Fixed"), ("starting_from", "Starting From"), ("negotiable", "Negotiable")], default="fixed", max_length=32)),
                ("amount", models.DecimalField(decimal_places=2, max_digits=12)),
                ("currency", models.CharField(default="XAF", max_length=8)),
                ("duration_minutes", models.PositiveIntegerField(default=30)),
                ("city", models.CharField(max_length=120)),
                ("address", models.CharField(blank=True, max_length=255)),
                ("is_published", models.BooleanField(default=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("category", models.ForeignKey(null=True, on_delete=models.deletion.SET_NULL, related_name="services", to="taxonomy.category")),
                ("professional", models.ForeignKey(on_delete=models.deletion.CASCADE, related_name="services", to="professionals.professionalprofile")),
            ],
        ),
    ]
