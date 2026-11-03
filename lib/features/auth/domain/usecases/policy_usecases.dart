import '../entities/policy.dart';
import '../repositories/auth_repository.dart';

class GetActivePolicy {
  const GetActivePolicy(this._repository);
  final AuthRepository _repository;

  Future<Policy?> call() => _repository.getActivePolicy();
}

class HasAgreedActivePolicy {
  const HasAgreedActivePolicy(this._repository);
  final AuthRepository _repository;

  Future<bool> call() => _repository.hasAgreedActivePolicy();
}

class AgreeToActivePolicy {
  const AgreeToActivePolicy(this._repository);
  final AuthRepository _repository;

  Future<void> call() => _repository.agreeToActivePolicy();
}
