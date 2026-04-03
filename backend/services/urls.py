from rest_framework.routers import DefaultRouter

from .views import ServiceOfferViewSet

router = DefaultRouter(trailing_slash=False)
router.register("services", ServiceOfferViewSet, basename="services")

urlpatterns = router.urls
