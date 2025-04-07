import 'package:flutter/material.dart';
import 'package:geosociomap/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField(
      {super.key,
      required this.textField,
      required this.labelText,
      required this.controller,
      required this.icon,
      this.obscureText = false});
  final TextField textField;
  final String labelText;
  final TextEditingController controller;
  final bool obscureText;
  final Icon icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          width: 1,
          color: Colors.blue.shade100,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          icon: icon,
          labelText: labelText,
          labelStyle: GoogleFonts.sarabun(
            textStyle: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class CustomTextInput extends StatelessWidget {
  const CustomTextInput(
      {super.key,
      // required this.textField,
      required this.labelText,
      required this.controller,
      this.obscureText = false});
  // final TextField textField;
  final String labelText;
  final TextEditingController controller;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.0),
      decoration: BoxDecoration(
        color: Colors.grey[200], 
        borderRadius: BorderRadius.circular(8), 
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[200],
          border: InputBorder.none,
          hintText: labelText,
          hintStyle: TextStyle(color: Colors.grey[600]), 
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  const CustomButton(
      {super.key,
      required this.buttonText,
      this.isOutlined = false,
      required this.onPressed,
      this.width = 280});

  final String buttonText;
  final bool isOutlined;
  final Function onPressed;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onPressed();
      },
      child: Material(
        borderRadius: BorderRadius.circular(30),

    
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 9),
          decoration: BoxDecoration(
            color: isOutlined ? Colors.white : Colors.blue.shade300,
            border: Border.all(color: Colors.blue.shade300, width: 2.5),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              buttonText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isOutlined ? kTextColor : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomBottomScreen extends StatelessWidget {
  const CustomBottomScreen({
    super.key,
    required this.textButton,
    required this.question,
    this.heroTag = '',
    required this.buttonPressed,
    required this.questionPressed,
  });
  final String textButton;
  final String question;
  final String heroTag;
  final Function buttonPressed;
  final Function questionPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            child: GestureDetector(
              onTap: () {
                questionPressed();
              },
              child: Text(
                question,
                style: const TextStyle(
                  color: Colors.blue, 
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Hero(
            tag: heroTag,
            child: CustomButton(
              buttonText: textButton,
              width: 160,
              onPressed: () {
                buttonPressed();
              },
            ),
          ),
        ),
      ],
    );
  }
}

class TopScreenImage extends StatelessWidget {
  const TopScreenImage({super.key, required this.screenImageName});
  final String screenImageName;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.contain,
            image: AssetImage('assets/images/$screenImageName'),
          ),
        ),
      ),
    );
  }
}

