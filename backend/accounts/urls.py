from django.urls import path

from .views import AdminOverviewView, LoginView, MeView, RefreshView, RegisterView, logout_view, verify_otp

urlpatterns = [
    path("auth/register", RegisterView.as_view(), name="auth-register"),
    path("auth/login", LoginView.as_view(), name="auth-login"),
    path("auth/verify-otp", verify_otp, name="auth-verify-otp"),
    path("auth/logout", logout_view, name="auth-logout"),
    path("auth/refresh", RefreshView.as_view(), name="auth-refresh"),
    path("me", MeView.as_view(), name="me"),
    path("admin/overview", AdminOverviewView.as_view(), name="admin-overview"),
]
