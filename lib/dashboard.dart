import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:rxdart/rxdart.dart';
import 'package:servermanagerui/frame.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<charts.Series<GaugeSegment?, String>>? series;
  List<charts.Series<GaugeSegment?, String>>? series2;

  double cpu = 0;
  double mem = 0;

  BehaviorSubject<List<charts.Series<GaugeSegment?, String>>?> _seriesBehav =
      new BehaviorSubject<List<charts.Series<GaugeSegment?, String>>?>();

  StreamSubscription<Future<Null>>? _stream;
  Stream<List<charts.Series<GaugeSegment?, String>>?> get _seriesStream =>
      _seriesBehav.stream;
  BehaviorSubject<List<charts.Series<GaugeSegment?, String>>?> _seriesBehav2 =
      new BehaviorSubject<List<charts.Series<GaugeSegment?, String>>?>();
  Stream<List<charts.Series<GaugeSegment?, String>>?> get _seriesStream2 =>
      _seriesBehav2.stream;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _seriesBehav.close();
    if(_stream != null) _stream!.cancel();
  }

  @override
  Widget build(BuildContext context) {
    series = _createSampleData();
    series2 = _createSampleData();
    getInfo();
    _stream = Stream.periodic(Duration(seconds: 5), (period) async {

    }).listen((event)async {await getInfo();});
    return Frame(
      title: "Dashboard",
      body: Container(
        child: Padding(
        padding: EdgeInsets.all(30),
        child: Row(children: [
          Expanded(
            child: StreamBuilder<List<charts.Series<GaugeSegment?, String>>?>(
              stream: _seriesStream,
              initialData: series,
              builder: (context, snap) => Column(
                children: [
                  Expanded(
                    child: charts.PieChart<String>(
                      snap.data!,
                      defaultRenderer: charts.ArcRendererConfig(
                          arcWidth: 30,
                          startAngle: 4 / 5 * 3.14,
                          arcLength: 7 / 5 * 3.14),
                    ),
                  ),
                  Text("CPU " + this.cpu.round().toString() + "%"),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<charts.Series<GaugeSegment?, String>>?>(
              stream: _seriesStream2,
              initialData: series2,
              builder: (context, snap) => Column(
                children: [
                  Expanded(
                    child: charts.PieChart<String>(
                      snap.data!,
                      defaultRenderer: charts.ArcRendererConfig(
                          arcWidth: 30,
                          startAngle: 4 / 5 * 3.14,
                          arcLength: 7 / 5 * 3.14),
                    ),
                  ),
                  Text("Memory " + this.mem.round().toString() + "%"),
                ],
              ),
            ),
          ),
        ]),
      ),
      ),
    );
  }

  Future<void> getInfo() async {
    try {
      var resp = await ParseCloudFunction("GetMainServerStats").execute();
      if (resp.success) {
        cpu = resp.result["cpu"];
        mem = resp.result["mem"];
        _seriesBehav.add(_createSampleData());
        _seriesBehav2.add(_createSampleData2());
      }
    } catch (e) {}
  }

  List<charts.Series<GaugeSegment?, String>> _createSampleData() {
    final data = [
      new GaugeSegment('CPU', this.cpu),
      new GaugeSegment('Not Used', 100 - this.cpu),
    ];

    return [
      new charts.Series<GaugeSegment, String>(
        id: 'Segments',
        domainFn: (GaugeSegment segment, _) => segment.segment,
        measureFn: (GaugeSegment segment, _) => segment.size,
        colorFn: (GaugeSegment segment, _) => charts.ColorUtil.fromDartColor(
            segment.segment == "CPU" ? Colors.blue : Colors.grey.shade300),
        data: data,
      )
    ];
  }

  List<charts.Series<GaugeSegment?, String>> _createSampleData2() {
    final data = [
      new GaugeSegment('Memory', this.mem),
      new GaugeSegment('Not Used', 100 - this.mem),
    ];

    return [
      new charts.Series<GaugeSegment, String>(
        id: 'Segments',
        domainFn: (GaugeSegment segment, _) => segment.segment,
        measureFn: (GaugeSegment segment, _) => segment.size,
        colorFn: (GaugeSegment segment, _) => charts.ColorUtil.fromDartColor(
            segment.segment == "Memory" ? Colors.blue : Colors.grey.shade300),
        data: data,
      )
    ];
  }
}

class GaugeSegment {
  final String segment;
  final double size;

  GaugeSegment(this.segment, this.size);
}
