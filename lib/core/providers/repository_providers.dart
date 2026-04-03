import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/booking/data/datasources/booking_remote_datasource.dart';
import '../../features/booking/data/repositories/booking_repository_impl.dart';
import '../../features/dashboard/data/datasources/admin_remote_datasource.dart';
import '../../features/messaging/data/datasources/messaging_remote_datasource.dart';
import '../../features/notifications/data/datasources/notifications_remote_datasource.dart';
import '../../features/professionals/data/datasources/professionals_remote_datasource.dart';
import '../../features/professionals/data/repositories/professionals_repository_impl.dart';
import '../../features/reviews/data/datasources/reviews_remote_datasource.dart';
import '../../features/services/data/datasources/services_remote_datasource.dart';
import '../../features/services/data/repositories/services_repository_impl.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

final professionalsRemoteDataSourceProvider =
    Provider<ProfessionalsRemoteDataSource>((ref) {
  return ProfessionalsRemoteDataSource(ref.watch(dioProvider));
});

final professionalsRepositoryProvider =
    Provider<ProfessionalsRepositoryImpl>((ref) {
  return ProfessionalsRepositoryImpl(
    ref.watch(professionalsRemoteDataSourceProvider),
  );
});

final servicesRemoteDataSourceProvider =
    Provider<ServicesRemoteDataSource>((ref) {
  return ServicesRemoteDataSource(ref.watch(dioProvider));
});

final servicesRepositoryProvider = Provider<ServicesRepositoryImpl>((ref) {
  return ServicesRepositoryImpl(ref.watch(servicesRemoteDataSourceProvider));
});

final bookingRemoteDataSourceProvider =
    Provider<BookingRemoteDataSource>((ref) {
  return BookingRemoteDataSource(ref.watch(dioProvider));
});

final bookingRepositoryProvider = Provider<BookingRepositoryImpl>((ref) {
  return BookingRepositoryImpl(ref.watch(bookingRemoteDataSourceProvider));
});

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSource(ref.watch(dioProvider));
});

final messagingRemoteDataSourceProvider =
    Provider<MessagingRemoteDataSource>((ref) {
  return MessagingRemoteDataSource(ref.watch(dioProvider));
});

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>((ref) {
  return NotificationsRemoteDataSource(ref.watch(dioProvider));
});

final reviewsRemoteDataSourceProvider = Provider<ReviewsRemoteDataSource>((ref) {
  return ReviewsRemoteDataSource(ref.watch(dioProvider));
});
