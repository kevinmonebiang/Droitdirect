import uuid

from django.db import transaction
from django.http import HttpResponse
from django.utils import timezone
from rest_framework import generics, permissions, response, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny

from bookings.models import PaymentStatus as BookingPaymentStatus
from messaging.models import Conversation
from notifications_app.models import Notification

from .models import Payment
from .serializers import PaymentSerializer


class PaymentDetailView(generics.RetrieveAPIView):
    queryset = Payment.objects.select_related("booking", "user").all()
    serializer_class = PaymentSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def get_queryset(self):
        queryset = super().get_queryset()
        if getattr(self.request.user, "role", None) == "admin":
            return queryset
        return queryset.filter(user=self.request.user)


class PaymentListView(generics.ListAPIView):
    serializer_class = PaymentSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def get_queryset(self):
        queryset = Payment.objects.select_related("booking", "user").order_by("-paid_at", "-id")
        if getattr(self.request.user, "role", None) == "admin":
            return queryset
        return queryset.filter(user=self.request.user)


class PaymentReceiptView(generics.RetrieveAPIView):
    queryset = Payment.objects.select_related(
        "booking",
        "booking__service",
        "booking__professional",
        "booking__professional__user",
        "user",
    ).all()
    serializer_class = PaymentSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def get_queryset(self):
        queryset = super().get_queryset()
        if getattr(self.request.user, "role", None) == "admin":
            return queryset
        return queryset.filter(user=self.request.user)

    def retrieve(self, request, *args, **kwargs):
        payment = self.get_object()
        pdf_content = _build_receipt_pdf(payment)
        response_pdf = HttpResponse(pdf_content, content_type="application/pdf")
        response_pdf["Content-Disposition"] = (
            f'attachment; filename="recu-{payment.transaction_ref}.pdf"'
        )
        return response_pdf


@api_view(["POST"])
@permission_classes([permissions.IsAuthenticated])
def initiate_payment(request):
    payload = request.data.copy()
    booking_id = payload.get("booking")
    provider = (payload.get("provider") or "").strip().lower()
    amount = payload.get("amount")
    currency = payload.get("currency") or "XAF"

    existing_payment = None
    if booking_id:
        existing_payment = Payment.objects.filter(booking_id=booking_id).first()

    serializer = PaymentSerializer(
        existing_payment,
        data={
            "booking": booking_id,
            "user": request.user.id,
            "amount": amount,
            "currency": currency,
            "provider": provider,
            "transaction_ref": (
                existing_payment.transaction_ref
                if existing_payment is not None
                else f"DD-{uuid.uuid4().hex[:10].upper()}"
            ),
            "status": existing_payment.status if existing_payment is not None else "pending",
        },
        partial=existing_payment is not None,
    )
    serializer.is_valid(raise_exception=True)
    payment = serializer.save(user=request.user)
    data = PaymentSerializer(payment).data
    data["ussd_code"] = _ussd_code(provider, payment.amount)
    return response.Response(
        data,
        status=(
            status.HTTP_200_OK
            if existing_payment is not None
            else status.HTTP_201_CREATED
        ),
    )


@api_view(["POST"])
@permission_classes([permissions.IsAuthenticated])
@transaction.atomic
def confirm_payment(request):
    payment_id = request.data.get("payment_id")
    if not payment_id:
        return response.Response(
            {"detail": "payment_id est requis."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    payment = Payment.objects.select_related(
        "booking",
        "booking__service",
        "booking__professional",
        "booking__professional__user",
        "user",
    ).filter(pk=payment_id, user=request.user).first()
    if payment is None:
        return response.Response(
            {"detail": "Paiement introuvable."},
            status=status.HTTP_404_NOT_FOUND,
        )

    payment.status = "paid"
    payment.paid_at = timezone.now()
    payment.save(update_fields=["status", "paid_at"])

    booking = payment.booking
    booking.payment_status = BookingPaymentStatus.PAID
    booking.save(update_fields=["payment_status"])

    Notification.objects.create(
        user=booking.professional.user,
        title="Paiement confirme",
        body=(
            f"{booking.user.full_name} a confirme le paiement de "
            f"{booking.service.title}."
        ),
        type="payment_confirmed",
    )

    conversation, _ = Conversation.objects.get_or_create(
        booking=booking,
        user=booking.user,
        professional=booking.professional,
    )

    data = PaymentSerializer(payment).data
    data["conversation_id"] = str(conversation.id)
    return response.Response(data, status=status.HTTP_200_OK)


@api_view(["POST"])
@permission_classes([AllowAny])
def payment_webhook(request):
    return response.Response({"detail": "Webhook received."})


def _ussd_code(provider, amount):
    safe_amount = int(float(amount))
    if provider == "orange_money":
        return f"#150*46*0780539*{safe_amount}*2#"
    if provider == "mtn_money":
        return f"*126*4*752923*{safe_amount}#"
    return ""


def _build_receipt_pdf(payment):
    booking = payment.booking
    lines = [
        "RECU DE PAIEMENT - DROITDIRECT",
        "",
        f"Reference: {payment.transaction_ref}",
        f"Client: {payment.user.full_name}",
        f"Professionnel: {booking.professional.user.full_name}",
        f"Service: {booking.service.title}",
        f"Montant: {payment.amount} {payment.currency}",
        f"Statut: {payment.status}",
        f"Date paiement: {payment.paid_at.strftime('%Y-%m-%d %H:%M') if payment.paid_at else 'En attente'}",
        f"Reservation: {booking.appointment_date} {booking.start_time}",
        "",
        "DroitDirect - La justice, sans detour",
    ]
    return _simple_pdf_bytes(lines)


def _simple_pdf_bytes(lines):
    safe_lines = [line.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)") for line in lines]
    stream_lines = ["BT", "/F1 16 Tf", "50 790 Td"]
    first = True
    for line in safe_lines:
        if first:
            stream_lines.append(f"({line}) Tj")
            first = False
        else:
            stream_lines.append("0 -24 Td")
            stream_lines.append(f"({line}) Tj")
    stream_lines.append("ET")
    stream = "\n".join(stream_lines).encode("latin-1", errors="ignore")

    objects = []
    objects.append(b"1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n")
    objects.append(b"2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n")
    objects.append(
        b"3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >> endobj\n"
    )
    objects.append(
        f"4 0 obj << /Length {len(stream)} >> stream\n".encode("latin-1")
        + stream
        + b"\nendstream endobj\n"
    )
    objects.append(
        b"5 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n"
    )

    pdf = b"%PDF-1.4\n"
    offsets = [0]
    for obj in objects:
        offsets.append(len(pdf))
        pdf += obj
    xref_offset = len(pdf)
    pdf += f"xref\n0 {len(objects) + 1}\n".encode("latin-1")
    pdf += b"0000000000 65535 f \n"
    for offset in offsets[1:]:
        pdf += f"{offset:010d} 00000 n \n".encode("latin-1")
    pdf += (
        f"trailer << /Size {len(objects) + 1} /Root 1 0 R >>\nstartxref\n{xref_offset}\n%%EOF".encode(
            "latin-1"
        )
    )
    return pdf
