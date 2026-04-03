from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("professionals", "0001_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="professionalprofile",
            name="intervention_zone",
            field=models.CharField(blank=True, max_length=255),
        ),
        migrations.AddField(
            model_name="professionalprofile",
            name="is_online",
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name="professionalprofile",
            name="last_seen_at",
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]
