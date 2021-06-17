import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:money_formatter/money_formatter.dart';
import 'package:money_man/core/models/budget_model.dart';
import 'package:money_man/core/models/event_model.dart';
import 'package:money_man/core/models/super_icon_model.dart';
import 'package:money_man/core/models/transaction_model.dart';
import 'package:money_man/core/models/wallet_model.dart';
import 'package:money_man/core/services/constaints.dart';
import 'package:money_man/core/services/firebase_firestore_services.dart';
import 'package:money_man/ui/screens/planning_screens/budget_screens/add_budget.dart';
import 'package:money_man/ui/screens/planning_screens/budget_screens/widget/budget_tile.dart';
import 'package:money_man/ui/screens/transaction_screens/edit_transaction_screen.dart';
import 'package:money_man/ui/widgets/accept_dialog.dart';
import 'package:money_man/ui/widgets/money_symbol_formatter.dart';
import 'package:provider/provider.dart';

class TransactionDetail extends StatefulWidget {
  final MyTransaction transaction;
  final Wallet wallet;

  TransactionDetail({
    Key key,
    @required this.transaction,
    @required this.wallet,
  }) : super(key: key);

  @override
  _TransactionDetailState createState() => _TransactionDetailState();
}

class _TransactionDetailState extends State<TransactionDetail> {
  bool isDebtOrLoan;
  Event event;
  MyTransaction _transaction;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
    isDebtOrLoan = _transaction.category.name == 'Debt' ||
        _transaction.category.name == 'Loan';
    Future.delayed(Duration.zero, () async {
      var res = await getEvent(_transaction.eventID, widget.wallet);
      setState(() {
        event = res;
      });
    });
  }

  Future<Event> getEvent(String id, Wallet wallet) async {
    if (id == '' || id == null) return null;
    final _firestore =
        Provider.of<FirebaseFireStoreService>(context, listen: false);
    var _event = await _firestore.getEventByID(id, wallet);
    return _event;
  }

  @override
  Widget build(BuildContext context) {
    final _firestore = Provider.of<FirebaseFireStoreService>(context);
    // getEvent(_transaction.eventID, widget.wallet);
    print(event);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.close_sharp),
        ),
        title: Text('Transaction'),
        centerTitle: false,
        actions: [
          IconButton(
              icon: Icon(
                Icons.share,
                color: Colors.white,
              ),
              onPressed: () async {
                //Todo: Edit transaction
              }),
          IconButton(
              icon: Icon(
                Icons.edit,
                color: Colors.white,
              ),
              onPressed: () async {
                final updatedTrans = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EditTransactionScreen(
                              transaction: _transaction,
                              wallet: widget.wallet,
                              event: event,
                            )));
                if (updatedTrans != null)
                  setState(() {
                    _transaction = updatedTrans;
                  });
              }),
          IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: () async {
                //TODO: Thuc hien xoa transaction

                String result = await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) {
                      return AlertDialog(
                        title: Text(
                          'Delete this transaction?',
                          style: TextStyle(
                            color: Colors.red,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        actions: [
                          FlatButton(
                              onPressed: () {
                                Navigator.pop(context, 'No');
                              },
                              child: Text('No')),
                          FlatButton(
                              onPressed: () {
                                Navigator.pop(context, 'Yes');
                                // chưa có animation để back ra transaction screen
                              },
                              child: Text('Yes'))
                        ],
                      );
                    });
                if (result == 'Yes') {
                  await _firestore.deleteTransaction(
                      _transaction, widget.wallet);
                  Navigator.pop(context);
                }
              })
        ],
        backgroundColor: Color(0xff333333),
      ),
      body: Container(
        color: Color(0xff1a1a1a),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                  child: SuperIcon(
                iconPath: _transaction.category.iconID,
                size: 45,
              )),
              title: Container(
                padding: EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _transaction.category.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                        fontSize: 30,
                      ),
                    ),
                    Container(
                        margin: EdgeInsets.only(top: 30),
                        child: MoneySymbolFormatter(
                          text: _transaction.amount,
                          currencyId: widget.wallet.currencyID,
                          textStyle: TextStyle(
                              color: Colors.red[400],
                              fontSize: 30,
                              fontWeight: FontWeight.w200),
                        )),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            // Nếu có note thì chèn thêm note vào <3
            _transaction.note != ''
                ? ListTile(
                    leading: Container(
                      padding: EdgeInsets.only(left: 10),
                      child: Icon(
                        Icons.textsms_outlined,
                        color: white,
                      ),
                    ),
                    title: Container(
                      padding: EdgeInsets.only(left: 5),
                      child: Text(
                        '${_transaction.note}',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    width: 1,
                  ),
            ListTile(
              leading: Container(
                  padding: EdgeInsets.only(left: 10),
                  child: Icon(
                    Icons.date_range_outlined,
                    color: Colors.white,
                  )),
              title: Container(
                padding: EdgeInsets.only(left: 5),
                child: Text(
                  _transaction.date.toString(),
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.only(left: 10),
                child: SuperIcon(
                  iconPath: '${widget.wallet.iconID}',
                  size: 25,
                ),
              ),
              title: Container(
                padding: EdgeInsets.only(left: 5),
                child: Text(
                  '${widget.wallet.name}',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                    flex: 1,
                    child: Icon(Icons.account_balance,
                        color: Colors.grey[500], size: 25.0)),
                Expanded(
                    flex: 3,
                    child: Text(
                        _transaction.contact == null
                            ? 'With someone'
                            : 'With ${_transaction.contact}',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: ' Montserrat',
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0))),
              ],
            ),
            isDebtOrLoan
                ? DebtLoanSection(transaction: _transaction)
                : Container(),
            SizedBox(height: 10),
            (_transaction.eventID != "" && _transaction.eventID != null)
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                          flex: 1,
                          child: SuperIcon(
                            iconPath: event != null
                                ? event.iconPath
                                : 'assets/images/email.svg',
                            size: 25.0,
                          )),
                      Expanded(
                          flex: 3,
                          child: Text(event != null ? event.name : 'a',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: ' Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0))),
                    ],
                  )
                : Row(),
            Divider(
              color: Colors.white60,
            ),

            // Này là để hiện budget đã có hoặc tùy chọn thêm budget
            StreamBuilder<List<Budget>>(
                stream: _firestore.budgetTransactionStream(
                    _transaction, widget.wallet.id),
                builder: (context, snapshot) {
                  List<Budget> budgets = snapshot.data ?? [];
                  print('Nafy la in tu transaction detail');

                  // Nếu không có budgets nào có categories trùng với transaction hiển thị tùy chọn thêm transaction
                  if (budgets.length == 0)
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.only(top: 25, bottom: 15),
                            child: Text('Budget',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w500)),
                          ),
                          Text(
                            'This transaction is not within a budget, but it should be within a budget so you can better manage your finances.',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 15),
                          ),
                          SizedBox(
                            height: 40,
                          ),
                          Center(
                            child: GestureDetector(
                              onTap: () async {
                                await showCupertinoModalBottomSheet(
                                    isDismissible: true,
                                    backgroundColor: Colors.grey[900],
                                    context: context,
                                    builder: (context) => AddBudget(
                                          wallet: widget.wallet,
                                          myCategory: _transaction.category,
                                        ));
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                width: 300,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Color(0xFF2FB49C)),
                                    borderRadius: BorderRadius.circular(5)),
                                child: Text(
                                  "ADD BUDGET FOR THIS TRANSACTION",
                                  style: TextStyle(
                                      color: Color(0xFF2FB49C),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  budgets.sort((b, a) => b.beginDate.compareTo(a.beginDate));
                  for (int i = 0; i < budgets.length; i++) {
                    if (budgets[i].endDate.isBefore(DateTime.now())) {
                      budgets.removeAt(i);
                      i--;
                    }
                  }
                  /*return Column(
                    children: [
                      for (int i = 0; i < budgets.length; i++)
                        MyBudgetTile(
                          budget: budgets[i],
                          wallet: widget.wallet,
                        ),
                    ],
                  );*/
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.only(left: 15, top: 20, bottom: 10),
                        child: Text('Budget',
                            style: TextStyle(color: white, fontSize: 25)),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Text(
                          'This transaction belongs to the following budgets',
                          style: TextStyle(color: white),
                        ),
                      ),
                      SizedBox(
                        height: 14,
                      ),
                      Container(
                        height: MediaQuery.of(context).size.height - 450,
                        child: ListView.builder(
                          itemCount: budgets == null ? 0 : budgets.length,
                          itemBuilder: (context, index) => Column(
                            children: [
                              MyBudgetTile(
                                budget: budgets[index],
                                wallet: widget.wallet,
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                })
          ],
        ),
      ),
    );
  }

  Future<String> _showAcceptionDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // user must tap button!
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return CustomAcceptAlert(
          content: 'Do you want to delete this transaction?',
        );
      },
    );
  }
}

