import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuestionWidget extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final ValueChanged<List<Map<String, dynamic>>> onQuestionsUpdated;

  const QuestionWidget({super.key, 
    required this.questions,
    required this.onQuestionsUpdated,
  });

  @override
  _QuestionWidgetState createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  late List<TextEditingController> _controllers;
  late List<Map<String, Object>> _editableQuestions;
  List<Map<String, Object>> _questions = [];

  @override
  void initState() {
    super.initState();
    _editableQuestions = List.from(widget.questions);
    _questions = List.from(widget.questions);

    _controllers = List.generate(
      _questions.length,
      (index) =>
          TextEditingController(text: _questions[index]['label'] as String?),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  final List<String> colors = [
    "#ef4444",
    "#f97316",
    "#f59e0b",
    "#eab308",
    "#fde047",
    "#84cc16",
    "#4ade80",
    "#34d399",
    "#2dd4bf",
    "#22d3ee",
    "#0ea5e9",
    "#3b82f6",
    "#6366f1",
    "#8b5cf6",
    "#a855f7",
    "#d946ef",
    "#ec4899",
    "#f43f5e",
  ];


  Color hexToColor(String hex) {
    return Color(int.parse('0xFF${hex.substring(1)}'));
  }


  String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          TextButton(
            onPressed: () {
             
              _showQuestionTypeDialog(context);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize
                  .shrinkWrap,
            ),
            child: Align(
              alignment: Alignment.centerRight, 
              child: Text(
                "เพิ่มคำถาม",
                style: GoogleFonts.sarabun(
                  
                  color: Colors.blue.shade700,
                  fontSize: 16.0, 
                  fontWeight: FontWeight.bold, 
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            flex: 2,
            child: ListView.separated(
              itemCount: _questions.length,
              separatorBuilder: (context, index) => const Divider(
                thickness: 1.0,
                color: Colors.grey,
                height: 32.0,
              ),
              itemBuilder: (context, index) {
                final question = _questions[index];
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _buildQuestionWidget(question, index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showQuestionTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'เลือกประเภทคำถาม',
            style: GoogleFonts.sarabun(
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.blue[600],
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  'ข้อความ',
                  style: GoogleFonts.sarabun(
                    textStyle: const TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                onTap: () {
                  
                  _addQuestion('text');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text(
                  'ตัวเลข',
                  style: GoogleFonts.sarabun(
                    textStyle: const TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                onTap: () {
                 
                  _addQuestion('number');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text(
                  'ตัวเลือกแบบคำตอบเดียว',
                  style: GoogleFonts.sarabun(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                onTap: () {
                
                  _addQuestion('multiple_choice');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text(
                  'ตัวเลือกแบบหลายคำตอบ',
                  style: GoogleFonts.sarabun(
                    textStyle: const TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                onTap: () {
               
                  _addQuestion('checkbox');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addQuestion(String type) {
    setState(() {
      String id = (_questions.length + 1).toString();
      var newQuestion = <String, Object>{
        'id': id, 
        'label': '',
        'type': type, 
        'showOnMap': false, 
      };
      if (type == 'multiple_choice' || type == 'checkbox') {
        newQuestion['options'] = []; 
      }
      _questions.add(newQuestion);
      _controllers
          .add(TextEditingController(text: newQuestion['label'] as String?));
      _updateQuestions();
    });
  }

  void _moveQuestionUp(int index) {
    setState(() {
      if (index > 0) {
        final temp = _questions[index];
        _questions[index] = _questions[index - 1];
        _questions[index - 1] = temp;
      }
      _updateQuestions();
    });
  }

  void _moveQuestionDown(int index) {
    setState(() {
      if (index < _questions.length - 1) {
        final temp = _questions[index];
        _questions[index] = _questions[index + 1];
        _questions[index + 1] = temp;
      }
      _updateQuestions();
    });
  }

  void _updateQuestions() {
    widget.onQuestionsUpdated(_questions);
  }

  Widget _buildQuestionWidget(Map<String, dynamic> question, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          child: Row(
            children: [
              if (question['type'] != 'checkbox' &&
                  question['type'] != 'multiple_choice') ...[
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    size: 23.0, 
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          'ยืนยันการลบ',
                          style: GoogleFonts.sarabun(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          'คุณต้องการลบคำถามนี้หรือไม่?',
                          style: GoogleFonts.sarabun(
                            fontSize: 16.0,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('ยกเลิก'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _questions.removeAt(index);
                              });
                              _updateQuestions();

                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'ลบ',
                              style: GoogleFonts.sarabun(
                                fontSize: 16.0,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_drop_up_rounded,
                    size: 28.0, 
                  ),
                  onPressed: index > 0 ? () => _moveQuestionUp(index) : null,
                  constraints: const BoxConstraints(
                    minWidth: 40.0, 
                    minHeight: 40.0,
                  ),
                  splashRadius: 24.0, 
                ),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 28.0, 
                  ),
                  onPressed: index < widget.questions.length - 1
                      ? () => _moveQuestionDown(index)
                      : null,
                  constraints: const BoxConstraints(
                    minWidth: 40.0,
                    minHeight: 40.0,
                  ),
                  splashRadius: 24.0, 
                ),
              ],
              const Spacer(),

           
            ],
          ),
        ),
        if (question['type'] == 'checkbox' ||
            question['type'] == 'multiple_choice') ...[
       

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  size: 23.0,
                  color: Colors.grey, 
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        'ยืนยันการลบ',
                        style: GoogleFonts.sarabun(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Text(
                        'คุณต้องการลบคำถามนี้หรือไม่?',
                        style: GoogleFonts.sarabun(
                          fontSize: 16.0,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('ยกเลิก'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _questions.removeAt(index);
                            });
                            _updateQuestions();

                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'ลบ',
                            style: GoogleFonts.sarabun(
                              fontSize: 16.0,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.arrow_drop_up_rounded,
                  size: 28.0, 
                ),
                onPressed: index > 0 ? () => _moveQuestionUp(index) : null,
                constraints: const BoxConstraints(
                  minWidth: 40.0, 
                  minHeight: 40.0,
                ),
                splashRadius: 24.0,
              ),
              IconButton(
                icon: const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 28.0,
                ),
                onPressed: index < _questions.length - 1
                    ? () => _moveQuestionDown(index)
                    : null,
                constraints: const BoxConstraints(
                  minWidth: 40.0, 
                  minHeight: 40.0,
                ),
                splashRadius: 24.0,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                   
                    for (var q in _questions) {
                    
                      if (q['showOnMap'] is String) {
                        q['showOnMap'] =
                            q['showOnMap'] == 'true'; 
                      } else if (q['showOnMap'] is bool) {
                        q['showOnMap'] = false; 
                      }
                    }
                 
                    question['showOnMap'] = true;
                  });
                  _updateQuestions();
                },
                child: Container(
                  width: 24.0,
                  height: 24.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (question['showOnMap'] ==
                            true) 
                        ? Colors.blue
                        : Colors.grey[500],
                  ),
                  child: (question['showOnMap'] ==
                          true)
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16.0,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 8.0),
              const Text(
                'แสดงบนแผนที่',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
        ],
        TextField(
          controller: _controllers[index],
          onChanged: (value) {
            setState(() {
              question['label'] = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'แก้ไขคำถาม',
            filled: true,
            fillColor:
                Colors.grey[100], 
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
          ),
          style: GoogleFonts.sarabun(
           
            fontSize: 16.0,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16.0),
        if (question['type'] == 'text') ...[
          TextField(
            decoration: InputDecoration(
              hintText: 'กรอกข้อมูลที่นี่',
              filled: true,
              fillColor: Colors.grey[300], 
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
            ),
            style: GoogleFonts.sarabun(
             
              fontSize: 16.0, 
              color: Colors.black, 
            ),
          ),
        ] else if (question['type'] == 'number') ...[
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'กรอกข้อมูลที่นี่',
              filled: true,
              fillColor: Colors.grey[300],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
            ),
            style: GoogleFonts.sarabun(
              fontSize: 16.0,
              color: Colors.black, 
            ),
            enabled:
                false,
            cursorColor: Colors.grey, 
          ),
        ] else if (question['type'] == 'multiple_choice') ...[
          ...List<Widget>.from(
            question['options'].asMap().entries.map(
              (entry) {
                int index = entry.key;
                var option = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 2.0), 
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller:
                              TextEditingController(text: option['label']),
                          onChanged: (value) {
                            setState(() {
                              question['options'][index]['label'] = value;
                            });
                            _updateQuestions();
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 12.0,
                            ),
                          ),
                          style: GoogleFonts.sarabun(
                            
                            fontSize: 16.0,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    
                      SizedBox(
                        width: 24.0,
                        child: Align(
                          alignment: Alignment.center,
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.grey,
                              size: 20.0,
                            ),
                            onPressed: () {
                           
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                      'ยืนยันการลบ',
                                      style: GoogleFonts.sarabun(
                                     
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                    content: Text(
                                      'คุณต้องการลบตัวเลือกนี้ใช่หรือไม่?',
                                      style: GoogleFonts.sarabun(
                                       
                                        fontSize: 16.0,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); 
                                        },
                                        child: Text(
                                          'ยกเลิก',
                                          style: GoogleFonts.sarabun(
                                          
                                            fontSize: 16.0,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            question['options'].removeAt(
                                                index);
                                          });
                                          _updateQuestions();
                                          Navigator.of(context)
                                              .pop(); 
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'ตัวเลือกถูกลบออกแล้ว',
                                                style: GoogleFonts.sarabun(
                                               
                                                  fontSize: 16.0,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'ยืนยัน',
                                          style: GoogleFonts.sarabun(
                                        
                                            fontSize: 16.0,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      if (question['showOnMap'] == true) const SizedBox(width: 12.0),
                      if (question['showOnMap'] == true)
                        GestureDetector(
                          onTap: () async {
                          
                            String? selectedColor = await showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text(
                                    'เลือกสีที่แสดงบนแผนที่',
                                    style: GoogleFonts.sarabun(
                                  
                                      textStyle: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                  ),
                                  content: SingleChildScrollView(
                                    child: Wrap(
                                      spacing: 8.0,
                                      runSpacing: 8.0,
                                      children: colors.map((color) {
                                        return GestureDetector(
                                          onTap: () {
                                           
                                            Navigator.of(context).pop(color);
                                          },
                                          child: Container(
                                            width: 36.0,
                                            height: 36.0,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: hexToColor(color),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                );
                              },
                            );

                            if (selectedColor != null) {
                              setState(() {
                               
                                option['color'] = selectedColor;
                                _updateQuestions();
                              });
                            }
                          },
                          child: Container(
                            width: 24.0,
                            height: 24.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: option['color'] != null
                                  ? hexToColor(option['color'])
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.center, 
            child: SizedBox(
              width: double.infinity, 
              child: TextButton(
                onPressed: () {
                  setState(() {
                    question['options'].add({
                      'label': '',
                      'value': '',
                    });
                    _updateQuestions();
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF699BF7), 
                  padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal:
                          20), 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), 
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment
                      .center,
                  children: [
                    const Icon(
                      Icons.add,
                      size: 20,
                      color: Colors.white, 
                    ),
                    const SizedBox(width: 8), 
                    Text(
                      'เพิ่มตัวเลือก',
                      style: GoogleFonts.sarabun(
                  
                        fontSize: 16.0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ] else if (question['type'] == 'checkbox') ...[
          ...List<Widget>.from(
            question['options'].asMap().entries.map(
              (entry) {
                int index = entry.key;
                var option = entry.value;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300], 
                              borderRadius: BorderRadius.circular(8.0), 
                            ),
                            child: TextField(
                              controller:
                                  TextEditingController(text: option['label']),
                              onChanged: (value) {
                                setState(() {
                                  question['options'][index]['label'] = value;
                                  _updateQuestions();
                                });
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none, 
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 12.0,
                                ),
                              ),
                              style: GoogleFonts.sarabun(
                                fontSize: 16.0,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                            width: 2.0),
                        SizedBox(
                          width: 24.0,
                          child: Align(
                            alignment: Alignment.center,
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.grey,
                                size: 20.0,
                              ),
                              onPressed: () {
                               
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                        'ยืนยันการลบ',
                                        style: GoogleFonts.sarabun(
                                      
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue[600],
                                        ),
                                      ),
                                      content: Text(
                                        'คุณต้องการลบตัวเลือกนี้ใช่หรือไม่?',
                                        style: GoogleFonts.sarabun(
                                          
                                          fontSize: 16.0,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); 
                                          },
                                          child: Text(
                                            'ยกเลิก',
                                            style: GoogleFonts.sarabun(
                                           
                                              fontSize: 16.0,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              question['options'].removeAt(
                                                  index); 
                                            });
                                            _updateQuestions();
                                            Navigator.of(context)
                                                .pop(); 
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'ตัวเลือกถูกลบออกแล้ว',
                                                  style: GoogleFonts.sarabun(
                                                  
                                                    fontSize: 16.0,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'ยืนยัน',
                                            style: GoogleFonts.sarabun(
                                            
                                              fontSize: 16.0,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                        if (question['showOnMap'] == true)
                          const SizedBox(width: 12.0),
                        if (question['showOnMap'] == true)
                          GestureDetector(
                            onTap: () async {
                         
                              String? selectedColor = await showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(
                                      'เลือกสีที่แสดงบนแผนที่',
                                      style: GoogleFonts.sarabun(
                                      
                                        textStyle: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue[600],
                                        ),
                                      ),
                                    ),
                                    content: SingleChildScrollView(
                                      child: Wrap(
                                        spacing: 8.0,
                                        runSpacing: 8.0,
                                        children: colors.map((color) {
                                          return GestureDetector(
                                            onTap: () {
                                             
                                              Navigator.of(context).pop(color);
                                            },
                                            child: Container(
                                              width: 36.0,
                                              height: 36.0,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: hexToColor(color),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  );
                                },
                              );

                              if (selectedColor != null) {
                                setState(() {
                                 
                                  option['color'] = selectedColor;
                                  _updateQuestions();
                                });
                              }
                            },
                            child: Container(
                              width: 24.0,
                              height: 24.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: option['color'] != null
                                    ? hexToColor(option['color'])
                                    : Colors.grey[300],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5.0), 
                  ],
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.center, 
            child: SizedBox(
              width: double.infinity, 
              child: TextButton(
                onPressed: () {
                  setState(() {
                    question['options'].add({
                      'label': '',
                      'value': '',
                    });
                    _updateQuestions();
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF699BF7), 
                  padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal:
                          20), 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), 
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment
                      .center, 
                  children: [
                    const Icon(
                      Icons.add,
                      size: 20,
                      color: Colors.white, 
                    ),
                    const SizedBox(width: 8), 
                    Text(
                      'เพิ่มตัวเลือก',
                      style: GoogleFonts.sarabun(
                    
                        fontSize: 16.0,
                        color: Colors.white, 
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ] else ...[
          const Text('Unsupported question type'),
        ],
        const SizedBox(width: 12.0),
      ],
    );
  }
}
