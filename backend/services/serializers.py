from rest_framework import serializers

from taxonomy.models import Category

from professionals.models import VerificationStatus

from .models import ServiceOffer


class ServiceOfferSerializer(serializers.ModelSerializer):
    category_name = serializers.SerializerMethodField(read_only=True)
    category_input = serializers.CharField(
        write_only=True,
        required=False,
        allow_blank=True,
    )

    class Meta:
        model = ServiceOffer
        fields = (
            "id",
            "professional",
            "title",
            "description",
            "category",
            "mode",
            "price_type",
            "amount",
            "currency",
            "duration_minutes",
            "city",
            "address",
            "is_published",
            "created_at",
            "category_name",
            "category_input",
        )
        read_only_fields = ("professional", "created_at")
        extra_kwargs = {
            "category": {"required": False, "allow_null": True},
            "professional": {"required": False},
        }

    def validate(self, attrs):
        request = self.context.get("request")
        professional = attrs.get("professional")
        if professional is None and request is not None:
            professional = getattr(request.user, "professional_profile", None)
        is_published = attrs.get("is_published", False)
        if professional and is_published:
            if professional.verification_status != VerificationStatus.VERIFIED:
                attrs["is_published"] = False
        return attrs

    def create(self, validated_data):
        category_input = validated_data.pop("category_input", "").strip()
        validated_data["category"] = self._resolve_category(
            validated_data.get("professional"),
            category_input,
            validated_data.get("category"),
        )
        return super().create(validated_data)

    def update(self, instance, validated_data):
        category_input = validated_data.pop("category_input", "").strip()
        if category_input or "category" in validated_data:
            validated_data["category"] = self._resolve_category(
                validated_data.get("professional", instance.professional),
                category_input,
                validated_data.get("category", instance.category),
            )
        return super().update(instance, validated_data)

    def get_category_name(self, obj):
        return obj.category.name if obj.category_id else ""

    def _resolve_category(self, professional, category_input, category):
        if category is not None:
            return category
        if not category_input or professional is None:
            return None
        category_name = category_input[:120]
        resolved_category, _ = Category.objects.get_or_create(
            name=category_name,
            profession_type=professional.profession_type,
            defaults={"is_active": True},
        )
        return resolved_category
