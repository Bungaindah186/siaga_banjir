import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../widgets/feature_page_shell.dart';
import '../widgets/reference_components.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({
    super.key,
    required this.account,
    required this.locationService,
  });

  final AuthenticatedUser account;
  final LocationService locationService;

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _chatTab = false;
  int _selectedStatus = 0;
  final _messageController = TextEditingController();

  List<Map<String, dynamic>> _familyGroups = [];
  List<Map<String, dynamic>> _familyStatuses = [];
  // Data chat keluarga dari API Laravel.
  List<Map<String, dynamic>> _familyMessages = [];
  bool _isLoadingMessages = false;
  bool _isSendingMessage = false;
  int _unreadCount = 0;

  // Data undangan keluarga yang masuk.
  List<Map<String, dynamic>> _familyInvitations = [];
  bool _isLoadingInvitations = false;
  int? _processingInvitationId;

  int? _selectedFamilyGroupId;
  bool _isLoadingFamily = false;
  bool _isSendingStatus = false;
  String? _familyError;

  @override
  void initState() {
    super.initState();
    _loadFamilyData();
    _loadFamilyInvitations();
    _loadFamilyUnreadCount();
  }

  Future<void> _loadFamilyData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingFamily = true;
      _familyError = null;
    });

    try {
      // Ambil daftar grup keluarga milik pengguna yang sedang login.
      final groups = await _apiClient.fetchFamilyGroups(
        token: widget.account.token,
      );

      if (!mounted) return;

      // Jika pengguna belum memiliki grup keluarga.
      if (groups.isEmpty) {
        setState(() {
          _familyGroups = [];
          _familyStatuses = [];
          _selectedFamilyGroupId = null;
          _familyError =
              'Belum ada grup keluarga. Buat atau gabung grup terlebih dahulu.';
        });
        return;
      }

      // Gunakan grup yang sedang dipilih jika masih tersedia.
      // Jika belum ada, pilih grup pertama.
      final selectedGroupId =
          _selectedFamilyGroupId != null &&
              groups.any(
                (group) =>
                    int.tryParse(group['id'].toString()) ==
                    _selectedFamilyGroupId,
              )
          ? _selectedFamilyGroupId!
          : int.parse(groups.first['id'].toString());

      // Ambil status anggota dari grup yang dipilih.
      final statuses = await _apiClient.fetchFamilyStatuses(
        token: widget.account.token,
        familyGroupId: selectedGroupId,
      );

      if (!mounted) return;

      setState(() {
        _familyGroups = groups;
        _selectedFamilyGroupId = selectedGroupId;
        _familyStatuses = statuses;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _familyError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFamily = false;
        });
      }
    }
  }

  Future<void> _loadFamilyInvitations() async {
    if (!mounted) return;

    setState(() {
      _isLoadingInvitations = true;
    });

    try {
      final invitations = await _apiClient.fetchFamilyInvitations(
        token: widget.account.token,
      );

      if (!mounted) return;

      setState(() {
        _familyInvitations = invitations;
      });
    } catch (e) {
      if (!mounted) return;

      _showNotConnected('Gagal memuat undangan keluarga: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInvitations = false;
        });
      }
    }
  }

  // Memperbarui jumlah pesan keluarga yang belum dibaca.
  Future<void> _loadFamilyUnreadCount() async {
    try {
      final count = await _apiClient.fetchFamilyUnreadCount(
        token: widget.account.token,
      );

      if (!mounted) return;

      setState(() {
        _unreadCount = count;
      });
    } catch (e) {
      // Jika gagal mengambil jumlah pesan, pertahankan nilai sebelumnya.
    }
  }

  Future<void> _loadFamilyMessages() async {
    final groupId = _selectedFamilyGroupId;

    if (groupId == null) {
      if (!mounted) return;

      setState(() {
        _familyMessages = [];
      });
      await _loadFamilyUnreadCount();

      return;
    }

    if (_isLoadingMessages) return;

    setState(() {
      _isLoadingMessages = true;
    });

    try {
      final messages = await _apiClient.fetchFamilyMessages(
        token: widget.account.token,
        familyGroupId: groupId,
      );

      if (!mounted) return;

      setState(() {
        _familyMessages = messages;
      });
    } catch (e) {
      if (!mounted) return;

      _showNotConnected('Gagal memuat chat keluarga: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMessages = false;
        });
      }
    }
  }

  Future<void> _sendFamilyMessage() async {
    if (_isSendingMessage) return;

    final groupId = _selectedFamilyGroupId;
    final message = _messageController.text.trim();

    if (groupId == null) {
      _showNotConnected(
        'Kamu belum memiliki grup keluarga. '
        'Buat atau gabung grup terlebih dahulu.',
      );
      return;
    }

    if (message.isEmpty) return;

    setState(() {
      _isSendingMessage = true;
    });

    try {
      await _apiClient.sendFamilyMessage(
        token: widget.account.token,
        familyGroupId: groupId,
        message: message,
      );

      if (!mounted) return;

      _messageController.clear();

      await _loadFamilyMessages();

      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;

      _showNotConnected('Gagal mengirim pesan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _sendStatus() async {
    if (_isSendingStatus) return;

    if (_selectedFamilyGroupId == null) {
      _showNotConnected(
        'Kamu belum memiliki grup keluarga. Buat atau gabung grup terlebih dahulu.',
      );
      return;
    }

    setState(() {
      _isSendingStatus = true;
    });

    try {
      const statusValues = ['aman', 'waspada', 'darurat', 'butuh_bantuan'];

      await _apiClient.sendFamilyStatus(
        token: widget.account.token,
        familyGroupId: _selectedFamilyGroupId!,
        status: statusValues[_selectedStatus],
      );

      if (!mounted) return;

      _showNotConnected('Status berhasil dikirim ke keluarga.');

      await _loadFamilyData();
    } catch (e) {
      if (!mounted) return;

      _showNotConnected('Gagal mengirim status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSendingStatus = false;
        });
      }
    }
  }

  Future<void> _respondToFamilyInvitation({
    required Map<String, dynamic> invitation,
    required bool accept,
  }) async {
    final invitationId = int.tryParse(invitation['id']?.toString() ?? '');

    if (invitationId == null) {
      _showNotConnected('ID undangan tidak valid.');
      return;
    }

    if (_processingInvitationId != null) return;

    setState(() {
      _processingInvitationId = invitationId;
    });

    try {
      await _apiClient.respondFamilyInvitation(
        token: widget.account.token,
        invitationId: invitationId,
        accept: accept,
      );

      if (!mounted) return;

      setState(() {
        _familyInvitations.removeWhere(
          (item) => item['id'].toString() == invitationId.toString(),
        );
      });

      _showNotConnected(
        accept
            ? 'Undangan diterima. Kamu bergabung dengan grup keluarga.'
            : 'Undangan keluarga ditolak.',
      );

      if (accept) {
        await _loadFamilyData();
      }

      await _loadFamilyInvitations();
    } catch (e) {
      if (!mounted) return;

      _showNotConnected(
        accept ? 'Gagal menerima undangan: $e' : 'Gagal menolak undangan: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingInvitationId = null;
        });
      }
    }
  }

  void _showNotConnected(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _leaveFamilyGroup(Map<String, dynamic> group) async {
    final groupId = int.tryParse(group['id'].toString());

    if (groupId == null) {
      _showNotConnected('ID grup keluarga tidak valid.');
      return;
    }

    final groupName = group['name']?.toString() ?? 'grup keluarga';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari Grup?'),
        content: Text('Apakah kamu yakin ingin keluar dari "$groupName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _apiClient.leaveFamilyGroup(
        token: widget.account.token,
        familyGroupId: groupId,
      );

      if (!mounted) return;

      _selectedFamilyGroupId = null;

      await _loadFamilyData();

      if (mounted) {
        _showNotConnected('Kamu berhasil keluar dari grup "$groupName".');
      }
    } catch (e) {
      if (mounted) {
        _showNotConnected('Gagal keluar dari grup: $e');
      }
    }
  }

  Future<void> _openAddMemberPage() async {
    await Navigator.pushNamed(
      context,
      AppRoutes.familyAddPhone,
      arguments: AppRouteArguments(
        account: widget.account,
        locationService: widget.locationService,
        apiClient: _apiClient,
      ),
    );

    if (!mounted) return;
    await _loadFamilyData();
  }

  Future<void> _showFamilyGroupDialog() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Grup Keluarga',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.group_add_outlined),
                title: const Text('Buat Grup Keluarga'),
                subtitle: const Text(
                  'Buat grup baru dan dapatkan kode undangan.',
                ),
                onTap: () => Navigator.pop(context, 'create'),
              ),
              ListTile(
                leading: const Icon(Icons.group_outlined),
                title: const Text('Gabung Grup Keluarga'),
                subtitle: const Text('Masukkan kode undangan keluarga.'),
                onTap: () => Navigator.pop(context, 'join'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'create') {
      await _createFamilyGroupDialog();
    } else if (action == 'join') {
      await _joinFamilyGroupDialog();
    }
  }

  Future<void> _createFamilyGroupDialog() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Grup Keluarga'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 255,
          decoration: const InputDecoration(
            labelText: 'Nama grup keluarga',
            hintText: 'Contoh: Keluarga di Padang',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Buat Grup'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (!mounted || name == null || name.isEmpty) return;

    try {
      final result = await _apiClient.createFamilyGroup(
        token: widget.account.token,
        name: name,
      );

      if (!mounted) return;

      final data = result['data'];
      final inviteCode = data is Map ? data['invite_code']?.toString() : null;

      await _loadFamilyData();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Grup Berhasil Dibuat'),
          content: Text(
            inviteCode == null
                ? 'Grup keluarga berhasil dibuat.'
                : 'Bagikan kode undangan berikut kepada anggota keluarga:\n\n$inviteCode',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        _showNotConnected('Gagal membuat grup: $e');
      }
    }
  }

  Future<void> _joinFamilyGroupDialog() async {
    final controller = TextEditingController();

    final inviteCode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gabung Grup Keluarga'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          maxLength: 12,
          decoration: const InputDecoration(
            labelText: 'Kode undangan',
            hintText: 'Masukkan kode keluarga',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Gabung'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (!mounted || inviteCode == null || inviteCode.isEmpty) return;

    try {
      await _apiClient.joinFamilyGroup(
        token: widget.account.token,
        inviteCode: inviteCode,
      );

      if (!mounted) return;

      await _loadFamilyData();

      if (mounted) {
        _showNotConnected('Berhasil bergabung dengan grup keluarga.');
      }
    } catch (e) {
      if (mounted) {
        _showNotConnected('Gagal bergabung: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) => FeaturePageShell(
    title: _chatTab ? 'Chat keluarga' : 'Status Keluarga',
    account: widget.account,
    locationService: widget.locationService,
    activeTab: 'Keluarga',
    showFamilyUnread: _unreadCount > 0,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 7),
          child: Row(
            children: [
              Expanded(
                child: ReferenceTab(
                  label: 'Status Keluarga',
                  selected: !_chatTab,
                  onTap: () => setState(() => _chatTab = false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ReferenceTab(
                  label: 'Chat',
                  selected: _chatTab,
                  showUnread: _unreadCount > 0,
                  onTap: () {
                    setState(() {
                      _chatTab = true;
                    });

                    _loadFamilyMessages();
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _chatTab ? _buildChat() : _buildStatus()),
      ],
    ),
  );
  Widget _buildFamilyInvitationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Undangan Keluarga Masuk',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF263840),
            ),
          ),
        ),
        if (_isLoadingInvitations)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_familyInvitations.isEmpty)
          const ReferenceCard(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.mail_outline, color: Color(0xFF71808D)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Belum ada undangan keluarga yang menunggu.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF71808D)),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._familyInvitations.map((invitation) {
            final inviter =
                invitation['inviter_name']?.toString() ??
                (invitation['inviter'] is Map
                    ? invitation['inviter']['name']?.toString()
                    : null) ??
                'Anggota keluarga';

            final groupName =
                invitation['family_group_name']?.toString() ??
                (invitation['family_group'] is Map
                    ? invitation['family_group']['name']?.toString()
                    : null) ??
                'Grup keluarga';

            final invitationId = int.tryParse(
              invitation['id']?.toString() ?? '',
            );

            final isProcessing =
                invitationId != null && _processingInvitationId == invitationId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ReferenceCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.group_add_outlined,
                          color: Color(0xFF118AA1),
                          size: 26,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Undangan Bergabung ke Keluarga',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF263840),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$inviter mengundangmu bergabung ke grup "$groupName".',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF52636B),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                isProcessing || _processingInvitationId != null
                                ? null
                                : () => _respondToFamilyInvitation(
                                    invitation: invitation,
                                    accept: false,
                                  ),
                            child: const Text('Tolak'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed:
                                isProcessing || _processingInvitationId != null
                                ? null
                                : () => _respondToFamilyInvitation(
                                    invitation: invitation,
                                    accept: true,
                                  ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF118AA1),
                            ),
                            child: isProcessing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Terima'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStatus() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
    children: [
      _buildFamilyInvitationsSection(),
      const SizedBox(height: 14),
      ReferenceCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bagaimana keadaanmu?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF263840),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih statusmu agar keluarga mengetahui keadaanmu.',
              style: TextStyle(fontSize: 12, color: Color(0xFF71808D)),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _statuses.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 8,
                childAspectRatio: 4.5,
              ),
              itemBuilder: (context, index) {
                return _StatusChoice(
                  status: _statuses[index],
                  selected: _selectedStatus == index,
                  onTap: () {
                    setState(() {
                      _selectedStatus = index;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSendingStatus ? null : _sendStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF118AA1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSendingStatus
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kirim Status'),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const Padding(
        padding: EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          'Status Anggota Keluarga',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF263840),
          ),
        ),
      ),
      ReferenceCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: _isLoadingFamily
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            : _familyError != null
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _familyError!,
                  style: const TextStyle(
                    color: Color(0xFF71808D),
                    fontSize: 12,
                  ),
                ),
              )
            : _familyStatuses.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Belum ada status anggota keluarga.',
                  style: TextStyle(color: Color(0xFF71808D), fontSize: 12),
                ),
              )
            : Column(
                children: [
                  for (final member in _familyStatuses)
                    _buildFamilyMemberStatus(member),
                ],
              ),
      ),
      const SizedBox(height: 12),
      if (_familyGroups.isNotEmpty) ...[
        for (final group in _familyGroups) ...[
          ReferenceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      color: Color(0xFF118AA1),
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Grup Keluarga',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF71808D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            group['name']?.toString() ?? 'Keluarga',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF263840),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (group['invite_code'] != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Kode Undangan',
                    style: TextStyle(fontSize: 12, color: Color(0xFF71808D)),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    group['invite_code'].toString(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF118AA1),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _leaveFamilyGroup(group),
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Keluar dari Grup',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
      if (_familyGroups.isEmpty) ...[
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showFamilyGroupDialog,
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('Buat atau Gabung Grup Keluarga'),
          ),
        ),
        const SizedBox(height: 12),
      ],

      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _openAddMemberPage,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Tambah Anggota Keluarga'),
        ),
      ),
      if (_familyError != null) ...[
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _loadFamilyData,
          icon: const Icon(Icons.refresh),
          label: const Text('Coba lagi'),
        ),
      ],
    ],
  );
  Widget _buildFamilyMemberStatus(Map<String, dynamic> member) {
    final name = member['name']?.toString() ?? 'Anggota keluarga';
    final rawStatus = member['status']?.toString();
    final message = member['message']?.toString();
    final reportedAt = member['reported_at']?.toString();

    String displayStatus;
    Color statusColor;

    switch (rawStatus) {
      case 'aman':
        displayStatus = 'Aman';
        statusColor = const Color(0xFF2EA361);
        break;
      case 'waspada':
        displayStatus = 'Waspada';
        statusColor = const Color(0xFFFFC928);
        break;
      case 'darurat':
        displayStatus = 'Darurat';
        statusColor = const Color(0xFFE34337);
        break;
      case 'butuh_bantuan':
        displayStatus = 'Butuh Bantuan';
        statusColor = const Color(0xFF1495D0);
        break;
      default:
        displayStatus = 'Belum melapor';
        statusColor = const Color(0xFF8B969B);
    }

    String timeLabel = 'Belum ada laporan';

    if (reportedAt != null && reportedAt.isNotEmpty) {
      final date = DateTime.tryParse(reportedAt)?.toLocal();

      if (date != null) {
        final difference = DateTime.now().difference(date);

        if (difference.inMinutes < 1) {
          timeLabel = 'Baru saja';
        } else if (difference.inHours < 1) {
          timeLabel = '${difference.inMinutes} menit lalu';
        } else if (difference.inDays < 1) {
          timeLabel = '${difference.inHours} jam lalu';
        } else {
          timeLabel = '${difference.inDays} hari lalu';
        }
      }
    }

    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().substring(0, 1).toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF118AA1),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF263840),
                  ),
                ),
                Text(
                  message != null && message.isNotEmpty
                      ? '$timeLabel • $message'
                      : timeLabel,
                  style: const TextStyle(color: Color(0xFF8B969B), fontSize: 9),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              displayStatus,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChat() => Column(
    children: [
      Expanded(
        child: _isLoadingMessages
            ? const Center(child: CircularProgressIndicator())
            : _selectedFamilyGroupId == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Kamu belum memiliki grup keluarga. '
                    'Buat atau gabung grup terlebih dahulu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF71808D)),
                  ),
                ),
              )
            : _familyMessages.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Belum ada pesan. '
                    'Mulai percakapan dengan keluarga.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF71808D)),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                itemCount: _familyMessages.length,
                itemBuilder: (context, index) {
                  final item = _familyMessages[index];

                  final user = item['user'];

                  final senderId = user is Map ? user['id']?.toString() : null;

                  final name = user is Map
                      ? user['name']?.toString() ?? 'Anggota keluarga'
                      : 'Anggota keluarga';

                  final message = item['message']?.toString() ?? '';

                  final incoming = senderId != widget.account.id.toString();

                  return _ChatBubble(
                    name: incoming ? name : 'Saya',
                    message: message,
                    incoming: incoming,
                  );
                },
              ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
        child: const Text(
          'Pesan tersimpan melalui server aplikasi.',
          style: TextStyle(color: Color(0xFF71808D), fontSize: 11),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
        child: TextField(
          controller: _messageController,
          textInputAction: TextInputAction.send,
          enabled: !_isSendingMessage && _selectedFamilyGroupId != null,
          onSubmitted: (_) => _sendFamilyMessage(),
          decoration: InputDecoration(
            hintText: 'Ketik pesan...',
            filled: true,
            fillColor: Colors.white,
            suffixIcon: IconButton(
              tooltip: 'Kirim pesan',
              onPressed: _isSendingMessage || _selectedFamilyGroupId == null
                  ? null
                  : _sendFamilyMessage,
              icon: _isSendingMessage
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD6DDE0)),
            ),
          ),
        ),
      ),
    ],
  );
}

