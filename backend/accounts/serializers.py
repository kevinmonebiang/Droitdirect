import os
import uuid

from django.conf import settings
from django.core.files.storage import default_storage
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .models import User, UserRole


class UserSerializer(serializers.ModelSerializer):
    avatar_file = serializers.FileField(write_only=True, required=False)

    class Meta:
        model = User
        fields = (
            "id",
            "full_name",
            "phone",
            "email",
            "role",
            "avatar",
            "city",
            "created_at",
            "updated_at",
            "status",
            "avatar_file",
        )
        read_only_fields = ("id", "email", "role", "created_at", "updated_at", "status")

    def update(self, instance, validated_data):
        avatar_file = validated_data.pop("avatar_file", None)
        for attribute, value in validated_data.items():
            setattr(instance, attribute, value)

        if avatar_file is not None:
            extension = os.path.splitext(avatar_file.name)[1] or ".jpg"
            saved_name = default_storage.save(
                f"avatars/{uuid.uuid4().hex}{extension}",
                avatar_file,
            )
            request = self.context.get("request")
            if request is not None:
                instance.avatar = request.build_absolute_uri(
                    f"{settings.MEDIA_URL}{saved_name}"
                )
            else:
                instance.avatar = f"{settings.MEDIA_URL}{saved_name}"

        instance.save()
        return instance


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ("id", "full_name", "phone", "email", "password", "role", "city")

    def validate_role(self, value):
        if value == UserRole.ADMIN:
            raise serializers.ValidationError(
                "La creation d un compte administrateur est reservee au backoffice."
            )
        return value

    def create(self, validated_data):
        password = validated_data.pop("password")
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class AdminUserSerializer(serializers.ModelSerializer):
    has_professional_profile = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = (
            "id",
            "full_name",
            "phone",
            "email",
            "role",
            "city",
            "status",
            "avatar",
            "created_at",
            "has_professional_profile",
        )

    def get_has_professional_profile(self, obj):
        return hasattr(obj, "professional_profile")


class CamrlexTokenSerializer(TokenObtainPairSerializer):
    username_field = User.EMAIL_FIELD

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token["role"] = user.role
        token["full_name"] = user.full_name
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        data["user"] = UserSerializer(self.user).data
        return data


class OTPSerializer(serializers.Serializer):
    otp = serializers.CharField(max_length=8)
