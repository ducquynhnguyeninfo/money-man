import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:money_man/core/models/superIconModel.dart';
import 'package:money_man/core/models/walletModel.dart';
import 'package:money_man/core/services/firebase_firestore_services.dart';
import 'package:money_man/ui/screens/shared_screens/enter_amount_screen.dart';
import 'package:money_man/ui/widgets/custom_alert.dart';
import 'package:money_man/ui/widgets/icon_picker.dart';
import 'package:provider/provider.dart';

class AddWalletScreen extends StatefulWidget {
  @override
  _AddWalletScreenState createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  static var _formKey = GlobalKey<FormState>();
  String currencyName = 'Viet Nam Dong';

  Wallet wallet = Wallet(
      id: '0',
      name: 'newWallet',
      amount: 0,
      currencyID: 'VND',
      iconID: 'assets/icons/wallet_2.svg');

  @override
  Widget build(BuildContext context) {
    final _firestore = Provider.of<FirebaseFireStoreService>(context);
    return Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          leadingWidth: 70.0,
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0))),
          title: Text('Add Wallet',
              style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 15.0)),
          leading: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                primary: Colors.white,
                backgroundColor: Colors.transparent,
              )),
          actions: <Widget>[
            TextButton(
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    FocusScope.of(context).requestFocus(FocusNode());
                    var res = await _firestore.addWallet(this.wallet);
                    await _firestore.updateSelectedWallet(res);
                    Navigator.of(context).pop(res);
                  }
                },
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  primary: Colors.white,
                  backgroundColor: Colors.transparent,
                )),
          ],
        ),
        body: Container(
            color: Colors.black26,
            child: Form(
              key: _formKey,
              child: buildInput(),
            )));
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

  String convertMoneyType(double k) {
    String result = k.toString();
    var ff = result.split('.');
    String temp1 = ff[0];
    String temp2 = temp1.split('').reversed.join();
    result = '';
    int i = 0;
    for (int j = 0; j < temp2.length; j++) {
      result += temp2[j];
      i++;
      if (i % 3 == 0 && j + 1 != temp2.length) result += ',';
    }
    result = ff.length == 1
        ? result.split('').reversed.join()
        : result.split('').reversed.join() + '.';
    for (i = 1; i < ff.length; i++) result += ff[i];
    print(result);
    return result;
  }

  Widget buildInput() {
    return ListView(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              color: Colors.grey[900],
              margin: EdgeInsets.symmetric(vertical: 35.0, horizontal: 0.0),
              child: Column(
                children: [
                  Row(
                    //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: SuperIcon(
                          iconPath: wallet.iconID,
                          size: 49.0,
                        ),
                        onPressed: () async {
                          // TODO: Chọn icon cho ví
                          var data = await showCupertinoModalBottomSheet(
                            context: context,
                            builder: (context) => IconPicker(),
                          );
                          if (data != null) {
                            setState(() {
                              wallet.iconID = data;
                            });
                          }
                        },
                        iconSize: 70,
                        color: Color(0xff8f8f8f),
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.only(right: 50),
                          width: 250,
                          child: TextFormField(
                            autocorrect: false,
                            keyboardType: TextInputType.name,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                            decoration: InputDecoration(
                              errorBorder: UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.red, width: 1),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.white60, width: 1),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.white60, width: 3),
                              ),
                              labelText: 'Name',
                              labelStyle: TextStyle(
                                  color: Colors.white60, fontSize: 15),
                            ),
                            onChanged: (value) => wallet.name = value,
                            validator: (value) {
                              if (value == null || value.length == 0)
                                return 'Name is empty';
                              return (value != null && value.contains('@'))
                                  ? 'Do not use the @ char.'
                                  : null;
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                  Divider(
                    thickness: 0.05,
                    color: Colors.white,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.fromLTRB(30, 0, 20, 0),
                    onTap: () {
                      showCurrencyPicker(
                        theme: CurrencyPickerThemeData(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20.0)),
                          ),
                          flagSize: 26,
                          titleTextStyle: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 17,
                              color: Colors.black,
                              fontWeight: FontWeight.w700),
                          subtitleTextStyle: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 15,
                              color: Colors.black
                          ),
                          //backgroundColor: Colors.grey[900],
                        ),
                        onSelect: (value) {
                          wallet.currencyID = value.code;
                          setState(() {
                            currencyName = value.name;
                          });
                        },
                        context: context,
                        showFlag: true,
                        showCurrencyName: true,
                        showCurrencyCode: true,
                      );
                    },
                    dense: true,
                    leading: Icon(Icons.monetization_on,
                        size: 30.0, color: Colors.white24),
                    title: Text(currencyName,
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            fontSize: 16.0
                        )
                    ),
                    trailing: Icon(Icons.chevron_right,
                        size: 20.0, color: Colors.white),
                  ),
                  Divider(
                    thickness: 0.05,
                    color: Colors.white,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.fromLTRB(30, 0, 20, 10),
                    onTap: () async {
                      final resultAmount = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => EnterAmountScreen()));
                      if (resultAmount != null)
                        setState(() {
                          print(resultAmount);
                          wallet.amount = double.parse(resultAmount);
                        });
                    },
                    dense: true,
                    leading: Icon(Icons.account_balance,
                        size: 30.0, color: Colors.white24),
                    title: Text(
                        wallet.amount == null
                            ? 'Enter initial balance'
                            : convertMoneyType(wallet.amount),
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            fontSize: 16.0
                        )
                    ),
                    trailing: Icon(Icons.chevron_right,
                        size: 20.0, color: Colors.white),
                  )
                  /*Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 8),
                    child: Row(
                      //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(
                            Icons.account_balance_outlined,
                            color: Color(0xff8f8f8f),
                            size: 30,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.only(left: 15, right: 50),
                            width: 250,
                            child: TextFormField(
                              onTap: () {
                                print('print');
                              },
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: Colors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),*/
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                // Xử lý sự kiện click ở đây.
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                alignment: Alignment.center,
                width: double.infinity,
                color: Colors.grey[900],
                child: Text(
                  'Link to service',
                  style: TextStyle(
                      color: Colors.green,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Montserrat'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