const _statuses = [
  ('Aman', Icons.check_circle, Color(0xFF2EA361)),
  ('Waspada', Icons.error, Color(0xFFFFC928)),
  ('Darurat', Icons.emergency, Color(0xFFE34337)),
  ('Butuh Bantuan', Icons.help, Color(0xFF1495D0)),
];

class _StatusChoice extends StatelessWidget {
  const _StatusChoice({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final (String, IconData, Color) status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final itemWidth = (screenWidth - 48) / 2;

    return SizedBox(
      width: itemWidth,
      height: 38,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        elevation: selected ? 1 : 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(status.$2, color: status.$3, size: 22),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    status.$1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF34454D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.name,
    required this.message,
    required this.incoming,
  });
  final String name;
  final String message;
  final bool incoming;

  @override
  Widget build(BuildContext context) => Align(
    alignment: incoming ? Alignment.centerLeft : Alignment.centerRight,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (incoming)
            const CircleAvatar(radius: 24, child: Icon(Icons.person)),
          if (incoming) const SizedBox(width: 9),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 235),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: incoming
                    ? const Color(0xFFDCE3E5)
                    : const Color(0xFFDDF2F4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(message),
                ],
              ),
            ),
          ),
          if (!incoming) const SizedBox(width: 9),
          if (!incoming)
            const CircleAvatar(radius: 24, child: Icon(Icons.person)),
        ],
      ),
    ),
  );
}
