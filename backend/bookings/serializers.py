from rest_framework import serializers

from messaging.models import Conversation
from professionals.models import VerificationStatus

from .models import (
    AvailabilitySlot,
    Booking,
    BookingIssueReport,
    BookingIssueReportStatus,
    BookingStatus,
)


class AvailabilitySlotSerializer(serializers.ModelSerializer):
    def validate(self, attrs):
        instance = getattr(self, "instance", None)
        day_of_week = attrs.get("day_of_week", getattr(instance, "day_of_week", 0))
        start_time = attrs.get("start_time", getattr(instance, "start_time", None))
        end_time = attrs.get("end_time", getattr(instance, "end_time", None))

        if day_of_week < 1 or day_of_week > 7:
            raise serializers.ValidationError(
                "Le jour de disponibilite doit etre compris entre 1 et 7."
            )
        if start_time is not None and end_time is not None and start_time >= end_time:
            raise serializers.ValidationError(
                "L heure de fin doit etre apres l heure de debut."
            )
        return attrs

    class Meta:
        model = AvailabilitySlot
        fields = (
            "id",
            "professional",
            "day_of_week",
            "start_time",
            "end_time",
            "is_available",
            "slot_duration",
        )
        read_only_fields = ("professional",)


class BookingSerializer(serializers.ModelSerializer):
    service_title = serializers.CharField(source="service.title", read_only=True)
    client_name = serializers.CharField(source="user.full_name", read_only=True)
    professional_name = serializers.CharField(
        source="professional.user.full_name",
        read_only=True,
    )
    conversation_id = serializers.SerializerMethodField(read_only=True)
    has_review = serializers.SerializerMethodField(read_only=True)
    payment_id = serializers.SerializerMethodField(read_only=True)
    issue_report_status = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Booking
        fields = (
            "id",
            "user",
            "professional",
            "service",
            "issue_title",
            "issue_summary",
            "urgency",
            "booking_type",
            "appointment_date",
            "start_time",
            "end_time",
            "amount",
            "status",
            "payment_status",
            "meeting_link",
            "onsite_address",
            "note",
            "created_at",
            "service_title",
            "client_name",
            "professional_name",
            "conversation_id",
            "has_review",
            "payment_id",
            "issue_report_status",
        )
        read_only_fields = (
            "user",
            "professional",
            "amount",
            "status",
            "payment_status",
            "created_at",
        )

    def validate(self, attrs):
        service = attrs.get("service")
        professional = attrs.get("professional") or (service.professional if service else None)
        current_title = getattr(self.instance, "issue_title", "")
        current_summary = getattr(self.instance, "issue_summary", "")
        issue_title = (attrs.get("issue_title") or current_title or "").strip()
        issue_summary = (attrs.get("issue_summary") or current_summary or "").strip()
        urgency = (attrs.get("urgency") or getattr(self.instance, "urgency", "") or "").strip().lower()
        appointment_date = attrs.get(
            "appointment_date",
            getattr(self.instance, "appointment_date", None),
        )
        start_time = attrs.get("start_time", getattr(self.instance, "start_time", None))
        end_time = attrs.get("end_time", getattr(self.instance, "end_time", None))

        if self.instance is None:
            if not issue_title:
                raise serializers.ValidationError(
                    "Le titre du probleme est requis."
                )
            if not issue_summary:
                raise serializers.ValidationError(
                    "Le resume du probleme est requis."
                )

        if service and professional and service.professional_id != professional.id:
            raise serializers.ValidationError(
                "Le service selectionne ne correspond pas au professionnel."
            )
        if professional and professional.verification_status != VerificationStatus.VERIFIED:
            raise serializers.ValidationError(
                "Un professionnel non valide ne peut pas recevoir de reservation."
            )
        if service and not service.is_published:
            raise serializers.ValidationError(
                "Ce service n est pas disponible pour la reservation."
            )
        if urgency not in {"urgent", "medium"}:
            raise serializers.ValidationError(
                "Le niveau d urgence doit etre urgent ou medium."
            )
        if (
            appointment_date is not None
            and start_time is not None
            and end_time is not None
            and start_time >= end_time
        ):
            raise serializers.ValidationError(
                "L heure de fin doit etre apres l heure de debut."
            )
        if professional and appointment_date and start_time and end_time:
            day_of_week = appointment_date.isoweekday()
            matching_slot = AvailabilitySlot.objects.filter(
                professional=professional,
                day_of_week=day_of_week,
                is_available=True,
                start_time__lte=start_time,
                end_time__gte=end_time,
            ).exists()
            if not matching_slot:
                raise serializers.ValidationError(
                    "Ce creneau ne correspond pas aux disponibilites du professionnel."
                )

            overlaps = Booking.objects.filter(
                professional=professional,
                appointment_date=appointment_date,
                start_time__lt=end_time,
                end_time__gt=start_time,
                status__in=[
                    BookingStatus.PENDING,
                    BookingStatus.ACCEPTED,
                    BookingStatus.COMPLETED,
                ],
            )
            if self.instance is not None:
                overlaps = overlaps.exclude(pk=self.instance.pk)
            if overlaps.exists():
                raise serializers.ValidationError(
                    "Ce creneau est deja reserve. Veuillez choisir une autre disponibilite."
                )
        attrs["issue_title"] = issue_title
        attrs["issue_summary"] = issue_summary
        attrs["urgency"] = urgency
        return attrs

    def get_conversation_id(self, obj):
        conversation = Conversation.objects.filter(booking=obj).first()
        return str(conversation.id) if conversation is not None else ""

    def get_has_review(self, obj):
        return hasattr(obj, "review")

    def get_payment_id(self, obj):
        payment = getattr(obj, "payment", None)
        return str(payment.id) if payment is not None else ""

    def get_issue_report_status(self, obj):
        report = getattr(obj, "issue_report", None)
        return report.status if report is not None else ""


class BookingIssueReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = BookingIssueReport
        fields = (
            "id",
            "booking",
            "user",
            "reason",
            "details",
            "wants_refund",
            "status",
            "admin_note",
            "created_at",
            "updated_at",
        )
        read_only_fields = (
            "booking",
            "user",
            "status",
            "admin_note",
            "created_at",
            "updated_at",
        )

    def validate(self, attrs):
        instance = getattr(self, "instance", None)
        reason = (attrs.get("reason") or getattr(instance, "reason", "")).strip()
        if not reason:
            raise serializers.ValidationError(
                "Le motif du signalement est requis."
            )
        return attrs
