from django.utils import timezone
from rest_framework import decorators, parsers, permissions, response, status, viewsets
from rest_framework.exceptions import PermissionDenied

from services.models import ServiceOffer
from services.serializers import ServiceOfferSerializer

from .models import (
    FavoriteProfessional,
    ProfessionalProfile,
    VerificationDocument,
    VerificationStatus,
)
from .serializers import (
    FavoriteProfessionalSerializer,
    ProfessionalProfileSerializer,
    VerificationDocumentSerializer,
)


class ProfessionalProfileViewSet(viewsets.ModelViewSet):
    queryset = (
        ProfessionalProfile.objects.select_related("user")
        .prefetch_related("verification_documents", "reviews__user")
        .all()
    )
    serializer_class = ProfessionalProfileSerializer
    parser_classes = (parsers.MultiPartParser, parsers.FormParser, parsers.JSONParser)
    filterset_fields = ("profession_type", "city", "verification_status", "is_active")
    search_fields = ("user__full_name", "bio", "office_name")
    ordering_fields = ("rating_average", "years_experience")

    def get_permissions(self):
        if self.action in ("list", "retrieve", "services", "verification_status"):
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    def create(self, request, *args, **kwargs):
        if getattr(request.user, "role", None) not in ("professional", "admin"):
            request.user.role = "professional"
            request.user.save(update_fields=["role"])
        existing_profile = ProfessionalProfile.objects.filter(
            user=request.user
        ).first()
        if existing_profile is not None:
            serializer = self.get_serializer(
                existing_profile,
                data=request.data,
                partial=True,
            )
            serializer.is_valid(raise_exception=True)
            serializer.save(user=request.user)
            return response.Response(serializer.data, status=status.HTTP_200_OK)

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(user=request.user)
        headers = self.get_success_headers(serializer.data)
        return response.Response(
            serializer.data,
            status=status.HTTP_201_CREATED,
            headers=headers,
        )

    def update(self, request, *args, **kwargs):
        if getattr(request.user, "role", None) not in ("professional", "admin"):
            profile = self.get_object()
            if profile.user_id != request.user.id:
                raise PermissionDenied(
                    "Vous ne pouvez modifier que votre propre profil professionnel."
                )
            request.user.role = "professional"
            request.user.save(update_fields=["role"])
        kwargs["partial"] = True
        return super().update(request, *args, **kwargs)

    def get_queryset(self):
        queryset = super().get_queryset()
        if self.action in ("list", "retrieve", "services", "verification_status"):
            return queryset
        role = getattr(self.request.user, "role", None)
        if self.request.user.is_authenticated and role == "admin":
            return queryset
        if self.request.user.is_authenticated and (
            role == "professional"
            or getattr(self.request.user, "professional_profile", None) is not None
        ):
            return queryset.filter(user=self.request.user)
        return queryset.none()

    @decorators.action(detail=False, methods=["get"], url_path="me")
    def me(self, request):
        profile = (
            ProfessionalProfile.objects.select_related("user")
            .prefetch_related("reviews__user")
            .filter(user=request.user)
            .first()
        )
        if profile is None:
            return response.Response(
                {"detail": "Aucun profil professionnel."},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = self.get_serializer(profile)
        return response.Response(serializer.data)

    @decorators.action(detail=True, methods=["get"], url_path="services")
    def services(self, request, pk=None):
        queryset = ServiceOffer.objects.filter(professional_id=pk)
        serializer = ServiceOfferSerializer(queryset, many=True)
        return response.Response(serializer.data)

    @decorators.action(detail=False, methods=["get"], url_path="favorites")
    def favorites(self, request):
        favorites = (
            FavoriteProfessional.objects.filter(user=request.user)
            .select_related("professional", "professional__user")
            .prefetch_related("professional__reviews__user")
        )
        serializer = FavoriteProfessionalSerializer(
            favorites,
            many=True,
            context={"request": request},
        )
        return response.Response(serializer.data)

    @decorators.action(detail=True, methods=["post", "delete"], url_path="favorite")
    def favorite(self, request, pk=None):
        professional = self.get_object()
        favorite = FavoriteProfessional.objects.filter(
            user=request.user,
            professional=professional,
        ).first()

        if request.method == "DELETE":
            if favorite is not None:
                favorite.delete()
            return response.Response({"is_favorited": False}, status=status.HTTP_200_OK)

        if favorite is None:
            FavoriteProfessional.objects.create(
                user=request.user,
                professional=professional,
            )
        return response.Response({"is_favorited": True}, status=status.HTTP_200_OK)

    @decorators.action(detail=True, methods=["post"], url_path="verification")
    def verification(self, request, pk=None):
        professional = self.get_object()
        if professional.user_id != request.user.id:
            raise PermissionDenied(
                "Vous ne pouvez soumettre des documents que pour votre propre compte professionnel."
            )
        if getattr(request.user, "role", None) != "professional":
            request.user.role = "professional"
            request.user.save(update_fields=["role"])
        instance = VerificationDocument.objects.filter(professional_id=pk).first()
        serializer = VerificationDocumentSerializer(
            instance,
            data=request.data,
            partial=instance is not None,
            context={"request": request},
        )
        serializer.is_valid(raise_exception=True)
        serializer.save(
            professional_id=pk,
            status=VerificationStatus.SUBMITTED,
        )
        professional.verification_status = VerificationStatus.SUBMITTED
        submitted_number = request.data.get("bar_number", "")
        if isinstance(submitted_number, str) and submitted_number.strip():
            professional.professional_number = submitted_number.strip()
            professional.save(
                update_fields=["verification_status", "professional_number"]
            )
        else:
            professional.save(update_fields=["verification_status"])
        return response.Response(serializer.data, status=status.HTTP_201_CREATED)

    @decorators.action(detail=True, methods=["get"], url_path="verification-status")
    def verification_status(self, request, pk=None):
        document = VerificationDocument.objects.filter(professional_id=pk).first()
        if document is None:
            return response.Response({"status": "draft"})
        return response.Response(
            {
                "status": document.status,
                "rejection_reason": document.rejection_reason,
                "bar_number": document.bar_number,
            }
        )

    @decorators.action(detail=True, methods=["put"], url_path="review-verification")
    def review_verification(self, request, pk=None):
        if getattr(request.user, "role", None) != "admin":
            raise PermissionDenied("Action reservee a l administrateur.")

        professional = self.get_object()
        document = VerificationDocument.objects.filter(professional=professional).first()
        if document is None:
            return response.Response(
                {"detail": "Aucun dossier de verification a examiner."},
                status=status.HTTP_404_NOT_FOUND,
            )

        new_status = (request.data.get("status") or "").strip()
        allowed_statuses = {
            VerificationStatus.UNDER_REVIEW,
            VerificationStatus.VERIFIED,
            VerificationStatus.REJECTED,
            VerificationStatus.NEEDS_COMPLETION,
            VerificationStatus.SUSPENDED,
        }
        if new_status not in allowed_statuses:
            return response.Response(
                {"detail": "Statut de verification invalide."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        rejection_reason = (request.data.get("rejection_reason") or "").strip()
        document.status = new_status
        document.rejection_reason = rejection_reason
        document.reviewed_by = request.user
        document.reviewed_at = timezone.now()
        document.save(
            update_fields=[
                "status",
                "rejection_reason",
                "reviewed_by",
                "reviewed_at",
            ]
        )

        professional.verification_status = new_status
        professional.verified_at = timezone.now() if new_status == VerificationStatus.VERIFIED else None
        professional.save(update_fields=["verification_status", "verified_at"])

        return response.Response(
            {
                "detail": "Dossier mis a jour.",
                "professional": ProfessionalProfileSerializer(professional).data,
                "document": VerificationDocumentSerializer(document).data,
            }
        )
