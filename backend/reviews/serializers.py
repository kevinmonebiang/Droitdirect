from rest_framework import serializers

from .models import Review


class ReviewSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source="user.full_name", read_only=True)

    class Meta:
        model = Review
        fields = (
            "id",
            "booking",
            "user",
            "professional",
            "rating",
            "comment",
            "created_at",
            "author_name",
        )
        read_only_fields = ("user", "professional", "created_at")

    def validate(self, attrs):
        booking = attrs.get("booking")
        request = self.context.get("request")
        user = attrs.get("user") or getattr(request, "user", None)
        if booking and booking.status != "completed":
            raise serializers.ValidationError(
                "Seule une reservation terminee peut etre notee."
            )
        if booking and user and booking.user_id != user.id:
            raise serializers.ValidationError(
                "Seul le client de cette reservation peut laisser un avis."
            )
        return attrs
