import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:money_formatter/money_formatter.dart';
import 'package:money_man/core/models/budget_model.dart';
import 'package:money_man/core/models/super_icon_model.dart';
import 'package:money_man/core/models/wallet_model.dart';
import 'package:money_man/core/services/firebase_firestore_services.dart';
import 'package:money_man/ui/screens/planning_screens/budget_screens/edit_budget.dart';
import 'package:money_man/ui/screens/planning_screens/budget_screens/widget/line_chart_progress.dart';
import 'package:money_man/ui/screens/shared_screens/search_transaction_screen.dart';
import 'package:money_man/ui/widgets/accept_dialog.dart';
import 'package:provider/provider.dart';
import 'package:money_man/ui/screens/planning_screens/budget_screens/budget_transaction.dart';

class BudgetDetailScreen extends StatefulWidget {
  const BudgetDetailScreen({Key key, this.budget, this.wallet})
      : super(key: key);
  final Budget budget;
  final Wallet wallet;

  @override
  _BudgetDetailScreenState createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  bool isNotifi = false;

  // Hàm trả về string mô tả khoảng thời gian theo ngày tháng năm
  String valueDate(Budget budget) {
    String result = DateFormat('dd/MM/yyyy').format(budget.beginDate) +
        ' - ' +
        DateFormat('dd/MM/yyyy').format(budget.endDate);
    return result;
  }

  //Hàm trả về string mô tả thời gian hiện tại tương ứng với thời gian của budget như thế nào
  String TimeLeft(Budget budget) {
    var today = DateTime.now();
    if (today.isBefore(budget.beginDate)) {
      int n = budget.beginDate.difference(today).inDays;
      if (n > 1) {
        return '$n days to begin';
      } else
        return '$n day to begin';
    } else if (today.isAfter(budget.endDate)) {
      return 'Finished';
    } else {
      int n = budget.endDate.difference(today).inDays;
      if (n > 1) {
        return '$n days left';
      } else
        return '$n day left';
    }
  }