class DebtLoanSection extends StatelessWidget {
  final MyTransaction transaction;
  const DebtLoanSection({
    Key key,
    @required this.transaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(flex: 1, child: Text('Paid')),
              Expanded(flex: 3, child: Text('Left')),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                  flex: 1,
                  child: Text((transaction.amount - transaction.extraAmountInfo)
                      .toString())),
              Expanded(
                  flex: 3, child: Text(transaction.extraAmountInfo.toString())),
            ],
          ),
          Container(
            padding: EdgeInsets.fromLTRB(50, 20, 15, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                backgroundColor: Color(0xff161616),
                valueColor: AlwaysStoppedAnimation<Color>(
                    (transaction.amount - transaction.extraAmountInfo) /
                                (transaction.amount) ==
                            1
                        ? Color(0xFF2FB49C)
                        : Colors.yellow),
                minHeight: 8,
                value: (transaction.amount - transaction.extraAmountInfo) /
                    (transaction.amount),
              ),
            ),
          ),
          Row(
            children: [
              if (transaction.extraAmountInfo != 0)
                OutlineButton(
                    onPressed: () {},
                    child: Text(
                      'Cash back',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: ' Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0),
                    )),
              OutlineButton(
                  onPressed: () {},
                  child: Text(
                    'Transaction List',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: ' Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0),
                  ))
            ],
          )
        ],
      ),
    );
  }
}
