from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import AvailabilitySlotViewSet, BookingViewSet

router = DefaultRouter(trailing_slash=False)
router.register("bookings", BookingViewSet, basename="bookings")
router.register("availability-slots", AvailabilitySlotViewSet, basename="availability-slots")

urlpatterns = router.urls + [
    path("users/bookings", BookingViewSet.as_view({"get": "list"}), name="users-bookings"),
]
