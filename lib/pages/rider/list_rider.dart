import 'package:deliveryrpoject/pages/user/widgets/appbarheader.dart';
import 'package:flutter/material.dart';

class ListRider extends StatefulWidget {
  const ListRider({Key? key}) : super(key: key);

  @override
  State<ListRider> createState() => _ListRiderState();
}

class _ListRiderState extends State<ListRider> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(),
    );
  }
}
