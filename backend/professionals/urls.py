from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import ProfessionalProfileViewSet

router = DefaultRouter(trailing_slash=False)
router.register("professionals", ProfessionalProfileViewSet, basename="professionals")

urlpatterns = router.urls
