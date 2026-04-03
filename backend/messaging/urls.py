from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import ConversationViewSet, MessageCreateView

router = DefaultRouter(trailing_slash=False)
router.register("conversations", ConversationViewSet, basename="conversations")

urlpatterns = router.urls + [
    path("messages", MessageCreateView.as_view(), name="messages-create"),
]
