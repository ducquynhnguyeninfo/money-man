import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:money_man/core/services/constaints.dart';
import 'package:money_man/ui/screens/account_screens/account_edit_information_screen.dart';
import 'package:money_man/ui/screens/introduction_screens/first_step.dart';
import 'package:money_man/ui/widgets/custom_alert.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final auth = FirebaseAuth.instance;

  Timer timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 5), (timer) {
      checkIfEmailVerified();
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;
    final RoundedLoadingButtonController _btnController =
        new RoundedLoadingButtonController();
    final RoundedLoadingButtonController _btnController2 =
        new RoundedLoadingButtonController();
    return Scaffold(
      backgroundColor: Color(0xff1a1a1a),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(20, 50, 0, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(0, 0, 30, 0),
                    child: Text(
                      'Verify your email',
                      style: TextStyle(
                          color: yellow,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 35),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(0, 0, 30, 0),
                    child: Text(
                      'to keep using',
                      style: TextStyle(
                          color: yellow,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(0, 0, 30, 0),
                    child: Text(
                      'Money Man',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 45),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 50,
            ),
            Center(
              child: Container(
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/logoEmail.png'),
                    fit: BoxFit.fill,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              child: RoundedLoadingButton(
                height: 40,
                width: 200,
                color: Color(0xff2FB49C),
                child: Text('Verify email!',
                    style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        color: black)),
                controller: _btnController,
                onPressed: () async {
                  if (user.email.contains('gmail') == false) {
                    await user.sendEmailVerification();
                  } else {
                    final res = await _handleLinkWithGoogle(user.email);
                    if (res == null) {
                      await _showAlertDialog('There is something wrong!');
                      await user.delete();
                    }
                  }
                  final timer2 =
                      Timer.periodic(Duration(seconds: 3), (timer) {});

                  _btnController.success();
                },
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              child: RoundedLoadingButton(
                height: 40,
                width: 200,
                color: Color(0xff2FB49C),
                child: Text('Back',
                    style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        color: black)),
                controller: _btnController2,
                onPressed: () async {
                  await auth.signOut();
                },
              ),
            ),
            Center(
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 50, horizontal: 40),
                child: Text(
                  ' Click the button then check your mailbox to get your verify email link! \n ',
                  style: TextStyle(
                    color: white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future checkIfEmailVerified() async {
    var user = auth.currentUser;
    await user.reload();
    if (user.emailVerified) {
      timer.cancel();
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => AccountInformationScreen()));
    }
  }

  Future _handleLinkWithGoogle(String _email) async {
    try {
      final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final GoogleAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      if (_email.contains('gmail')) {
        // print('link');
        if (_email != googleUser.email) {
          await GoogleSignIn().signOut();
          await _showAlertDialog(
              'The google account and the email is different! Please sign up again!');
          await auth.currentUser.delete();

          // Navigator.pop(context);
        } else {
          try {
            UserCredential res =
                await auth.currentUser.linkWithCredential(credential);
          } on FirebaseAuthException catch (e) {
            // TODO
            print(e.code);
            return null;
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String error = '';
      switch (e.code) {
        case 'account-exists-with-different-credential':
          error =
              "This account is linked with another provider! Try another provider!";
          break;
        case 'email-already-in-use':
          error = "Your email address has been registered.";
          break;
        case 'invalid-credential':
          error = "Your credential is malformed or has expired.";
          break;
        case 'user-disabled':
          error = "This user has been disable.";
          break;
        default:
          error = e.code;
      }
      _showAlertDialog(error);
    }
  }

  Future<void> _showAlertDialog(String content) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return CustomAlert(content: content);
      },
    );
  }
}
