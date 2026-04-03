from rest_framework import permissions, viewsets
from rest_framework.exceptions import PermissionDenied

from .models import ServiceOffer
from .serializers import ServiceOfferSerializer


class ServiceOfferViewSet(viewsets.ModelViewSet):
    queryset = ServiceOffer.objects.select_related("professional", "category").all()
    serializer_class = ServiceOfferSerializer
    filterset_fields = ("mode", "city", "is_published", "category")
    search_fields = ("title", "description", "professional__user__full_name")
    ordering_fields = ("created_at", "amount")

    def get_permissions(self):
        if self.action in ("list", "retrieve"):
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        queryset = super().get_queryset()
        user = self.request.user
        if not user.is_authenticated:
            return queryset.filter(is_published=True)
        professional_profile = getattr(user, "professional_profile", None)
        if getattr(user, "role", None) == "professional" or professional_profile is not None:
            if professional_profile is None:
                return queryset.none()
            return queryset.filter(professional=professional_profile)
        return queryset.filter(is_published=True)

    def perform_create(self, serializer):
        professional = getattr(self.request.user, "professional_profile", None)
        if professional is None:
            raise PermissionDenied(
                "Creez d abord votre profil professionnel avant de publier une offre."
            )
        if getattr(self.request.user, "role", None) != "professional":
            self.request.user.role = "professional"
            self.request.user.save(update_fields=["role"])
        serializer.save(professional=professional)
