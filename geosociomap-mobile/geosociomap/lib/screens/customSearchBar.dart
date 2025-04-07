import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomSearchBar extends StatefulWidget {
  final List<Map<String, dynamic>> projects; 

  const CustomSearchBar({super.key, required this.projects});

  @override
  _CustomSearchBarState createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  String query = "";
  List<Map<String, dynamic>> filteredProjects = []; 

  @override
  void initState() {
    super.initState();
    filteredProjects = widget.projects; 
  }

  void updateSearch(String value) {
    setState(() {
      query = value;
      filteredProjects = widget.projects
          .where((project) =>
              project['projectName'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 35),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              onChanged: updateSearch,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                hintText: 'ค้นหาโครงการ',
                hintStyle: GoogleFonts.sarabun(
                  textStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11.0),
              ),
              style: GoogleFonts.sarabun(
                textStyle: const TextStyle(color: Colors.black, fontSize: 14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

    
        query.isNotEmpty
            ? Container(
                constraints: const BoxConstraints(maxWidth: 300),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filteredProjects.isNotEmpty
                      ? filteredProjects.map((project) {
                          return ListTile(
                            title: Text(
                              project['projectName'],
                              style: GoogleFonts.sarabun(
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            leading: const Icon(Icons.folder, color: Colors.blue),
                          );
                        }).toList()
                      : [
                          Text(
                            "ไม่พบโครงการ",
                            style: GoogleFonts.sarabun(
                              textStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          )
                        ],
                ),
              )
            : const SizedBox.shrink(), 
      ],
    );
  }
}
