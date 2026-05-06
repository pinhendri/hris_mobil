import '../core/constants/api_constants.dart';
import '../data/services/api_service.dart';
import '../models/company.dart';
import '../models/saas_models.dart';
import 'auth_provider.dart';
import 'package:flutter/material.dart';

class SaasProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isSwitchingCompany = false;
  String? _error;
  TrialStatus? _trialStatus;
  SaasContextSummary? _contextSummary;
  List<Company> _companies = const [];
  List<SaasInvitation> _invitations = const [];
  Map<String, dynamic>? _adminOverview;
  DateTime? _lastLoadedAt;

  bool get isLoading => _isLoading;
  bool get isSwitchingCompany => _isSwitchingCompany;
  String? get error => _error;
  TrialStatus? get trialStatus => _trialStatus;
  SaasContextSummary? get contextSummary => _contextSummary;
  Company? get currentCompany => _contextSummary?.currentCompany;
  List<Company> get companies => _companies;
  List<SaasInvitation> get invitations => _invitations;
  Map<String, dynamic>? get adminOverview => _adminOverview;
  DateTime? get lastLoadedAt => _lastLoadedAt;
  bool get hasLoadedData =>
      _lastLoadedAt != null ||
      _trialStatus != null ||
      _contextSummary != null ||
      _companies.isNotEmpty ||
      _invitations.isNotEmpty ||
      _adminOverview != null;
  int get pendingInvitationsCount => _invitations
      .where((invitation) => invitation.status.toLowerCase() == 'pending')
      .length;

  Future<void> loadWorkspace({
    required AuthProvider authProvider,
    bool includeAdminOverview = false,
    bool force = false,
  }) async {
    if (_isLoading && !force) {
      return;
    }

    _isLoading = true;
    if (force) {
      _error = null;
    }
    notifyListeners();

    try {
      final results = await Future.wait<_EndpointResult>([
        if (authProvider.canAccessSaasWorkspace)
          _safeGet(ApiConstants.saasContextEndpoint)
        else
          Future.value(const _EndpointResult(ok: false)),
        if (authProvider.canAccessSaasBilling)
          _safeGet(ApiConstants.saasTrialStatusEndpoint)
        else
          Future.value(const _EndpointResult(ok: false)),
        _safeGet(ApiConstants.saasCompaniesEndpoint),
        if (authProvider.canAccessSaasInvitations)
          _safeGet(ApiConstants.saasInvitationsEndpoint)
        else
          Future.value(const _EndpointResult(ok: false)),
        if (includeAdminOverview && authProvider.canAccessPlatformAdmin)
          _safeGet(ApiConstants.saasAdminOverviewEndpoint),
      ]);

      final contextResult = results[0];
      final trialResult = results[1];
      final companiesResult = results[2];
      final invitationsResult = results[3];
      final adminResult = includeAdminOverview && results.length > 4
          ? results[4]
          : null;

      if (contextResult.ok && contextResult.data is Map<String, dynamic>) {
        _contextSummary = SaasContextSummary.fromMap(
          contextResult.data! as Map<String, dynamic>,
        );
      }

      if (trialResult.ok && trialResult.data is Map<String, dynamic>) {
        _trialStatus = TrialStatus.fromMap(
          trialResult.data! as Map<String, dynamic>,
        );
      }

      if (companiesResult.ok) {
        _companies = _parseCompanies(companiesResult.data);
      }

      if (invitationsResult.ok) {
        _invitations = _parseInvitations(invitationsResult.data);
      }

      if (adminResult != null && adminResult.ok) {
        final payload = adminResult.data;
        _adminOverview = payload is Map<String, dynamic> ? payload : null;
      } else if (!includeAdminOverview) {
        _adminOverview = null;
      }

      if (!contextResult.ok &&
          !trialResult.ok &&
          !companiesResult.ok &&
          !invitationsResult.ok) {
        if (authProvider.canAccessAnySaasWorkspace) {
          throw Exception(contextResult.error ?? trialResult.error ?? 'Failed');
        }
      }

      _lastLoadedAt = DateTime.now();
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> switchCompany({
    required AuthProvider authProvider,
    required Company company,
    bool includeAdminOverview = false,
  }) async {
    _isSwitchingCompany = true;
    notifyListeners();

    try {
      final result = await authProvider.setSelectedCompany(
        companyId: company.id,
        cCode: company.cCode,
      );

      if (result['success'] == true) {
        await authProvider.getUserInfo();
        await loadWorkspace(
          authProvider: authProvider,
          includeAdminOverview: includeAdminOverview,
          force: true,
        );
      }

      return result;
    } finally {
      _isSwitchingCompany = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createInvitation({
    required AuthProvider authProvider,
    required String email,
    String name = '',
    String role = 'member',
    String authMode = 'either',
    bool includeAdminOverview = false,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.saasInvitationsEndpoint,
        {'email': email, 'name': name, 'role': role, 'auth_mode': authMode},
      );

      await loadWorkspace(
        authProvider: authProvider,
        includeAdminOverview: includeAdminOverview,
        force: true,
      );

      final payload = response is Map<String, dynamic> ? response : {};

      return {
        'success': true,
        'message':
            payload['message']?.toString() ?? 'Invitation sent successfully.',
        'data': payload['data'],
      };
    } catch (error) {
      return {'success': false, 'message': error.toString()};
    }
  }

  Future<Map<String, dynamic>> revokeInvitation({
    required AuthProvider authProvider,
    required int invitationId,
    bool includeAdminOverview = false,
  }) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.saasInvitationsEndpoint}/$invitationId',
      );

      await loadWorkspace(
        authProvider: authProvider,
        includeAdminOverview: includeAdminOverview,
        force: true,
      );

      final payload = response is Map<String, dynamic> ? response : {};

      return {
        'success': true,
        'message': payload['message']?.toString() ?? 'Invitation revoked.',
        'data': payload['data'],
      };
    } catch (error) {
      return {'success': false, 'message': error.toString()};
    }
  }

  Future<_EndpointResult> _safeGet(String endpoint) async {
    try {
      final response = await _apiService.get(endpoint);
      if (response is Map<String, dynamic>) {
        final payload = response['data'] ?? response;
        return _EndpointResult(ok: true, data: payload);
      }

      return _EndpointResult(ok: true, data: response);
    } catch (error) {
      return _EndpointResult(ok: false, error: error.toString());
    }
  }

  List<Company> _parseCompanies(dynamic payload) {
    final source = payload is List
        ? payload
        : payload is Map<String, dynamic> && payload['data'] is List
        ? payload['data'] as List
        : const [];

    return source
        .whereType<Map>()
        .map((company) => Company.fromMap(Map<String, dynamic>.from(company)))
        .toList(growable: false);
  }

  List<SaasInvitation> _parseInvitations(dynamic payload) {
    final source = payload is List
        ? payload
        : payload is Map<String, dynamic> && payload['data'] is List
        ? payload['data'] as List
        : const [];

    return source
        .whereType<Map>()
        .map(
          (invitation) =>
              SaasInvitation.fromMap(Map<String, dynamic>.from(invitation)),
        )
        .toList(growable: false);
  }
}

class _EndpointResult {
  final bool ok;
  final Object? data;
  final String? error;

  const _EndpointResult({required this.ok, this.data, this.error});
}
