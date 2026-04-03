from rest_framework import generics, permissions

from .models import Review
from .serializers import ReviewSerializer


class ReviewCreateView(generics.CreateAPIView):
    queryset = Review.objects.select_related("booking", "user", "professional").all()
    serializer_class = ReviewSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def perform_create(self, serializer):
        booking = serializer.validated_data["booking"]
        serializer.save(user=self.request.user, professional=booking.professional)


class ProfessionalReviewListView(generics.ListAPIView):
    serializer_class = ReviewSerializer

    def get_queryset(self):
        return Review.objects.filter(professional_id=self.kwargs["professional_id"]).select_related("user", "booking")
