import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import "package:intl/intl.dart";
import 'package:intl/date_symbol_data_local.dart';

Future<List<Transactios>> fetchTransactios(http.Client client) async {
  final aaa =
      await client.get('https://aidosmarket.com/api/transactions?limit=100');
  // Use the compute function to run parseTransactios in a separate isolate
  return compute(parseTransactios, aaa.body);
}

Future<List<OrderBooks>> fetchOrderBook(http.Client client) async {
  final bbb = await client.get('https://aidosmarket.com/api/order-book');
  print(compute(parseOrderBook, bbb.body));
  return compute(parseOrderBook, bbb.body);
}

List<OrderBooks> parseOrderBook(String responseBody) {
  final Map<String, dynamic> data = json.decode(responseBody);
  String askJson = json.encode(data["order-book"]["ask"]);
  String bidJson = json.encode(data["order-book"]["bid"]);
  List ask = json.decode(askJson);
  List bid = json.decode(bidJson);
  ask.map<OrderBooks>((json) => OrderBooks.fromJson(json)).toList();
  return bid.map<OrderBooks>((json) => OrderBooks.fromJson(json)).toList();
}

class OrderBooks {
  final String date;
  final String orderAmount;
  final String price;

  OrderBooks({this.date, this.orderAmount, this.price});

  factory OrderBooks.fromJson(Map<String, dynamic> json) {
    var formatter = new DateFormat('yyyy/MM/dd(E) HH:mm', "ja_JP");
    var formatted = formatter.format(json['date']); // DateからString
    print(formatted);
    return OrderBooks(
      date: json['date'],
      orderAmount: json['order_amount'].toString(),
      price: json['price'].round().toString(),
    );
  }
}

// A function that will convert a response body into a List<Transactios>
List<Transactios> parseTransactios(String responseBody) {
  final Map<String, dynamic> data = json.decode(responseBody);
  String transactionsJson = json.encode(data["transactions"]["data"]);
  print(transactionsJson);
  List transactions = json.decode(transactionsJson);
  return transactions
      .map<Transactios>((json) => Transactios.fromJson(json))
      .toList();
}

class Transactios {
  final String date;
  final String id;
  final String price;
  final String amount;
  final String type;

  Transactios({this.date, this.id, this.price, this.amount, this.type});

  factory Transactios.fromJson(Map<String, dynamic> json) {
    initializeDateFormatting("ja_JP");
    DateTime datetime = DateTime.parse(json['date']); // StringからDate
    var _9hourssAfter = datetime.add(new Duration(hours: 9));
    var formatter = new DateFormat('yyyy/MM/dd HH:mm', "ja_JP");
    var formatted = formatter.format(_9hourssAfter); // DateからString

    return Transactios(
      date: formatted,
      id: json['id'].toString(),
      price: json['price'].toString(),
      amount: json['amount'].round().toString(),
      type: json['type'],
    );
  }
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    print(now);
    print(now.timeZoneName);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _count = 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Logo(),
      ),
      body: Padding(
        child: FutureBuilder<List<Transactios>>(
          future: fetchTransactios(http.Client()),
          builder: (context, snapshot) {
            if (snapshot.hasError) print(snapshot.error);
            return snapshot.hasData
                ? RefreshIndicator(
                    child:
                        TransactiosList(photos: snapshot.data, count: _count),
                    onRefresh: _refreshhandle,
                  )
                : Center(child: CircularProgressIndicator());
          },
        ),
        padding: EdgeInsets.fromLTRB(1.0, 1.0, 1.0, 1.0),
      ),
    );
  }

  Future<Null> _refreshhandle() async {
    setState(() {
      _count;
    });
    return null;
  }
}

class Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // centers horizontally
      crossAxisAlignment: CrossAxisAlignment.center, // centers vertically
      children: <Widget>[
        Image.asset("assets/adk.png", width: 30, height: 30),
        SizedBox(
          width: 3,
        ), // The size box provides an immediate spacing between the widgets
        Text(
          "ADK Watcher",
        )
      ],
    );
  }
}

class TransactiosList extends StatelessWidget {
  final List<Transactios> photos;
  final int count;

  TransactiosList({Key key, this.photos, this.count}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TransactiosList = ListView.separated(
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return Container(
          child: Row(
            children: <Widget>[
              Divider(color: Colors.black),
              Center(
                  child: Container(
                width: 30,
                margin: EdgeInsets.fromLTRB(5, 2, 10, 0),
                child: Text(
                  photos[index].type,
                  style: TextStyle(
                    color:
                        photos[index].type == 'Buy' ? Colors.green : Colors.red,
                  ),
                ),
              )),
              Center(
                  child: Container(
                      width: 150,
                      margin: EdgeInsets.fromLTRB(5, 2, 10, 0),
                      child: Text(photos[index].date))),
              Center(
                  child: Container(
                width: 90,
                margin: EdgeInsets.fromLTRB(0, 2, 5, 0),
                child: Text(photos[index].price),
              )),
              Center(
                  child: Container(
                margin: EdgeInsets.fromLTRB(0, 2, 10, 0),
                child: Text(photos[index].amount),
              )),
            ],
          ),
        );
      },
      separatorBuilder: (context, index) {
        return Divider();
      },
    );

    final topTitle = Container(
        color: Colors.black,
        child: Row(
          children: <Widget>[
            Divider(color: Colors.black),
            Container(
                child: Container(
                    width: 32,
                    margin: EdgeInsets.fromLTRB(5, 2, 10, 0),
                    child: Text(
                      'Type',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ))),
            Container(
                child: Container(
                    width: 150,
                    margin: EdgeInsets.fromLTRB(5, 2, 10, 0),
                    child: Text(
                      'Date',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ))),
            Container(
                child: Container(
              width: 90,
              margin: EdgeInsets.fromLTRB(0, 2, 5, 0),
              child: Text(
                'Price',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            )),
            Container(
                child: Container(
              margin: EdgeInsets.fromLTRB(0, 2, 10, 0),
              child: Text(
                'Amount',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            )),
          ],
        ));

    //main
    return Container(
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: 10.0),
            child: topTitle,
          ),
          Flexible(child: TransactiosList),
        ],
      ),
    );
  }
}
