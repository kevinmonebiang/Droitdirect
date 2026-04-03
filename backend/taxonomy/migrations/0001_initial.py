import uuid
from django.db import migrations, models


class Migration(migrations.Migration):
    initial = True

    dependencies = [
        ("professionals", "0001_initial"),
    ]

    operations = [
        migrations.CreateModel(
            name="Category",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("name", models.CharField(max_length=120)),
                ("profession_type", models.CharField(choices=[("avocat", "Avocat"), ("huissier", "Huissier"), ("notaire", "Notaire")], max_length=32)),
                ("is_active", models.BooleanField(default=True)),
            ],
        ),
    ]
