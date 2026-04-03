from django.contrib import admin

from .models import AvailabilitySlot, Booking, BookingIssueReport

admin.site.register(AvailabilitySlot)
admin.site.register(Booking)
admin.site.register(BookingIssueReport)
