import 'dart:convert';
import 'dart:developer';

import 'package:deliveryrpoject/config/config.dart';
import 'package:deliveryrpoject/models/res/res_shipment.dart'; // ต้องมี field thumbUrl ในโมเดล
import 'package:deliveryrpoject/pages/sesstionstore.dart';
import 'package:deliveryrpoject/pages/user/followitem_user.dart';
import 'package:deliveryrpoject/pages/user/widgets/appbarheader.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ListUser extends StatefulWidget {
  const ListUser({super.key});

  @override
  State<ListUser> createState() => _ListUserState();
}

class _ListUserState extends State<ListUser> {
  static const _orange = Color(0xFFFD8700);
  static const _lightOrangeBg = Color(0xFFFFF5E9);
  static const _cardBorder = Color(0xFFFFC37D);

  String url = '';
  int? userId;

  bool _loadingSent = true;
  bool _loadingRecv = true;
  String? _errSent;
  String? _errRecv;

  List<ShipmentItem> _sent = [];
  List<ShipmentItem> _recv = [];

  @override
  void initState() {
    super.initState();
    _initAndFetch();
  }

  Future<void> _initAndFetch() async {
    try {
      final config = await Configuration.getConfig();
      final ep = (config['apiEndpoint'] as String? ?? '').trim();
      url = ep.endsWith('/') ? ep.substring(0, ep.length - 1) : ep;

      final auth = await SessionStore.getAuth();
      userId = (auth?['userId'] as num?)?.toInt();

      if (userId == null || userId == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ยังไม่ได้ล็อกอิน')),
          );
        }
        return;
      }

      await Future.wait([_fetchSent(), _fetchReceived()]);
    } catch (e) {
      log('init error: $e');
      if (mounted) {
        setState(() {
          _errSent ??= 'ตั้งค่า/ล็อกอินไม่ถูกต้อง';
          _errRecv ??= 'ตั้งค่า/ล็อกอินไม่ถูกต้อง';
          _loadingSent = false;
          _loadingRecv = false;
        });
      }
    }
  }

  Future<void> _fetchSent() async {
    setState(() {
      _loadingSent = true;
      _errSent = null;
    });
    try {
      final uri = Uri.parse('$url/shipments/sent')
          .replace(queryParameters: {'sender_id': '${userId!}'});
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        final items = (j['items'] as List<dynamic>? ?? [])
            .map((e) => ShipmentItem.fromJson(
                  e as Map<String, dynamic>,
                  isSenderView: true,
                ))
            .toList();
        setState(() {
          _sent = items;
          _loadingSent = false;
        });
      } else {
        setState(() {
          _errSent = 'Server error (${res.statusCode})';
          _loadingSent = false;
        });
      }
    } catch (e) {
      setState(() {
        _errSent = 'เชื่อมต่อเซิร์ฟเวอร์ไม่สำเร็จ: $e';
        _loadingSent = false;
      });
    }
  }

  Future<void> _fetchReceived() async {
    setState(() {
      _loadingRecv = true;
      _errRecv = null;
    });
    try {
      final uri = Uri.parse('$url/shipments/received')
          .replace(queryParameters: {'user_id': '${userId!}'});
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        final items = (j['items'] as List<dynamic>? ?? [])
            .map((e) => ShipmentItem.fromJson(
                  e as Map<String, dynamic>,
                  isSenderView: false,
                ))
            .toList();
        setState(() {
          _recv = items;
          _loadingRecv = false;
        });
      } else {
        setState(() {
          _errRecv = 'Server error (${res.statusCode})';
          _loadingRecv = false;
        });
      }
    } catch (e) {
      setState(() {
        _errRecv = 'เชื่อมต่อเซิร์ฟเวอร์ไม่สำเร็จ: $e';
        _loadingRecv = false;
      });
    }
  }

  /// ถ้า backend ส่ง path มา (เช่น /uploads/xx.png) ให้ต่อเป็น absolute ด้วย baseUrl

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F4),
        appBar: customAppBar(),
        body: Column(
          children: [
            const Material(
              color: Color(0xFFF4F4F4),
              child: TabBar(
                labelColor: Colors.orange,
                unselectedLabelColor: Colors.orangeAccent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorColor: _orange,
                labelStyle: TextStyle(fontWeight: FontWeight.w800),
                tabs: [
                  Tab(text: 'ส่งของ'),
                  Tab(text: 'รับของ'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // TAB: ส่งของ
                  RefreshIndicator(
                    onRefresh: () async => _fetchSent(),
                    child: _buildList(
                      titleIcon: Icons.local_shipping_outlined,
                      titleText: 'ส่งของ',
                      loading: _loadingSent,
                      error: _errSent,
                      items: _sent,
                    ),
                  ),
                  // TAB: รับของ
                  RefreshIndicator(
                    onRefresh: () async => _fetchReceived(),
                    child: _buildList(
                      titleIcon: Icons.download_outlined,
                      titleText: 'รับของ',
                      loading: _loadingRecv,
                      error: _errRecv,
                      items: _recv,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- List builder ----------
  Widget _buildList({
    required IconData titleIcon,
    required String titleText,
    required bool loading,
    required String? error,
    required List<ShipmentItem> items,
  }) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 32),
          Center(child: Text(error)),
        ],
      );
    }
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 32),
          Center(child: Text('ไม่พบรายการ')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: items.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Row(
            children: [
              Icon(titleIcon, color: _orange),
              const SizedBox(width: 6),
              Text(titleText,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          );
        }
        final it = items[i - 1];
        return _buildOrderCard(
          title: 'Delivery WarpSong',
          badgeText: it.statusText,
          badgeColor: it.statusColor,
          itemName: it.itemName,
          detail: it.detailText,
          imageUrl: it.thumbUrl,
          onTrack: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FollowitemUser(shipmentId: it.shipmentId),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildOrderCard({
    required String title,
    required String badgeText,
    required Color badgeColor,
    required String itemName,
    required String detail,
    required VoidCallback onTrack,
    String? imageUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _lightOrangeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, color: _orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // body
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: imageUrl == null
                        ? Container(
                            color: Colors.black12,
                            alignment: Alignment.center,
                            child:
                                const Icon(Icons.image, color: Colors.black38),
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: Colors.black12,
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                            errorBuilder: (ctx, err, stack) {
                              return Container(
                                color: Colors.black12,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image,
                                    color: Colors.black38),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detail,
                        style: const TextStyle(
                            height: 1.25, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // footer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTrack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'ติดตาม',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
