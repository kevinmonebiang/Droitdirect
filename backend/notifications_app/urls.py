from django.urls import path

from .views import NotificationListView, mark_notification_read

urlpatterns = [
    path("notifications", NotificationListView.as_view(), name="notifications-list"),
    path(
        "notifications/<uuid:pk>/read",
        mark_notification_read,
        name="notifications-mark-read",
    ),
]
