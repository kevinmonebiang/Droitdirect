import uuid

from django.db import models

from professionals.models import ProfessionType


class Category(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=120)
    profession_type = models.CharField(max_length=32, choices=ProfessionType.choices)
    is_active = models.BooleanField(default=True)

    def __str__(self) -> str:
        return self.name
