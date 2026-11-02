import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/evacuation_point.dart';

class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.token,
  });

  final int id;
  final String name;
  final String email;
  final String token;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.homeAddress,
    this.profilePhotoPath,
    this.homeLatitude,
    this.homeLongitude,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? homeAddress;
  final double? homeLatitude;
  final double? homeLongitude;
  final String? profilePhotoPath;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      homeAddress: json['home_address']?.toString(),
      homeLatitude: double.tryParse(json['home_latitude']?.toString() ?? ''),
      homeLongitude: double.tryParse(json['home_longitude']?.toString() ?? ''),
      profilePhotoPath: json['profile_photo_path']?.toString(),
    );
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({String? baseUrl})
    : baseUrl =
          (baseUrl ??
                  const String.fromEnvironment(
                    'API_BASE_URL',
                    defaultValue: 'http://10.77.170.215:8000/api',
                  ))
              .replaceFirst(RegExp(r'/+$'), '');

  final String baseUrl;

  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/$path'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(response.body) as Map);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }

      final errors = decoded['errors'];

      if (errors is Map) {
        for (final messages in errors.values) {
          if (messages is List && messages.isNotEmpty) {
            throw ApiException(messages.first.toString());
          }
        }
      }

      throw ApiException(
        decoded['message']?.toString() ??
            'Permintaan gagal (HTTP ${response.statusCode}).',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons. Coba lagi.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa alamat API dan jaringan.',
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _post('register', {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  Future<AuthenticatedUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _post('login', {
      'email': email,
      'password': password,
    });

    final data = Map<String, dynamic>.from(response['data'] as Map);

    final user = Map<String, dynamic>.from(data['user'] as Map);

    return AuthenticatedUser(
      id: int.parse(user['id'].toString()),
      name: user['name'].toString(),
      email: user['email'].toString(),
      token: data['token'].toString(),
    );
  }

  Future<UserProfile> getProfile({required String token}) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/profile'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = Map<String, dynamic>.from(decoded['data'] as Map);
        return UserProfile.fromJson(data);
      }

      throw ApiException(
        decoded['message']?.toString() ?? 'Gagal mengambil profil.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons. Coba lagi.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server.');
    }
  }

  Future<UserProfile> updateProfile({
    required String token,
    String? name,
    String? phone,
    String? homeAddress,
    double? homeLatitude,
    double? homeLongitude,
  }) async {
    final body = <String, Object?>{};

    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;

    if (homeAddress != null) {
      body['home_address'] = homeAddress;
    }

    if (homeLatitude != null) {
      body['home_latitude'] = homeLatitude;
    }

    if (homeLongitude != null) {
      body['home_longitude'] = homeLongitude;
    }

    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/profile'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = Map<String, dynamic>.from(decoded['data'] as Map);
        return UserProfile.fromJson(data);
      }

      final errors = decoded['errors'];

      if (errors is Map) {
        for (final messages in errors.values) {
          if (messages is List && messages.isNotEmpty) {
            throw ApiException(messages.first.toString());
          }
        }
      }

      throw ApiException(decoded['message'] ?? 'Gagal menyimpan profil.');
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons. Coba lagi.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server.');
    }
  }

  Future<UserProfile> uploadProfilePhoto({
    required String token,
    required XFile photo,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/profile/photo');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          http.MultipartFile.fromBytes(
            'photo',
            await photo.readAsBytes(),
            filename: photo.name,
          ),
        );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = Map<String, dynamic>.from(decoded['data'] as Map);

        return UserProfile.fromJson(data);
      }

      final errors = decoded['errors'];

      if (errors is Map) {
        for (final messages in errors.values) {
          if (messages is List && messages.isNotEmpty) {
            throw ApiException(messages.first.toString());
          }
        }
      }

      throw ApiException(
        decoded['message']?.toString() ?? 'Gagal mengunggah foto profil.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Upload terlalu lama. Silakan coba lagi.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server.');
    }
  }

  Future<List<EvacuationPoint>> fetchEvacuationPoints({
    required String token,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/evacuation-points'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded['data'];

        if (data is! List) {
          throw const ApiException(
            'Format data titik pengungsian tidak valid.',
          );
        }

        return data
            .whereType<Map>()
            .map(
              (item) =>
                  EvacuationPoint.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }

      throw ApiException(
        decoded['message']?.toString() ??
            'Gagal mengambil data titik pengungsian.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Koneksi ke server terlalu lama. Silakan coba lagi.',
      );
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server.');
    }
  }

  Future<Map<String, dynamic>> fetchWeather({String? adm4}) async {
    try {
      final uri = Uri.parse('$baseUrl/weather')
          .replace(queryParameters: adm4 == null ? null : {'adm4': adm4});

      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }

      throw ApiException(
        decoded['message']?.toString() ?? 'Gagal mengambil data cuaca.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Koneksi ke server terlalu lama. Silakan coba lagi.',
      );
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa alamat API dan jaringan.',
      );
    }
  }

  // Mengambil daftar grup keluarga pengguna yang sedang login.
  Future<List<Map<String, dynamic>>> fetchFamilyGroups({
    required String token,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/family/groups'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded['data'];

        if (data is! List) {
          throw const ApiException('Format data grup keluarga tidak valid.');
        }

        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw ApiException(
        decoded['message']?.toString() ?? 'Gagal mengambil grup keluarga.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server.');
    }
  }

  Future<Map<String, dynamic>> createFamilyGroup({
    required String token,
    required String name,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/family/groups'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'name': name}),
        )
        .timeout(const Duration(seconds: 15));

    final decoded = Map<String, dynamic>.from(jsonDecode(response.body) as Map);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw ApiException(
      decoded['message']?.toString() ?? 'Gagal membuat grup keluarga.',
    );
  }

  Future<Map<String, dynamic>> joinFamilyGroup({
    required String token,
    required String inviteCode,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/family/groups/join'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'invite_code': inviteCode}),
        )
        .timeout(const Duration(seconds: 15));

    final decoded = Map<String, dynamic>.from(jsonDecode(response.body) as Map);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw ApiException(
      decoded['message']?.toString() ?? 'Gagal bergabung ke grup keluarga.',
    );
  }

  // Mengeluarkan pengguna yang sedang login dari grup keluarga.
  Future<Map<String, dynamic>> leaveFamilyGroup({
    required String token,
    required int familyGroupId,
  }) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/family/groups/leave'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'family_group_id': familyGroupId}),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }

      throw ApiException(
        decoded['message']?.toString() ?? 'Gagal keluar dari grup keluarga.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa alamat API dan jaringan.',
      );
    }
  }

  // Mengambil status semua anggota dalam satu grup keluarga.
  Future<List<Map<String, dynamic>>> fetchFamilyStatuses({
    required String token,
    required int familyGroupId,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/family/status',
      ).replace(queryParameters: {'family_group_id': familyGroupId.toString()});

      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded['data'];

        if (data is! List) {
          throw const ApiException('Format status anggota tidak valid.');
        }

        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw ApiException(
        decoded['message']?.toString() ??
            'Gagal mengambil status anggota keluarga.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server.');
    }
  }

  // Mengirim status anggota ke Laravel untuk disimpan ke database.
  Future<Map<String, dynamic>> sendFamilyStatus({
    required String token,
    required int familyGroupId,
    required String status,
    String? message,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/family/status'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'family_group_id': familyGroupId,
              'status': status,
              'message': message,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }

      final errors = decoded['errors'];

      if (errors is Map) {
        for (final messages in errors.values) {
          if (messages is List && messages.isNotEmpty) {
            throw ApiException(messages.first.toString());
          }
        }
      }

      throw ApiException(
        decoded['message']?.toString() ?? 'Gagal mengirim status keluarga.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server.');
    }
  }

  // Mengirim undangan keluarga berdasarkan nomor HP.
  Future<Map<String, dynamic>> sendFamilyInvitation({
    required String token,
    required String phone,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/family/invitations'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'phone': phone.trim()}),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }

      throw ApiException(
        decoded['message']?.toString() ?? 'Gagal mengirim undangan keluarga.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server.');
    }
  }

  // Mengambil undangan keluarga yang masih menunggu jawaban.
  Future<List<Map<String, dynamic>>> fetchFamilyInvitations({
    required String token,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/family/invitations'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded['data'];

        if (data is! List) {
          throw const ApiException(
            'Format data undangan keluarga tidak valid.',
          );
        }

        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw ApiException(
        decoded['message']?.toString() ?? 'Gagal mengambil undangan keluarga.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server.');
    }
  }

  // Menerima atau menolak undangan keluarga.
  Future<Map<String, dynamic>> respondFamilyInvitation({
    required String token,
    required int invitationId,
    required bool accept,
  }) async {
    final action = accept ? 'accept' : 'reject';

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/family/invitations/$invitationId/$action'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }

      throw ApiException(
        decoded['message']?.toString() ?? 'Gagal memproses undangan keluarga.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server.');
    }
  }

  // Mengambil riwayat pesan dari grup keluarga.
  Future<List<Map<String, dynamic>>> fetchFamilyMessages({
    required String token,
    required int familyGroupId,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/family/groups/$familyGroupId/messages'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded['data'];

        if (data is! List) {
          throw const ApiException('Format pesan chat tidak valid.');
        }

        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw ApiException(
        decoded['message']?.toString() ?? 'Gagal mengambil pesan chat.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa alamat API dan jaringan.',
      );
    }
  }

  // Mengirim pesan baru ke grup keluarga.
  Future<Map<String, dynamic>> sendFamilyMessage({
    required String token,
    required int familyGroupId,
    required String message,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/family/groups/$familyGroupId/messages'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'message': message.trim()}),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }

      final errors = decoded['errors'];

      if (errors is Map) {
        for (final messages in errors.values) {
          if (messages is List && messages.isNotEmpty) {
            throw ApiException(messages.first.toString());
          }
        }
      }

      throw ApiException(
        decoded['message']?.toString() ?? 'Gagal mengirim pesan chat.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa alamat API dan jaringan.',
      );
    }
  }

  // Mengambil jumlah pesan chat keluarga yang belum dibaca.
  Future<int> fetchFamilyUnreadCount({required String token}) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/family/unread-count'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return int.tryParse(decoded['unread_count']?.toString() ?? '') ?? 0;
      }

      throw ApiException(
        decoded['message']?.toString() ??
            'Gagal mengambil jumlah pesan belum dibaca.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons. Coba lagi.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa alamat API dan jaringan.',
      );
    }
  }

  // Mengambil pengaturan notifikasi dari database Laravel.
  Future<Map<String, bool>> fetchNotificationPreferences({
    required String token,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/notification-preferences'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = Map<String, dynamic>.from(decoded['data'] as Map);

        return {
          'notification_alert': data['notification_alert'] == true,
          'notification_river': data['notification_river'] == true,
          'notification_education': data['notification_education'] == true,
        };
      }

      throw ApiException(
        decoded['message']?.toString() ??
            'Gagal mengambil pengaturan notifikasi.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server.');
    }
  }

  // Menyimpan pengaturan notifikasi ke database Laravel.
  Future<Map<String, bool>> updateNotificationPreferences({
    required String token,
    required bool notificationAlert,
    required bool notificationRiver,
    required bool notificationEducation,
  }) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/notification-preferences'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'notification_alert': notificationAlert,
              'notification_river': notificationRiver,
              'notification_education': notificationEducation,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = Map<String, dynamic>.from(decoded['data'] as Map);

        return {
          'notification_alert': data['notification_alert'] == true,
          'notification_river': data['notification_river'] == true,
          'notification_education': data['notification_education'] == true,
        };
      }

      throw ApiException(
        decoded['message']?.toString() ??
            'Gagal menyimpan pengaturan notifikasi.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server.');
    }
  }

  // Mendaftarkan Firebase Installation ID perangkat ke Laravel.
  Future<void> registerDeviceToken({
    required String token,
    required String installationId,
    String platform = 'android',
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/device-tokens'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'firebase_installation_id': installationId,
              'platform': platform,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final decoded = response.body.isEmpty
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(jsonDecode(response.body) as Map);

        throw ApiException(
          decoded['message']?.toString() ?? 'Gagal mendaftarkan perangkat.',
        );
      }
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons. Coba lagi.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server Laravel.');
    }
  }

  // Menghapus pendaftaran Firebase Installation ID dari Laravel.
  Future<void> unregisterDeviceToken({
    required String token,
    required String installationId,
  }) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/device-tokens'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'firebase_installation_id': installationId}),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(response.body) as Map);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      throw ApiException(
        decoded['message']?.toString() ??
            'Gagal menghapus pendaftaran perangkat.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons. Coba lagi.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server Laravel.');
    }
  }

  // Mengirim laporan warga ke Laravel.

  Future<Map<String, dynamic>> submitCitizenReport({
    required String token,
    required String eventType,
    required String locationName,
    required String description,
    String? eventTime,
    double? waterLevelCm,
    double? latitude,
    double? longitude,
    XFile? photo,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/citizen-reports'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields.addAll({
        'event_type': eventType,
        'location_name': locationName,
        'description': description,
      });

      if (eventTime != null && eventTime.trim().isNotEmpty) {
        request.fields['event_time'] = eventTime.trim();
      }

      if (waterLevelCm != null) {
        request.fields['water_level_cm'] = waterLevelCm.toString();
      }

      if (latitude != null) {
        request.fields['latitude'] = latitude.toString();
      }

      if (longitude != null) {
        request.fields['longitude'] = longitude.toString();
      }

      if (photo != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            await photo.readAsBytes(),
            filename: photo.name,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }

      final errors = decoded['errors'];

      if (errors is Map) {
        for (final messages in errors.values) {
          if (messages is List && messages.isNotEmpty) {
            throw ApiException(messages.first.toString());
          }
        }
      }

      throw ApiException(
        decoded['message']?.toString() ?? 'Gagal mengirim laporan.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server.');
    }
  }

  // Mengambil riwayat laporan milik pengguna yang sedang login.
  Future<List<Map<String, dynamic>>> fetchMyCitizenReports({
    required String token,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/citizen-reports/my'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded['data'];

        if (data is! List) {
          throw const ApiException('Format riwayat laporan tidak valid.');
        }

        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw ApiException(
        decoded['message']?.toString() ?? 'Gagal mengambil riwayat laporan.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server.');
    }
  }

  // Mengambil daftar riwayat bencana dari Laravel.
  Future<List<Map<String, dynamic>>> fetchDisasterHistories() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/disaster-histories'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded['data'];

        if (data is! List) {
          throw const ApiException('Format data riwayat bencana tidak valid.');
        }

        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw ApiException(
        decoded['message']?.toString() ?? 'Gagal mengambil riwayat bencana.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server Laravel.');
    }
  }

  void dispose() {
    _client.close();
  }
}
