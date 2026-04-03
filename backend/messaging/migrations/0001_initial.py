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
            name="Conversation",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("booking", models.ForeignKey(blank=True, null=True, on_delete=models.deletion.SET_NULL, related_name="conversations", to="bookings.booking")),
                ("professional", models.ForeignKey(on_delete=models.deletion.CASCADE, related_name="conversations", to="professionals.professionalprofile")),
                ("user", models.ForeignKey(on_delete=models.deletion.CASCADE, related_name="conversations", to=settings.AUTH_USER_MODEL)),
            ],
        ),
        migrations.CreateModel(
            name="Message",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("message_type", models.CharField(choices=[("text", "Text"), ("image", "Image"), ("file", "File"), ("system", "System")], default="text", max_length=16)),
                ("content", models.TextField(blank=True)),
                ("attachment_url", models.URLField(blank=True)),
                ("is_read", models.BooleanField(default=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("conversation", models.ForeignKey(on_delete=models.deletion.CASCADE, related_name="messages", to="messaging.conversation")),
                ("sender", models.ForeignKey(on_delete=models.deletion.CASCADE, related_name="sent_messages", to=settings.AUTH_USER_MODEL)),
            ],
        ),
    ]
