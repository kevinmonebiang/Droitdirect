from rest_framework import serializers

from bookings.models import BookingStatus, PaymentStatus as BookingPaymentStatus

from .models import Payment


class PaymentSerializer(serializers.ModelSerializer):
    ussd_code = serializers.CharField(read_only=True)
    booking_status = serializers.CharField(
        source="booking.status",
        read_only=True,
    )

    class Meta:
        model = Payment
        fields = (
            "id",
            "booking",
            "user",
            "amount",
            "currency",
            "provider",
            "transaction_ref",
            "status",
            "paid_at",
            "ussd_code",
            "booking_status",
        )

    def validate(self, attrs):
        booking = attrs.get("booking")
        user = attrs.get("user")
        provider = (attrs.get("provider") or "").strip().lower()

        if booking is None or user is None:
            return attrs

        if booking.user_id != user.id:
            raise serializers.ValidationError(
                "Ce paiement ne correspond pas au client connecte."
            )
        if booking.status != BookingStatus.ACCEPTED:
            raise serializers.ValidationError(
                "Le paiement n est disponible qu apres acceptation du professionnel."
            )
        if booking.payment_status == BookingPaymentStatus.PAID:
            raise serializers.ValidationError(
                "Cette reservation est deja payee."
            )
        if provider not in {"orange_money", "mtn_money"}:
            raise serializers.ValidationError(
                "Fournisseur de paiement invalide."
            )
        return attrs
