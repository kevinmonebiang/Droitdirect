from django.contrib import admin

from .models import FavoriteProfessional, ProfessionalProfile, VerificationDocument

admin.site.register(ProfessionalProfile)
admin.site.register(VerificationDocument)
admin.site.register(FavoriteProfessional)
