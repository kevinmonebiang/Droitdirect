from django.utils import timezone
from rest_framework import generics, parsers, permissions, response, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from bookings.models import Booking, BookingIssueReport, BookingIssueReportStatus
from bookings.serializers import BookingSerializer
from professionals.models import ProfessionalProfile
from professionals.serializers import AdminProfessionalProfileSerializer

from .models import User
from .permissions import IsPlatformAdmin
from .serializers import (
    AdminUserSerializer,
    CamrlexTokenSerializer,
    OTPSerializer,
    RegisterSerializer,
    UserSerializer,
)


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [AllowAny]


class LoginView(TokenObtainPairView):
    permission_classes = [AllowAny]
    serializer_class = CamrlexTokenSerializer

    def post(self, request, *args, **kwargs):
        result = super().post(request, *args, **kwargs)
        user = User.objects.filter(email=request.data.get("email", "")).first()
        if user is not None:
            professional_profile = getattr(user, "professional_profile", None)
            if professional_profile is not None:
                professional_profile.is_online = True
                professional_profile.last_seen_at = timezone.now()
                professional_profile.save(update_fields=["is_online", "last_seen_at"])
        return result


class RefreshView(TokenRefreshView):
    permission_classes = [AllowAny]


class MeView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = (parsers.MultiPartParser, parsers.FormParser, parsers.JSONParser)

    def get_object(self):
        professional_profile = getattr(self.request.user, "professional_profile", None)
        if professional_profile is not None:
            if self.request.user.role != "professional":
                self.request.user.role = "professional"
                self.request.user.save(update_fields=["role"])
            professional_profile.is_online = True
            professional_profile.last_seen_at = timezone.now()
            professional_profile.save(update_fields=["is_online", "last_seen_at"])
        return self.request.user

    def update(self, request, *args, **kwargs):
        kwargs["partial"] = True
        return super().update(request, *args, **kwargs)


class AdminOverviewView(generics.GenericAPIView):
    permission_classes = [permissions.IsAuthenticated, IsPlatformAdmin]

    def get(self, request, *args, **kwargs):
        users = User.objects.order_by("-created_at")
        professionals = (
            ProfessionalProfile.objects.select_related("user")
            .prefetch_related("verification_documents", "reviews__user")
            .order_by("-user__created_at")
        )
        bookings = (
            Booking.objects.select_related("user", "professional__user", "service")
            .order_by("-created_at")
        )
        issue_reports = (
            BookingIssueReport.objects.select_related(
                "booking",
                "booking__user",
                "booking__professional__user",
                "booking__service",
                "booking__payment",
            )
            .order_by("-updated_at", "-created_at")
        )

        return response.Response(
            {
                "metrics": {
                    "total_users": users.count(),
                    "total_professionals": professionals.count(),
                    "verified_professionals": professionals.filter(
                        verification_status="verified"
                    ).count(),
                    "pending_professionals": professionals.exclude(
                        verification_status="verified"
                    ).count(),
                    "total_bookings": bookings.count(),
                    "pending_bookings": bookings.filter(status="pending").count(),
                    "open_disputes": issue_reports.filter(
                        status__in=[
                            BookingIssueReportStatus.OPEN,
                            BookingIssueReportStatus.UNDER_REVIEW,
                        ]
                    ).count(),
                    "refund_requests": issue_reports.filter(
                        wants_refund=True
                    ).count(),
                },
                "users": AdminUserSerializer(users, many=True).data,
                "professionals": AdminProfessionalProfileSerializer(
                    professionals, many=True
                ).data,
                "bookings": BookingSerializer(bookings, many=True).data,
                "issue_reports": [
                    {
                        "id": str(report.id),
                        "booking_id": str(report.booking_id),
                        "service_title": report.booking.service.title,
                        "client_name": report.booking.user.full_name,
                        "professional_name": report.booking.professional.user.full_name,
                        "reason": report.reason,
                        "details": report.details,
                        "wants_refund": report.wants_refund,
                        "status": report.status,
                        "admin_note": report.admin_note,
                        "booking_status": report.booking.status,
                        "payment_status": report.booking.payment_status,
                        "amount": str(report.booking.amount),
                        "transaction_ref": (
                            report.booking.payment.transaction_ref
                            if hasattr(report.booking, "payment")
                            else ""
                        ),
                        "created_at": report.created_at.isoformat(),
                        "updated_at": report.updated_at.isoformat(),
                    }
                    for report in issue_reports
                ],
            }
        )


@api_view(["POST"])
@permission_classes([AllowAny])
def verify_otp(request):
    serializer = OTPSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    return response.Response({"detail": "OTP verified (stub)."})


@api_view(["POST"])
def logout_view(request):
    professional_profile = getattr(request.user, "professional_profile", None)
    if professional_profile is not None:
        professional_profile.is_online = False
        professional_profile.last_seen_at = timezone.now()
        professional_profile.save(update_fields=["is_online", "last_seen_at"])
    refresh_token = request.data.get("refresh")
    if refresh_token:
        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
        except Exception:
            pass
    return response.Response(status=status.HTTP_204_NO_CONTENT)
