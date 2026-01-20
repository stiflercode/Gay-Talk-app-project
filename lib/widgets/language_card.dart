import 'package:flutter/material.dart';

class LanguageCard extends StatelessWidget {
  final String code;
  final String label;
  final String native;
  final VoidCallback onTap;
  const LanguageCard({required this.code, required this.label, required this.native, required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(side: BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(8)),
        child: ListTile(
          leading: SizedBox(width: 36, child: Center(child: Icon(Icons.flag))),
          title: Text(label),
          subtitle: Text(native),
        ),
      ),
    );
  }
}
