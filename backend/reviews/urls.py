from django.urls import path

from .views import ProfessionalReviewListView, ReviewCreateView

urlpatterns = [
    path("reviews", ReviewCreateView.as_view(), name="reviews-create"),
    path("professionals/<uuid:professional_id>/reviews", ProfessionalReviewListView.as_view(), name="professionals-reviews"),
]
