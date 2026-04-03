from django.db import transaction
from rest_framework import decorators, permissions, response, status, viewsets
from rest_framework.exceptions import PermissionDenied

from messaging.models import Conversation
from notifications_app.models import Notification

from accounts.models import UserRole

from .models import (
    AvailabilitySlot,
    Booking,
    BookingIssueReport,
    BookingIssueReportStatus,
    BookingStatus,
    PaymentStatus,
)
from .serializers import (
    AvailabilitySlotSerializer,
    BookingIssueReportSerializer,
    BookingSerializer,
)


class AvailabilitySlotViewSet(viewsets.ModelViewSet):
    queryset = AvailabilitySlot.objects.select_related("professional", "professional__user").all()
    serializer_class = AvailabilitySlotSerializer
    permission_classes = (permissions.IsAuthenticated,)
    filterset_fields = ("professional", "day_of_week", "is_available")
    ordering_fields = ("day_of_week", "start_time", "end_time")

    def get_queryset(self):
        queryset = super().get_queryset()
        user = self.request.user
        if not user.is_authenticated:
            return queryset.none()

        professional_id = self.request.query_params.get("professional")
        if getattr(user, "role", None) == "admin":
            if professional_id:
                return queryset.filter(professional_id=professional_id).order_by(
                    "day_of_week",
                    "start_time",
                )
            return queryset.order_by("day_of_week", "start_time")

        own_profile = getattr(user, "professional_profile", None)
        if getattr(user, "role", None) == "professional" or own_profile is not None:
            own_queryset = queryset.filter(professional__user=user)
            if professional_id:
                return own_queryset.filter(professional_id=professional_id).order_by(
                    "day_of_week",
                    "start_time",
                )
            return own_queryset.order_by("day_of_week", "start_time")

        if professional_id:
            return queryset.filter(
                professional_id=professional_id,
                is_available=True,
            ).order_by("day_of_week", "start_time")
        return queryset.none()

    def perform_create(self, serializer):
        professional = getattr(self.request.user, "professional_profile", None)
        if professional is None:
            raise PermissionDenied(
                "Creez d abord votre profil professionnel avant d ajouter des creneaux."
            )
        if getattr(self.request.user, "role", None) != "professional":
            self.request.user.role = "professional"
            self.request.user.save(update_fields=["role"])
        serializer.save(professional=professional)

    def perform_update(self, serializer):
        slot = self.get_object()
        if slot.professional.user_id != self.request.user.id:
            raise PermissionDenied(
                "Vous ne pouvez pas modifier cette disponibilite."
            )
        if getattr(self.request.user, "role", None) != "professional":
            self.request.user.role = "professional"
            self.request.user.save(update_fields=["role"])
        serializer.save()

    def perform_destroy(self, instance):
        if instance.professional.user_id != self.request.user.id:
            raise PermissionDenied(
                "Vous ne pouvez pas supprimer cette disponibilite."
            )
        instance.delete()


