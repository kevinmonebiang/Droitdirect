from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("professionals", "0002_professionalprofile_presence_and_zone"),
    ]

    operations = [
        migrations.AddField(
            model_name="professionalprofile",
            name="professional_number",
            field=models.CharField(blank=True, max_length=120),
        ),
    ]
