import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 


Widget buildListTile(String title, VoidCallback? onTap) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 0), 
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0), 
      dense: true, 
      title: Text(
        title,
        style: GoogleFonts.sarabun( 
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: Colors.black, 
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14.0, 
        color: Colors.grey[600],
      ),
      onTap: onTap,
    ),
  );
}
