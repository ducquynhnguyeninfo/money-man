import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_formatter/money_formatter.dart';
import 'package:money_man/core/models/categoryModel.dart';
import 'package:money_man/core/models/transactionModel.dart';
import 'package:money_man/core/models/walletModel.dart';
import 'package:money_man/core/services/firebase_firestore_services.dart';
import 'package:money_man/ui/screens/categories_screens/categories_transaction_screen.dart';
import 'package:money_man/ui/screens/shared_screens/enter_amount_screen.dart';
import 'package:money_man/ui/screens/wallet_selection_screens/wallet_account_screen.dart';
import 'package:provider/provider.dart';

class AddTransactionScreen extends StatefulWidget {
  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  DateTime pickDate;
  double amount;
  MyCategory cate;
  Wallet wallet;
  String note;

  @override
  Widget build(BuildContext context) {
    final _firestore = Provider.of<FirebaseFireStoreService>(context);
    print('add build');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Add transaction',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          color: Colors.black,
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
              onPressed: () async {
                if (wallet != null && cate != null && amount != null) {
                  MyTransaction trans;
                  if (pickDate == null) {
                    trans = MyTransaction(
                        id: 'id',
                        amount: amount,
                        note: note,
                        date: DateTime.parse(
                            DateFormat("yyyy-MM-dd").format(DateTime.now())),
                        currencyID: wallet.currencyID,
                        category: cate);
                    print(trans.date.toString() + "chua pick");
                  } else {
                    trans = MyTransaction(
                        id: 'id',
                        amount: amount,
                        note: note,
                        date: pickDate,
                        currencyID: wallet.currencyID,
                        category: cate);
                    print(trans.date.toString() + 'da pick');
                  }
                  await _firestore.addTransaction(wallet, trans);
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Save',
                style: TextStyle(color: Colors.black),
              ))
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            onTap: () async {
              final resultAmount = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => EnterAmountScreen()));
              if (resultAmount != null)
                setState(() {
                  print(resultAmount);
                  amount = double.parse(resultAmount);
                });
            },
            leading: Icon(Icons.money),
            title: TextFormField(
              readOnly: true,
              onTap: () async {
                final resultAmount = await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => EnterAmountScreen()));
                if (resultAmount != null)
                  setState(() {
                    print(resultAmount);
                    amount = double.parse(resultAmount);
                  });
              },
              // onChanged: (value) => amount = double.tryParse(value),
              style: TextStyle(color: Colors.green),
              decoration: InputDecoration(
                  hintStyle: TextStyle(color: Colors.green),
                  hintText: amount == null
                      ? '0'
                      : MoneyFormatter(amount: amount)
                          .output
                          .withoutFractionDigits),
            ),
          ),
          ListTile(
              onTap: () async {
                final selectCate = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CategoriesTransactionScreen()));
                if (selectCate != null) {
                  setState(() {
                    this.cate = selectCate;
                  });
                }
              },
              leading: cate == null
                  ? Icon(Icons.question_answer)
                  : Icon(Icons.ac_unit),
              title: TextField(
                onTap: () async {
                  final selectCate = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CategoriesTransactionScreen()));
                  if (selectCate != null) {
                    setState(() {
                      this.cate = selectCate;
                    });
                  }
                },
                readOnly: true,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                    hintText:
                        this.cate == null ? 'Select category' : this.cate.name),
              )),
          ListTile(
            leading: Icon(Icons.note),
            title: TextFormField(
              decoration: InputDecoration(hintText: 'Write note'),
              style: TextStyle(color: Colors.black),
              onChanged: (value) => note = value,
            ),
          ),
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: TextFormField(
              onTap: () async {
                DateTime now = DateTime.now();
                pickDate = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2030));

                if (pickDate != null) {
                  if (pickDate.day != now.day ||
                      pickDate.month != now.month ||
                      pickDate.year != now.year) {
                    setState(() {
                      pickDate = DateTime.tryParse(
                          DateFormat('yyyy-MM-dd').format(pickDate));
                    });
                  }
                }
              },
              readOnly: true,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                  hintText: pickDate == null
                      ? 'Today'
                      : DateFormat('EEEE, dd-MM-yyyy').format(pickDate)),
            ),
          ),
          ListTile(
            onTap: () async {
              wallet = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SelectWalletAccountScreen()));
            },
            leading: Icon(wallet == null
                ? Icons.account_balance_wallet_rounded
                : IconData(int.tryParse(wallet.iconID),
                    fontFamily: 'MaterialIcons')),
            title: TextFormField(
              readOnly: true,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                  hintText: wallet == null ? 'Select wallet' : wallet.name),
              onTap: () async {
                wallet = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SelectWalletAccountScreen()));
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}