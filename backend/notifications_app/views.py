from rest_framework import generics, permissions, response, status
from rest_framework.decorators import api_view, permission_classes

from .models import Notification
from .serializers import NotificationSerializer


class NotificationListView(generics.ListAPIView):
    serializer_class = NotificationSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user).order_by(
            "-created_at"
        )


@api_view(["PUT"])
@permission_classes([permissions.IsAuthenticated])
def mark_notification_read(request, pk):
    notification = Notification.objects.filter(
        pk=pk,
        user=request.user,
    ).first()
    if notification is None:
        return response.Response(
            {"detail": "Notification introuvable."},
            status=status.HTTP_404_NOT_FOUND,
        )

    notification.is_read = True
    notification.save(update_fields=["is_read"])
    return response.Response(NotificationSerializer(notification).data)
