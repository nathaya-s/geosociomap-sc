import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LayerDropdown extends StatefulWidget {
  final List<Map<String, dynamic>> layers; 
   final Function(String, String) onSelected;

  const LayerDropdown({
    super.key,
    required this.layers,
    required this.onSelected,
  });

  @override
  _LayerDropdownState createState() => _LayerDropdownState();
}

class _LayerDropdownState extends State<LayerDropdown> {
  String? selectedLayerTitle; 

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showModalBottomSheet(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8.0), 
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedLayerTitle ??
                  'เลือก Layer', 
              style: GoogleFonts.sarabun(fontSize: 16, color: Colors.black),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.grey, 
            ),
          ],
        ),
      ),
    );
  }

  void _showModalBottomSheet(BuildContext context) {
  showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true, 
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)), 
    ),
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 0.4, 
        child: Padding(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const SizedBox(height: 12),
                Column(
                  children: widget.layers.map((layer) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedLayerTitle = layer['title']; 
                        });
                    
                        widget.onSelected(
                            layer['id'], layer['title']);
                        Navigator.pop(context); 
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 1.0),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              layer['icon'] ??
                                  Icons.map, 
                              color: Colors.blue, 
                            ),
                            const SizedBox(
                                width: 8),
                            Text(
                              layer['title'],
                              style: GoogleFonts.sarabun(
                                fontSize: 16,
                                color: Colors.black,
                              ), 
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}


}
