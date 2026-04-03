import os
import uuid

from django.conf import settings
from django.core.files.storage import default_storage
from rest_framework import serializers

from reviews.serializers import ReviewSerializer

from .models import FavoriteProfessional, ProfessionalProfile, VerificationDocument


class ProfessionalProfileSerializer(serializers.ModelSerializer):
    user_id = serializers.UUIDField(source="user.id", read_only=True)
    full_name = serializers.CharField(source="user.full_name", read_only=True)
    email = serializers.EmailField(source="user.email", read_only=True)
    phone = serializers.CharField(source="user.phone", read_only=True)
    avatar = serializers.CharField(source="user.avatar", read_only=True)
    is_favorited = serializers.SerializerMethodField(read_only=True)
    reviews = ReviewSerializer(many=True, read_only=True)

    class Meta:
        model = ProfessionalProfile
        fields = (
            "id",
            "user_id",
            "full_name",
            "email",
            "phone",
            "avatar",
            "professional_number",
            "profession_type",
            "bio",
            "city",
            "intervention_zone",
            "address",
            "years_experience",
            "languages",
            "specialties",
            "office_name",
            "verification_status",
            "verified_at",
            "rating_average",
            "total_reviews",
            "reviews",
            "is_active",
            "is_online",
            "last_seen_at",
            "is_favorited",
        )
        read_only_fields = (
            "id",
            "user_id",
            "full_name",
            "email",
            "phone",
            "avatar",
            "verified_at",
            "rating_average",
            "total_reviews",
            "is_online",
            "last_seen_at",
            "is_favorited",
        )

    def get_is_favorited(self, obj):
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if user is None or not user.is_authenticated:
            return False
        return FavoriteProfessional.objects.filter(
            user=user,
            professional=obj,
        ).exists()


class VerificationDocumentSerializer(serializers.ModelSerializer):
    cni_front_file = serializers.FileField(write_only=True, required=False)
    cni_back_file = serializers.FileField(write_only=True, required=False)
    diploma_file = serializers.FileField(write_only=True, required=False)
    full_body_photo_file = serializers.FileField(write_only=True, required=False)
    portrait_photo_file = serializers.FileField(write_only=True, required=False)
    additional_doc_files = serializers.ListField(
        child=serializers.FileField(),
        write_only=True,
        required=False,
    )

    class Meta:
        model = VerificationDocument
        fields = (
            "id",
            "professional",
            "cni_front_url",
            "cni_back_url",
            "bar_number",
            "diploma_url",
            "full_body_photo_url",
            "portrait_photo_url",
            "additional_docs",
            "status",
            "rejection_reason",
            "reviewed_by",
            "reviewed_at",
            "cni_front_file",
            "cni_back_file",
            "diploma_file",
            "full_body_photo_file",
            "portrait_photo_file",
            "additional_doc_files",
        )
        read_only_fields = (
            "professional",
            "status",
            "rejection_reason",
            "reviewed_by",
            "reviewed_at",
        )
        extra_kwargs = {
            "professional": {"required": False},
        }

    def validate(self, attrs):
        def has_value(field_name, upload_key):
            if attrs.get(upload_key) is not None:
                return True
            if attrs.get(field_name):
                return True
            if self.instance is not None:
                return bool(getattr(self.instance, field_name, ""))
            return False

        errors = {}
        if not has_value("cni_front_url", "cni_front_file"):
            errors["cni_front_file"] = (
                "La CNI ou la carte professionnelle est requise."
            )
        if not has_value("diploma_url", "diploma_file"):
            errors["diploma_file"] = "Le diplome ou l attestation est requis."
        if not has_value("portrait_photo_url", "portrait_photo_file"):
            errors["portrait_photo_file"] = "Le selfie est requis."

        if errors:
            raise serializers.ValidationError(errors)

        return attrs

    def create(self, validated_data):
        request = self.context.get("request")
        uploads = {
            "cni_front_url": validated_data.pop("cni_front_file", None),
            "cni_back_url": validated_data.pop("cni_back_file", None),
            "diploma_url": validated_data.pop("diploma_file", None),
            "full_body_photo_url": validated_data.pop("full_body_photo_file", None),
            "portrait_photo_url": validated_data.pop("portrait_photo_file", None),
        }
        extra_files = validated_data.pop("additional_doc_files", [])

        for field_name, upload in uploads.items():
            if upload is not None:
                validated_data[field_name] = self._store_upload(
                    upload,
                    request=request,
                    folder="verification",
                )

        if extra_files:
            validated_data["additional_docs"] = [
                self._store_upload(upload, request=request, folder="verification")
                for upload in extra_files
            ]

        return super().create(validated_data)

    def update(self, instance, validated_data):
        request = self.context.get("request")
        uploads = {
            "cni_front_url": validated_data.pop("cni_front_file", None),
            "cni_back_url": validated_data.pop("cni_back_file", None),
            "diploma_url": validated_data.pop("diploma_file", None),
            "full_body_photo_url": validated_data.pop("full_body_photo_file", None),
            "portrait_photo_url": validated_data.pop("portrait_photo_file", None),
        }
        extra_files = validated_data.pop("additional_doc_files", None)

        for field_name, upload in uploads.items():
            if upload is not None:
                validated_data[field_name] = self._store_upload(
                    upload,
                    request=request,
                    folder="verification",
                )

        if extra_files is not None:
            validated_data["additional_docs"] = [
                self._store_upload(upload, request=request, folder="verification")
                for upload in extra_files
            ]

        return super().update(instance, validated_data)

    def _store_upload(self, upload, request, folder):
        extension = os.path.splitext(upload.name)[1] or ""
        saved_name = default_storage.save(
            f"{folder}/{uuid.uuid4().hex}{extension}",
            upload,
        )
        if request is not None:
            return request.build_absolute_uri(f"{settings.MEDIA_URL}{saved_name}")
        return f"{settings.MEDIA_URL}{saved_name}"


class AdminVerificationDocumentSerializer(serializers.ModelSerializer):
    reviewed_by_name = serializers.CharField(
        source="reviewed_by.full_name",
        read_only=True,
    )

    class Meta:
        model = VerificationDocument
        fields = (
            "id",
            "cni_front_url",
            "cni_back_url",
            "bar_number",
            "diploma_url",
            "full_body_photo_url",
            "portrait_photo_url",
            "additional_docs",
            "status",
            "rejection_reason",
            "reviewed_by_name",
            "reviewed_at",
        )


class AdminProfessionalProfileSerializer(ProfessionalProfileSerializer):
    verification_documents = AdminVerificationDocumentSerializer(
        many=True,
        read_only=True,
    )

    class Meta(ProfessionalProfileSerializer.Meta):
        fields = ProfessionalProfileSerializer.Meta.fields + (
            "verification_documents",
        )


class FavoriteProfessionalSerializer(serializers.ModelSerializer):
    professional = ProfessionalProfileSerializer(read_only=True)

    class Meta:
        model = FavoriteProfessional
        fields = (
            "id",
            "professional",
            "created_at",
        )
