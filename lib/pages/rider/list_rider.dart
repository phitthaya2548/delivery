import 'dart:convert';
import 'dart:developer';

import 'package:deliveryrpoject/config/config.dart';
import 'package:deliveryrpoject/pages/sesstionstore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ListRider extends StatefulWidget {
  const ListRider({Key? key}) : super(key: key);

  @override
  State<ListRider> createState() => _ListRiderState();
}

class _ListRiderState extends State<ListRider> {
  static const _orange = Color(0xFFFD8700);
  static const _bg = Color(0xFFF4F4F4);

  String _baseUrl = '';
  bool _loading = true;
  String? _error;
  dynamic _data;
  int riderId = 0;

  @override
  void initState() {
    super.initState();
    _initAndFetch();
  }

  Future<void> _initAndFetch() async {
    try {
      // Get configuration data
      final cfg = await Configuration.getConfig();
      final ep = (cfg['apiEndpoint'] as String? ?? '').trim();
      _baseUrl = ep.endsWith('/') ? ep.substring(0, ep.length - 1) : ep;

      // Get riderId from session storage
      final auth = SessionStore.getAuth();
      if (auth != null && auth['userId'] != null) {
        riderId = auth['userId'];
        await _fetchDetail();
      }
    } catch (e) {
      log('init error: $e');
      if (mounted) {
        setState(() {
          _error = 'ตั้งค่า API ไม่ถูกต้อง';
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      log(riderId.toString());
      final uri = Uri.parse('$_baseUrl/riders/accepted/accepted/$riderId');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _data = j['item'];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Server error (${res.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'เชื่อมต่อเซิร์ฟเวอร์ไม่สำเร็จ: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Delivery WarpSong'),
        centerTitle: false,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_orange, Color(0xFFFFDE98)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildContent(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('ย้อนกลับ',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_data == null) {
      return const Center(child: Text('No shipment data available'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildItemDetail(),
        const SizedBox(height: 12),
        _buildSenderDetail(),
        const SizedBox(height: 12),
        _buildReceiverDetail(),
        const SizedBox(height: 12),
        _buildStatus(),
        const SizedBox(height: 12),
        _buildActionButton(),
      ],
    );
  }

  // Item details section
  Widget _buildItemDetail() {
    final item = _data!; // Non-nullable
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['item_name'] ?? 'Unknown Item',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text(item['item_description'] ?? 'No Description'),
            const SizedBox(height: 10),
            item['last_photo'] != null
                ? Image.network(item['last_photo']['url'] ?? '',
                    height: 200, fit: BoxFit.cover)
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  // Sender details section
  Widget _buildSenderDetail() {
    final sender = _data!['sender'];
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                  sender['avatar'] ?? 'https://via.placeholder.com/150'),
              radius: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ผู้ส่ง: ${sender['name']}'),
                  Text('โทร: ${sender['phone']}'),
                  Text('ที่อยู่: ${sender['address']['address_text']}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Receiver details section
  Widget _buildReceiverDetail() {
    final receiver = _data!['receiver'];
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                  receiver['avatar'] ?? 'https://via.placeholder.com/150'),
              radius: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ผู้รับ: ${receiver['name']}'),
                  Text('โทร: ${receiver['phone']}'),
                  Text('ที่อยู่: ${receiver['address']['address_text']}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Status section
  Widget _buildStatus() {
    final status = _data!['status'];
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: _orange),
            const SizedBox(width: 10),
            Text('สถานะ: $status',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Action button
  Widget _buildActionButton() {
    return ElevatedButton(
      onPressed: () {
        // Add logic for handling the action
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Action executed')));
      },
      style: ElevatedButton.styleFrom(backgroundColor: _orange),
      child: const Text('รับงาน'),
    );
  }
}
