from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("bookings", "0002_booking_issue_fields"),
    ]

    operations = [
        migrations.AddField(
            model_name="booking",
            name="urgency",
            field=models.CharField(
                choices=[("urgent", "Urgent"), ("medium", "Medium")],
                default="medium",
                max_length=16,
            ),
        ),
    ]