  @override
  Widget build(BuildContext context) {
    final _firestore = Provider.of<FirebaseFireStoreService>(context);
    bool isStart;
    DateTime today = DateTime.now();
    // todayRate là biến biểu thị tỉ lệ thời gian hiện tại trong khoảng thời gian của budget. nếu >1 đã kết thúc, <0 chưa bắt đầu
    var todayRate = today.difference(widget.budget.beginDate).inDays /
        widget.budget.endDate.difference(widget.budget.beginDate).inDays;
    var todayTarget = widget.budget.spent / widget.budget.amount;
    if (today.isBefore(widget.budget.beginDate))
      isStart = false;
    else
      isStart = true;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.close_sharp),
        ),
        title: Text('Budget'),
        centerTitle: true,
        actions: [
          // Button chỉnh sửa budget
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Colors.white,
            ),
            onPressed: () async {
              var result = await showCupertinoModalBottomSheet(
                  isDismissible: true,
                  backgroundColor: Colors.grey[900],
                  context: context,
                  builder: (context) => EditBudget(
                        budget: widget.budget,
                        wallet: widget.wallet,
                      ));
              setState(() {});
            },
          ),
          IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: () async {
                String res = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('Delete Budget'),
                    content: const Text('Do you want to delete this budget?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'Cancel'),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'OK'),
                        child: const Text('yes'),
                      ),
                    ],
                  ),
                );
                print(res);
                if (res == 'OK') {
                  await _firestore.deleteBudget(
                      widget.budget.walletId, widget.budget.id);
                  Navigator.pop(context);
                }
              })

          /*IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: () async {
                //TODO: Thuc hien xoa budget
                String result = await _showAcceptionDialog();
                print(result);
                if (result == 'no') {
                  return;
                } else {
                  await _firestore.deleteBudget(
                      widget.budget.walletId, widget.budget.id);
                  Navigator.pop(context);
                }
              })*/
        ],
        backgroundColor: Color(0xff333333),
      ),
      body: Container(
        color: Color(0xff1a1a1a),
        child: ListView(
          children: [
            ListTile(
              leading: Container(
                  child: SuperIcon(
                iconPath: widget.budget.category.iconID,
                size: 45,
              )),
              title: Container(
                padding: EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      this.widget.budget.category.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                        fontSize: 30,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 30),
                      child: Text(
                        MoneyFormatter(amount: this.widget.budget.amount)
                            .output
                            .withoutFractionDigits,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w200),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 20),
                      padding: EdgeInsets.only(right: 10),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Spent',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white54,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      MoneyFormatter(
                                              amount: this.widget.budget.spent)
                                          .output
                                          .withoutFractionDigits,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      todayTarget > 1 ? 'Over spent' : 'Remain',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white54,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      MoneyFormatter(
                                              amount: todayTarget > 1
                                                  ? this.widget.budget.spent -
                                                      this.widget.budget.amount
                                                  : this.widget.budget.amount -
                                                      this.widget.budget.spent)
                                          .output
                                          .withoutFractionDigits,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 5),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                  backgroundColor: Color(0xff333333),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      todayTarget > 1
                                          ? Colors.red[700]
                                          : todayTarget > todayRate
                                              ? Colors.orange[700]
                                              : Color(0xFF2FB49C)),
                                  minHeight: 8,
                                  value: this.widget.budget.spent /
                                      this.widget.budget.amount),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                // Nếu chưa bắt đầu hoặc hết hạn thì không để today
                widget.budget.beginDate.isAfter(today) ||
                        today.isAfter(widget.budget.endDate)
                    ? Container()
                    : Container(
                        // Căn lề theo từng pixel, sử dụng kiến thức toán học để tính toán margin
                        margin: EdgeInsets.only(
                            left: 60 +
                                (MediaQuery.of(context).size.width - 60 - 45) *
                                    todayRate),
                        height: 20,
                        width: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Color(0xff171717)),
                        child: Text(
                          "Today",
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
              ],
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
                  valueDate(widget.budget),
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              subtitle: Container(
                padding: EdgeInsets.only(left: 5),
                child: Text(
                  TimeLeft(widget.budget),
                  style: TextStyle(
                    color: Colors.white54,
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
            GestureDetector(
              onTap: () {},
              child: Container(
                margin: EdgeInsets.only(top: 30),
                padding: EdgeInsets.only(left: 15, right: 30),
                color: Color(0xff1a1a1a),
                width: MediaQuery.of(context).size.width,
                height: 170,
                child: LineCharts(
                  budget: widget.budget,
                  todayRate: todayRate,
                  todayTaget: todayTarget,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 25),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Should spend/day ',
                          style: TextStyle(
                              color: Colors.white54,
                              fontWeight: FontWeight.w400,
                              fontSize: 13),
                        ),
                        SizedBox(
                          height: 2,
                        ),
                        Text(
                          MoneyFormatter(
                                  amount: widget.budget.amount /
                                      (widget.budget.endDate)
                                          .difference(widget.budget.beginDate)
                                          .inDays)
                              .output
                              .withoutFractionDigits,
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        )
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Actual spend/ day',
                          style: TextStyle(
                              color: Colors.white54,
                              fontWeight: FontWeight.w400,
                              fontSize: 13),
                        ),
                        SizedBox(
                          height: 2,
                        ),
                        Text(
                          MoneyFormatter(
                                  amount: widget.budget.spent /
                                      (today)
                                          .difference(widget.budget.beginDate)
                                          .inDays)
                              .output
                              .withoutFractionDigits,
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        )
                      ],
                    )
                  ]),
            ),
            Container(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        'Expected spending',
                        style: TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.w400,
                            fontSize: 13),
                      ),
                      Text(
                        MoneyFormatter(
                                amount: widget.budget.spent /
                                    (today)
                                        .difference(widget.budget.beginDate)
                                        .inDays *
                                    (widget.budget.endDate)
                                        .difference(widget.budget.beginDate)
                                        .inDays)
                            .output
                            .withoutFractionDigits,
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      )
                    ],
                  )
                ],
              ),
            ),
            Divider(
              color: Color(0xff333333),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Turn on notification',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  Switch(
                      value: isNotifi,
                      onChanged: (val) {
                        setState(() {
                          isNotifi = !isNotifi;
                        });
                      })
                ],
              ),
            ),
            Divider(
              color: Color(0xff333333),
            ),
            Container(
              margin: EdgeInsets.only(top: 10, bottom: 20),
              alignment: Alignment.center,
              child: TextButton(
                  onPressed: () async {
                    await showCupertinoModalBottomSheet(
                        context: context,
                        builder: (context) => BudgetTransactionScreen(
                              wallet: widget.wallet,
                              budget: widget.budget,
                            ));
                    setState(() {});
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                    decoration: BoxDecoration(
                        color: Color(0xFF2FB49C),
                        borderRadius: BorderRadius.circular(15)),
                    child: Text(
                      'Transaction list',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  )),
            )
          ],
        ),
      ),
    );
  }
}
