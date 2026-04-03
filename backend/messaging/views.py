from django.db.models import F, Max, Q
from rest_framework import decorators, generics, permissions, response, status, viewsets
from rest_framework.exceptions import PermissionDenied

from .models import Conversation, Message
from .serializers import ConversationSerializer, MessageSerializer


class ConversationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = ConversationSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def get_queryset(self):
        queryset = Conversation.objects.select_related(
            "user",
            "professional",
            "professional__user",
            "booking",
        ).prefetch_related("messages", "messages__sender")

        user = self.request.user
        if getattr(user, "role", None) == "professional":
            queryset = queryset.filter(
                professional__user=user,
                deleted_by_professional=False,
            )
        else:
            queryset = queryset.filter(
                Q(user=user, deleted_by_user=False)
                | Q(professional__user=user, deleted_by_professional=False)
            )

        queryset = queryset.annotate(
            latest_message_at=Max("messages__created_at"),
        )
        return queryset.order_by(
            F("latest_message_at").desc(nulls_last=True),
            "-created_at",
        )

    @decorators.action(detail=True, methods=["post"])
    def mark_read(self, request, pk=None):
        conversation = self.get_object()
        conversation.messages.exclude(sender=request.user).filter(is_read=False).update(
            is_read=True,
        )
        return response.Response({"detail": "Messages marques comme lus."}, status=status.HTTP_200_OK)

    @decorators.action(detail=True, methods=["post"])
    def archive(self, request, pk=None):
        conversation = self.get_object()
        update_fields = []
        if conversation.user_id == request.user.id:
            conversation.archived_by_user = True
            conversation.deleted_by_user = False
            update_fields.extend(["archived_by_user", "deleted_by_user"])
        elif conversation.professional.user_id == request.user.id:
            conversation.archived_by_professional = True
            conversation.deleted_by_professional = False
            update_fields.extend(
                ["archived_by_professional", "deleted_by_professional"]
            )
        else:
            raise PermissionDenied(
                "Vous ne pouvez pas archiver cette conversation."
            )

        conversation.save(update_fields=update_fields)
        return response.Response(
            {"detail": "Conversation archivee."},
            status=status.HTTP_200_OK,
        )

    @decorators.action(detail=True, methods=["post"])
    def delete(self, request, pk=None):
        conversation = self.get_object()
        update_fields = []
        if conversation.user_id == request.user.id:
            conversation.deleted_by_user = True
            conversation.archived_by_user = False
            update_fields.extend(["deleted_by_user", "archived_by_user"])
        elif conversation.professional.user_id == request.user.id:
            conversation.deleted_by_professional = True
            conversation.archived_by_professional = False
            update_fields.extend(
                ["deleted_by_professional", "archived_by_professional"]
            )
        else:
            raise PermissionDenied(
                "Vous ne pouvez pas supprimer cette conversation."
            )

        conversation.save(update_fields=update_fields)
        return response.Response(
            {"detail": "Conversation supprimee."},
            status=status.HTTP_200_OK,
        )


class MessageCreateView(generics.CreateAPIView):
    queryset = Message.objects.select_related("conversation", "sender").all()
    serializer_class = MessageSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def perform_create(self, serializer):
        conversation = serializer.validated_data["conversation"]
        user = self.request.user

        is_participant = (
            conversation.user_id == user.id
            or conversation.professional.user_id == user.id
        )
        if not is_participant:
            raise PermissionDenied(
                "Vous ne pouvez pas envoyer de message dans cette conversation."
            )

        serializer.save(sender=user)
