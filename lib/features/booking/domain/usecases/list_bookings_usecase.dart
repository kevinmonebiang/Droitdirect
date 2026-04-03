import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

class ListBookingsUseCase {
  const ListBookingsUseCase(this._repository);

  final BookingRepository _repository;

  Future<List<BookingEntity>> call() {
    return _repository.listBookings();
  }
}