class BookingViewSet(viewsets.ModelViewSet):
    queryset = Booking.objects.select_related("user", "professional", "service").all()
    serializer_class = BookingSerializer
    permission_classes = (permissions.IsAuthenticated,)
    filterset_fields = ("status", "payment_status", "booking_type", "professional", "urgency")
    ordering_fields = ("appointment_date", "created_at")

    def get_queryset(self):
        queryset = super().get_queryset()
        user = self.request.user
        if not user.is_authenticated:
            return queryset.none()
        if getattr(user, "role", None) == "admin":
            return queryset.order_by("-created_at")
        if getattr(user, "role", None) == "professional":
            return queryset.filter(professional__user=user).order_by("-created_at")
        return queryset.filter(user=user).order_by("-created_at")

    @transaction.atomic
    def perform_create(self, serializer):
        if getattr(self.request.user, "role", None) != "client":
            raise PermissionDenied(
                "Seuls les clients peuvent creer une reservation."
            )

        service = serializer.validated_data["service"]
        booking = serializer.save(
            user=self.request.user,
            professional=service.professional,
            amount=service.amount,
            onsite_address=service.address,
        )
        conversation, _ = Conversation.objects.get_or_create(
            booking=booking,
            user=booking.user,
            professional=booking.professional,
        )
        Notification.objects.create(
            user=booking.professional.user,
            title="Nouvelle reservation",
            body=(
                f"{booking.user.full_name} a demande le service "
                f"{booking.service.title} pour '{booking.issue_title}' "
                f"({booking.urgency})."
            ),
            type="booking_request",
        )

    @decorators.action(detail=True, methods=["put"])
    def accept(self, request, pk=None):
        booking = self.get_object()
        if getattr(request.user, "role", None) != "professional" or booking.professional.user_id != request.user.id:
            raise PermissionDenied(
                "Seul le professionnel concerne peut accepter cette reservation."
            )

        booking.status = "accepted"
        booking.meeting_link = (request.data.get("meeting_link") or booking.meeting_link).strip()
        booking.onsite_address = (request.data.get("onsite_address") or booking.onsite_address).strip()
        booking.save(update_fields=["status", "meeting_link", "onsite_address"])
        self._notify_booking_update(
            booking=booking,
            title="Reservation acceptee",
            body=(
                f"{booking.professional.user.full_name} a accepte votre demande "
                f"pour {booking.service.title}."
            ),
            notification_type="booking_accepted",
        )
        return response.Response(self.get_serializer(booking).data)

    @decorators.action(detail=True, methods=["put"])
    def reject(self, request, pk=None):
        booking = self.get_object()
        if getattr(request.user, "role", None) != "professional" or booking.professional.user_id != request.user.id:
            raise PermissionDenied(
                "Seul le professionnel concerne peut refuser cette reservation."
            )
        booking.status = "rejected"
        booking.save(update_fields=["status"])
        self._notify_booking_update(
            booking=booking,
            title="Reservation refusee",
            body=(
                f"{booking.professional.user.full_name} a refuse votre demande "
                f"pour {booking.service.title}."
            ),
            notification_type="booking_rejected",
        )
        return response.Response(self.get_serializer(booking).data)

    @decorators.action(detail=True, methods=["put"])
    def cancel(self, request, pk=None):
        booking = self.get_object()
        if booking.user_id != request.user.id and getattr(request.user, "role", None) != "admin":
            raise PermissionDenied(
                "Vous ne pouvez pas annuler cette reservation."
            )
        booking.status = "cancelled"
        booking.save(update_fields=["status"])
        return response.Response(self.get_serializer(booking).data)

    @decorators.action(detail=True, methods=["put"])
    def complete(self, request, pk=None):
        booking = self.get_object()
        if getattr(request.user, "role", None) != "professional" or booking.professional.user_id != request.user.id:
            raise PermissionDenied(
                "Seul le professionnel concerne peut terminer cette reservation."
            )
        booking.status = "completed"
        booking.save(update_fields=["status"])
        return response.Response(self.get_serializer(booking).data)

    @decorators.action(detail=True, methods=["post"], url_path="report-issue")
    def report_issue(self, request, pk=None):
        booking = self.get_object()
        if booking.user_id != request.user.id and getattr(request.user, "role", None) != UserRole.ADMIN:
            raise PermissionDenied(
                "Vous ne pouvez signaler qu une reservation qui vous appartient."
            )

        instance = BookingIssueReport.objects.filter(booking=booking).first()
        serializer = BookingIssueReportSerializer(
            instance,
            data=request.data,
            partial=instance is not None,
        )
        serializer.is_valid(raise_exception=True)
        report = serializer.save(
            booking=booking,
            user=booking.user,
        )

        if booking.status != BookingStatus.COMPLETED:
            booking.status = BookingStatus.DISPUTED
            booking.save(update_fields=["status"])

        Notification.objects.create(
            user=booking.professional.user,
            title="Signalement client",
            body=(
                f"{booking.user.full_name} a signale un probleme sur "
                f"{booking.service.title}."
            ),
            type="booking_dispute",
        )
        for admin_user in request.user.__class__.objects.filter(role=UserRole.ADMIN):
            Notification.objects.create(
                user=admin_user,
                title="Nouveau litige",
                body=(
                    f"Un signalement a ete soumis pour la reservation "
                    f"{booking.service.title}."
                ),
                type="booking_dispute",
            )

        data = BookingIssueReportSerializer(report).data
        data["booking_status"] = booking.status
        return response.Response(data, status=status.HTTP_200_OK)

    @decorators.action(detail=True, methods=["put"], url_path="review-issue")
    @transaction.atomic
    def review_issue(self, request, pk=None):
        booking = self.get_object()
        if getattr(request.user, "role", None) != UserRole.ADMIN:
            raise PermissionDenied(
                "Seul un administrateur peut traiter un litige."
            )

        report = getattr(booking, "issue_report", None)
        if report is None:
            return response.Response(
                {"detail": "Aucun signalement n est rattache a cette reservation."},
                status=status.HTTP_404_NOT_FOUND,
            )

        next_status = (request.data.get("status") or "").strip().lower()
        admin_note = (request.data.get("admin_note") or "").strip()
        allowed_statuses = {
            BookingIssueReportStatus.OPEN,
            BookingIssueReportStatus.UNDER_REVIEW,
            BookingIssueReportStatus.RESOLVED,
            BookingIssueReportStatus.REFUND_APPROVED,
            BookingIssueReportStatus.REFUND_REJECTED,
        }
        if next_status not in allowed_statuses:
            return response.Response(
                {"detail": "Statut de litige invalide."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        report.status = next_status
        report.admin_note = admin_note
        report.save(update_fields=["status", "admin_note", "updated_at"])

        booking_updates = []
        if next_status == BookingIssueReportStatus.REFUND_APPROVED:
            booking.payment_status = PaymentStatus.REFUNDED
            booking.status = BookingStatus.CANCELLED
            booking_updates.extend(["payment_status", "status"])
            payment = getattr(booking, "payment", None)
            if payment is not None:
                from payments.models import PaymentStatus as RealPaymentStatus

                payment.status = RealPaymentStatus.REFUNDED
                payment.save(update_fields=["status"])
        elif next_status == BookingIssueReportStatus.RESOLVED:
            if booking.status == BookingStatus.DISPUTED:
                booking.status = (
                    BookingStatus.COMPLETED
                    if booking.payment_status == PaymentStatus.PAID
                    else BookingStatus.ACCEPTED
                )
                booking_updates.append("status")
        elif next_status in {
            BookingIssueReportStatus.OPEN,
            BookingIssueReportStatus.UNDER_REVIEW,
            BookingIssueReportStatus.REFUND_REJECTED,
        }:
            if booking.status != BookingStatus.COMPLETED:
                booking.status = BookingStatus.DISPUTED
                booking_updates.append("status")

        if booking_updates:
            booking.save(update_fields=booking_updates)

        status_label = {
            BookingIssueReportStatus.OPEN: "ouvert",
            BookingIssueReportStatus.UNDER_REVIEW: "en cours d examen",
            BookingIssueReportStatus.RESOLVED: "resolu",
            BookingIssueReportStatus.REFUND_APPROVED: "remboursement approuve",
            BookingIssueReportStatus.REFUND_REJECTED: "remboursement refuse",
        }[next_status]

        for target in (booking.user, booking.professional.user):
            Notification.objects.create(
                user=target,
                title="Mise a jour du litige",
                body=(
                    f"Le signalement sur {booking.service.title} est maintenant "
                    f"{status_label}."
                ),
                type="booking_dispute_update",
            )

        data = BookingIssueReportSerializer(report).data
        data["booking_status"] = booking.status
        data["payment_status"] = booking.payment_status
        return response.Response(data, status=status.HTTP_200_OK)

    def _notify_booking_update(
        self,
        *,
        booking,
        title,
        body,
        notification_type,
    ):
        Notification.objects.create(
            user=booking.user,
            title=title,
            body=body,
            type=notification_type,
        )