Alert signUpAlert({
  required Function onPressed,
  required String title,
  required String desc,
  required String btnText,
  required BuildContext context,
}) {
  return Alert(
    context: context,
    title: title,
    desc: desc,
    buttons: [
      DialogButton(
        onPressed: () {
          onPressed();
        },
        width: 120,
        child: Text(
          btnText,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    ],
  );
}

Alert showAlert({
  required Function onPressed,
  required String title,
  required String desc,
  required BuildContext context,
}) {
  return Alert(
    context: context,
    type: AlertType.error,
    title: title,
    desc: desc,
    buttons: [
      DialogButton(
        onPressed: () {
          onPressed();
        },
        width: 120,
        child: const Text(
          "OK",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      )
    ],
  );
}

class ScreenTitle extends StatelessWidget {
  const ScreenTitle({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }
}

class OtpForm extends StatefulWidget {
  const OtpForm({
    super.key,
    required this.callBack,
  });
  final Function(String) callBack;
  @override
  State<OtpForm> createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> {
  final TextEditingController _num1 = TextEditingController();
  final TextEditingController _num2 = TextEditingController();
  final TextEditingController _num3 = TextEditingController();
  final TextEditingController _num4 = TextEditingController();
  final TextEditingController _num5 = TextEditingController();
  final TextEditingController _num6 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      child: KeyboardListener(
        autofocus: false,
        focusNode: FocusNode(canRequestFocus: false),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.backspace) {
              FocusScope.of(context).previousFocus();
            }
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: TextFormField(
                autofocus: true,
                controller: _num1,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(//
                      RegExp(r'[0-9]')),
                ],
                onSaved: (pin1) {},
                onChanged: (value) {
                  if (value.length == 1) {
                    FocusScope.of(context).nextFocus();
                  }
                },
                keyboardType: TextInputType.number,
                maxLength: 1,
                decoration: const InputDecoration(
                  counterText: "",
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 20,
              width: 20,
              child: TextFormField(
                autofocus: true,
                controller: _num2,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(//
                      RegExp(r'[0-9]')),
                ],
                onSaved: (pin2) {},
                onChanged: (value) {
                  if (value.length == 1) {
                    FocusScope.of(context).nextFocus();
                  }
                },
                keyboardType: TextInputType.number,
                maxLength: 1,
                decoration: const InputDecoration(
                  counterText: "",
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 20,
              width: 20,
              child: TextFormField(
                autofocus: true,
                controller: _num3,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(//
                      RegExp(r'[0-9]')),
                ],
                onSaved: (pin3) {},
                onChanged: (value) {
                  if (value.length == 1) {
                    FocusScope.of(context).nextFocus();
                  }
                },
                keyboardType: TextInputType.number,
                maxLength: 1,
                decoration: const InputDecoration(
                  counterText: "",
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 20,
              width: 20,
              child: TextFormField(
                autofocus: true,
                controller: _num4,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(//
                      RegExp(r'[0-9]')),
                ],
                onSaved: (pin4) {},
                onChanged: (value) {
                  if (value.length == 1) {
                    FocusScope.of(context).nextFocus();
                  }
                },
                keyboardType: TextInputType.number,
                maxLength: 1,
                decoration: const InputDecoration(
                  counterText: "",
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 20,
              width: 20,
              child: TextFormField(
                autofocus: true,
                controller: _num5,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(//
                      RegExp(r'[0-9]')),
                ],
                onSaved: (pin5) {},
                onChanged: (value) {
                  if (value.length == 1) {
                    FocusScope.of(context).nextFocus();
                  }
                },
                keyboardType: TextInputType.number,
                maxLength: 1,
                decoration: const InputDecoration(
                  counterText: "",
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 20,
              width: 20,
              child: TextFormField(
                autofocus: true,
                controller: _num6,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(//
                      RegExp(r'[0-9]')),
                ],
                onSaved: (pin6) {},
                onChanged: (value) {
                  if (value.length == 1) {
                    widget.callBack(_num1.text +
                        _num2.text +
                        _num3.text +
                        _num4.text +
                        _num5.text +
                        _num6.text);
                  }
                },
                keyboardType: TextInputType.number,
                maxLength: 1,
                decoration: const InputDecoration(
                  counterText: "",
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class CustomSearchBar extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Align(
//         alignment: Alignment.center, // จัดชิดขวามือ
//         child: Container(
//           constraints: BoxConstraints(
//             minWidth: 200,
//             maxWidth: 300,
//           ),
//           // padding: const EdgeInsets.all(16.0),
//           child: Container(
//             constraints: BoxConstraints(
//               maxHeight: 35,
//             ),
//             decoration: BoxDecoration(
//               color: Colors.grey[200],
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: TextField(
//               textAlignVertical: TextAlignVertical.center,
//               decoration: InputDecoration(
//                 prefixIcon: Container(
//                   child: Icon(
//                     Icons.search_rounded,
//                     color: Colors.grey,
//                     size: 20,
//                   ),
//                 ),
//                 hintText: 'ค้นหา',
//                 hintStyle: GoogleFonts.sarabun(
//                   textStyle: TextStyle(
//                     color: Colors.grey,
//                     fontSize: 14,
//                   ),
//                 ),
//                 border: InputBorder.none,
//                 contentPadding: EdgeInsets.symmetric(vertical: 11.0),
//               ),
//               style: GoogleFonts.sarabun(
//                 textStyle: TextStyle(
//                   color: Colors.black,
//                   fontSize: 14,
//                 ),
//               ), // Apply Sarabun font to the input text
//             ),
//           ),
//         ));
//   }
// }

class ProjectCard extends StatelessWidget {
  final String projectName;
  final String lastUpdate;
  final VoidCallback onTap;

  const ProjectCard({super.key, 
    required this.projectName,
    required this.lastUpdate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 400,
          maxWidth: 500,
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.lightBlue[50],
              borderRadius: BorderRadius.circular(10),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200, // Bottom border color
                  width: 1.0, // Bottom border thickness
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Icon Container
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      // ทำให้ Icon อยู่ตรงกลาง Container
                      child: Icon(
                        Icons.location_on_rounded,
                        color: Colors.blue[400],
                        size: 50, // ปรับขนาดไอคอนให้ใหญ่ขึ้น
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          projectName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlue.shade800,
                            overflow: TextOverflow.ellipsis, 
                          ),
                          maxLines: 1, 
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'แก้ไขล่าสุด $lastUpdate',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade300,
                          ),
                        ),
                      ],
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

class MapSearchBar extends StatelessWidget {
  const MapSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.center, // จัดชิดขวามือ
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 300,
            maxWidth: 350,
          ),
          // padding: const EdgeInsets.all(16.0),
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 35,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.0),
                prefixIcon: Container(
                  child: const Icon(
                    Icons.search_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
                hintText: 'ค้นหา',
                hintStyle: GoogleFonts.sarabun(
                  textStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11.0),
              ),
              style: GoogleFonts.sarabun(
                textStyle: const TextStyle(
                  color: Colors.black, 
                  fontSize: 14,
                ),
              ), 
            ),
          ),
        ));
  }
}
