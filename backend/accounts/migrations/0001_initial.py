import accounts.models
import django.contrib.auth.models
import django.utils.timezone
import uuid
from django.db import migrations, models


class Migration(migrations.Migration):
    initial = True

    dependencies = [
        ("auth", "0012_alter_user_first_name_max_length"),
    ]

    operations = [
        migrations.CreateModel(
            name="User",
            fields=[
                ("password", models.CharField(max_length=128, verbose_name="password")),
                ("last_login", models.DateTimeField(blank=True, null=True, verbose_name="last login")),
                ("is_superuser", models.BooleanField(default=False)),
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("full_name", models.CharField(max_length=255)),
                ("phone", models.CharField(max_length=32, unique=True)),
                ("email", models.EmailField(max_length=254, unique=True)),
                ("role", models.CharField(choices=[("client", "Client"), ("professional", "Professional"), ("admin", "Admin")], default="client", max_length=32)),
                ("avatar", models.URLField(blank=True)),
                ("city", models.CharField(blank=True, max_length=120)),
                ("status", models.CharField(choices=[("active", "Active"), ("pending", "Pending"), ("blocked", "Blocked"), ("deleted", "Deleted")], default="pending", max_length=32)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("first_name", models.CharField(blank=True, max_length=150)),
                ("last_name", models.CharField(blank=True, max_length=150)),
                ("is_staff", models.BooleanField(default=False)),
                ("is_active", models.BooleanField(default=True)),
                ("date_joined", models.DateTimeField(default=django.utils.timezone.now)),
                ("groups", models.ManyToManyField(blank=True, related_name="user_set", related_query_name="user", to="auth.group")),
                ("user_permissions", models.ManyToManyField(blank=True, related_name="user_set", related_query_name="user", to="auth.permission")),
            ],
            options={
                "abstract": False,
            },
            managers=[
                ("objects", accounts.models.UserManager()),
            ],
        ),
    ]
