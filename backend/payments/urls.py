from django.urls import path

from .views import (
    PaymentDetailView,
    PaymentListView,
    PaymentReceiptView,
    confirm_payment,
    initiate_payment,
    payment_webhook,
)

urlpatterns = [
    path("payments", PaymentListView.as_view(), name="payments-list"),
    path("payments/initiate", initiate_payment, name="payments-initiate"),
    path("payments/confirm", confirm_payment, name="payments-confirm"),
    path("payments/webhook", payment_webhook, name="payments-webhook"),
    path("payments/<uuid:pk>", PaymentDetailView.as_view(), name="payments-detail"),
    path("payments/<uuid:pk>/receipt", PaymentReceiptView.as_view(), name="payments-receipt"),
]
