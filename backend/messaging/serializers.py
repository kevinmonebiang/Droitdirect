from rest_framework import serializers

from .models import Conversation, Message


class ConversationSerializer(serializers.ModelSerializer):
    contact_name = serializers.SerializerMethodField()
    subtitle = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    messages = serializers.SerializerMethodField()
    last_activity_at = serializers.SerializerMethodField()
    is_archived = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = (
            "id",
            "booking",
            "user",
            "professional",
            "created_at",
            "contact_name",
            "subtitle",
            "unread_count",
            "last_activity_at",
            "is_archived",
            "messages",
        )

    def get_contact_name(self, obj):
        request = self.context.get("request")
        if request is None:
            return obj.professional.user.full_name
        if obj.user_id == request.user.id:
            return obj.professional.user.full_name
        return obj.user.full_name

    def get_subtitle(self, obj):
        last_message = self._sorted_messages(obj)[-1] if obj.messages.exists() else None
        if last_message is None:
            if obj.booking is not None and obj.booking.issue_title:
                return f"Demande: {obj.booking.issue_title}"
            return "Conversation ouverte."
        return last_message.content or last_message.attachment_url or "Nouveau message"

    def get_unread_count(self, obj):
        request = self.context.get("request")
        if request is None:
            return 0
        return sum(
            1
            for message in obj.messages.all()
            if message.sender_id != request.user.id and not message.is_read
        )

    def get_messages(self, obj):
        return MessageSerializer(self._sorted_messages(obj), many=True).data

    def get_last_activity_at(self, obj):
        last_message = self._sorted_messages(obj)[-1] if obj.messages.exists() else None
        if last_message is not None:
            return last_message.created_at
        return obj.created_at

    def get_is_archived(self, obj):
        request = self.context.get("request")
        if request is None:
            return False
        if obj.user_id == request.user.id:
            return obj.archived_by_user
        if obj.professional.user_id == request.user.id:
            return obj.archived_by_professional
        return False

    def _sorted_messages(self, obj):
        return sorted(obj.messages.all(), key=lambda message: message.created_at)


class MessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.CharField(source="sender.full_name", read_only=True)

    class Meta:
        model = Message
        fields = (
            "id",
            "conversation",
            "sender",
            "sender_name",
            "message_type",
            "content",
            "attachment_url",
            "is_read",
            "created_at",
        )
        read_only_fields = (
            "sender",
            "sender_name",
            "is_read",
            "created_at",
        )
