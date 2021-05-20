import 'package:flutter/material.dart';
import 'package:money_man/core/models/transactionModel.dart';
import 'package:money_man/core/models/walletModel.dart';
import 'package:money_man/core/services/firebase_firestore_services.dart';
import 'package:money_man/ui/screens/shared_screens/loading_screen.dart';
import 'package:money_man/ui/screens/transaction_screens/transaction_detail.dart';
import 'package:provider/provider.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:intl/intl.dart';

class SearchTransactionScreen extends StatefulWidget {
  final Wallet wallet;

  const SearchTransactionScreen({Key key, @required this.wallet})
      : super(key: key);
  @override
  _SearchTransactionScreenState createState() =>
      _SearchTransactionScreenState();
}

class _SearchTransactionScreenState extends State<SearchTransactionScreen> {
  // pattern mà user search
  String searchPattern;
  // biến control việc loading
  bool isLoading = false;
  // List danh sách transaction được fliter theo ngày order giảm dần theo thời gian
  List<List<MyTransaction>> transactionListSortByDate = [];
  // tổng đầu vào của các transaction trả về
  double totalInCome = 0;
  // tổng đầu ra của các transaction trả về
  double totalOutCome = 0;
  // hiệu của đầu vào vs đầu ra
  double total = 0;

  @override
  Widget build(BuildContext context) {
    final _firestore = Provider.of<FirebaseFireStoreService>(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          onChanged: (value) => searchPattern = value,
          onEditingComplete: () async {
            // làm bàn phím down
            FocusScope.of(context).unfocus();
            // control cho loading screen xuất hiện
            setState(() {
              isLoading = true;
            });

            // Lấy danh sách transaction dựa trên searchPattern
            List<MyTransaction> _transactionList = await _firestore
                .queryTransationByCategory(searchPattern, widget.wallet);

            // danh sách các date mà _transactionList có
            List<DateTime> listDateOfTrans = [];

            // thực hiện sort theo thứ tự thời gian giảm dần
            _transactionList.sort((a, b) => b.date.compareTo(a.date));
            // Lấy các ngày có trong _transactionList ra cho vào listDateOfTrans
            // tính toán tổng đầu vào, đàu ra, hiệu
            _transactionList.forEach((element) {
              if (!listDateOfTrans.contains(element.date))
                listDateOfTrans.add(element.date);
              if (element.category.type == 'expense')
                totalOutCome += element.amount;
              else
                totalInCome += element.amount;
            });
            total = totalInCome - totalOutCome;

            // Tạo thành list trans filter theo thời gian
            transactionListSortByDate.clear();
            listDateOfTrans.forEach((date) {
              final b = _transactionList
                  .where((element) => element.date.compareTo(date) == 0);
              transactionListSortByDate.add(b.toList());
            });

            // control loading screen mất => hiện kết quả truy ván ra
            setState(() {
              isLoading = false;
            });
          },
          decoration:
              InputDecoration(hintText: 'Search by #tag, category, etc'),
        ),
        actions: [Icon(Icons.settings_applications)],
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.black,
            child: transactionListSortByDate.length == 0
                ? Text(
                    'deo co gi ca',
                    style: TextStyle(color: Colors.white),
                  )
                : ListView.builder(
                    physics: BouncingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: transactionListSortByDate.length,
                    itemBuilder: (context, xIndex) {
                      double totalAmountInDay = 0;
                      transactionListSortByDate[xIndex].forEach((element) {
                        if (element.category.type == 'expense')
                          totalAmountInDay -= element.amount;
                        else
                          totalAmountInDay += element.amount;
                      });

                      return xIndex == 0
                          ? Column(
                              children: [
                                buildHeader(totalInCome, totalOutCome, total),
                                buildBottom(transactionListSortByDate, xIndex,
                                    totalAmountInDay)
                              ],
                            )
                          : buildBottom(transactionListSortByDate, xIndex,
                              totalAmountInDay);
                    }),
          ),
          isLoading == true ? LoadingScreen() : Container()
        ],
      ),
    );
  }

  Container buildBottom(
      List<List<MyTransaction>> x, int xIndex, double totalAmountInDay) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
      decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border(
              bottom: BorderSide(
                color: Colors.black,
                width: 1.0,
              ),
              top: BorderSide(
                color: Colors.black,
                width: 1.0,
              ))),
      child: StickyHeader(
        header: Container(
          color: Colors.grey[900],
          padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 5.0),
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                child: Text(DateFormat("dd").format(x[xIndex][0].date),
                    style: TextStyle(fontSize: 30.0, color: Colors.white)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                child: Text(
                    DateFormat("EEEE").format(x[xIndex][0].date).toString() +
                        '\n' +
                        DateFormat("MMMM yyyy")
                            .format(x[xIndex][0].date)
                            .toString(),
                    // 'hello',
                    style: TextStyle(fontSize: 12.0, color: Colors.grey[500])),
              ),
              Expanded(
                child: Text(totalAmountInDay.toString(),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
        content: ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: x[xIndex].length,
            itemBuilder: (context, yIndex) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TransactionDetail(
                              transaction: x[xIndex][yIndex],
                              wallet: widget.wallet)));
                },
                child: Container(
                  padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                        child: Icon(Icons.school,
                            size: 30.0, color: Colors.grey[600]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                        child: Text(x[xIndex][yIndex].category.name,
                            style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                      Expanded(
                        child: Text(x[xIndex][yIndex].amount.toString(),
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    x[xIndex][yIndex].category.type == 'income'
                                        ? Colors.green
                                        : Colors.red[600])),
                      ),
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }

  StickyHeader buildHeader(
      double totalInCome, double totalOutCome, double total) {
    return StickyHeader(
      header: SizedBox(height: 0),
      content: Container(
          decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                  bottom: BorderSide(
                color: Colors.black,
                width: 1.0,
              ))),
          padding: EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0),
          child: Column(children: <Widget>[
            Container(
              margin: EdgeInsets.fromLTRB(2, 2, 2, 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Opening balance',
                      style: TextStyle(color: Colors.grey[500])),
                  Text('+$totalInCome đ',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(2, 2, 2, 2),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('Ending balance',
                        style: TextStyle(color: Colors.grey[500])),
                    Text('-$totalOutCome đ',
                        style: TextStyle(color: Colors.white)),
                  ]),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(2, 2, 2, 2),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    SizedBox(
                      width: 10,
                      height: 10,
                    ),
                    Divider(
                      color: Colors.black,
                      thickness: 1.0,
                      height: 10,
                    ),
                    ColoredBox(color: Colors.black87)
                  ]),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(2, 2, 2, 2),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    SizedBox(
                      width: 10,
                    ),
                    Text('$total đ', style: TextStyle(color: Colors.white)),
                  ]),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View report for this period',
                style: TextStyle(color: Colors.yellow[700]),
              ),
              style: TextButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            )
          ])),
    );
  }
}