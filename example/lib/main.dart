// https://api.flutter.dev/flutter/material/DatePickerThemeData/DatePickerThemeData.html

import 'dart:convert';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:dio/dio.dart';
import 'package:example/dictionary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lunar_calendar/lunar_calendar.dart';

void main() =>runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        datePickerTheme: const DatePickerThemeData(
          backgroundColor: Color.fromARGB(150, 155, 225, 225),
          elevation: 26.0,
          headerHeadlineStyle: TextStyle(
            color: Colors.blueGrey,
            fontSize: 18.0
          ),
          rangePickerHeaderHeadlineStyle: TextStyle(
            color: Colors.red,
            fontSize: 28.0
          ),
          headerHelpStyle: TextStyle(
            color: Colors.yellowAccent,
            fontSize: 18.0,
            fontWeight: FontWeight.bold
          )
        )
      ),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('en', ''),
        Locale('zh', ''),
        Locale('he', ''),
        Locale('es', ''),
        Locale('ru', ''),
        Locale('ko', ''),
        Locale('hi', ''),
      ],
      home: const HomePage()
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<DateTime?> _dates = [
    DateTime(2023, 06, 12),
    DateTime(2023, 06, 24),
  ];

  List<DateTime?> _singleDate = [DateTime(2023, 07, 12)];

  late CalendarDatePicker2WithActionButtonsConfig config;

  var todayFormat = DateFormat("yyyy-MM-dd");

  var holidays = <String, dynamic>{};
  Future<void> _getHolidays() async {
    var response = await Dio().get("http://172.30.4.45:8888/daka/points");

    holidays = jsonDecode(response.toString());
    print(holidays);
    print(holidays["2023-01-02"]);
  }

  @override
  void initState() {
    super.initState();

    initConfig();
    _getHolidays();
  }

  void initConfig() {
    const dayTextStyle =
        TextStyle(color: Colors.black, fontWeight: FontWeight.w700);
    final weekendTextStyle =
        TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600);
    final anniversaryTextStyle = TextStyle(
      color: Colors.red[400],
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
    );
    config = CalendarDatePicker2WithActionButtonsConfig(
      dayTextStyle: dayTextStyle,
      calendarType: CalendarDatePicker2Type.range,
      selectedDayHighlightColor: Colors.purple[800],
      closeDialogOnCancelTapped: true,
      firstDayOfWeek: 1,
      dayBorderRadius: BorderRadius.all(Radius.zero),
      weekdayLabelTextStyle: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.bold,
      ),
      controlsTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
      centerAlignModePicker: true,
      customModePickerIcon: const SizedBox(),
      selectedDayTextStyle: dayTextStyle.copyWith(color: Colors.white),
      dayTextStylePredicate: ({required date}) {
        TextStyle? textStyle;
        if (date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday) {
          textStyle = weekendTextStyle;
        }
        // if (DateUtils.isSameDay(date, DateTime(2021, 1, 25))) {
        //   textStyle = anniversaryTextStyle;
        // }
        return textStyle;
      },
      dayBuilder: ({
        required date,
        textStyle,
        decoration,
        isSelected,
        isDisabled,
        isToday,
      }) {
        Widget dayWidget;
        Widget lunarWidget;
        String today = todayFormat.format(date);
        var holiday = holidays[today];
        bool? isOffDay = holiday?["isOffDay"];
        dayWidget = RichText(
          textAlign : TextAlign.start,
          text: TextSpan(
            children: [
              TextSpan(
                text: MaterialLocalizations.of(context).formatDecimal(date.day),
                style: textStyle,
              ),
              // if (holiday != null) TextSpan(
              //   text: isOffDay! ? "休" : "班",
              //   style: TextStyle(
              //     fontSize: 8,
              //     textBaseline: TextBaseline.alphabetic,
              //     color: isSelected == true
              //         ? Colors.white
              //         : isOffDay ? Colors.blue : Colors.red,
              //   ),
              // ),
              if (holiday != null) WidgetSpan(
                alignment: PlaceholderAlignment.top,
                child: Text(
                  isOffDay! ? "休" : "班",
                  style: TextStyle(
                    fontSize: 8,
                    color: isSelected == true
                        ? Colors.white
                        : isOffDay ? Colors.blue : Colors.red,
                  ),
                ),
              )
            ]
          )
        );

        List<int> lunar = CalendarConverter.solarToLunar(
            date.year, date.month, date.day,
            Timezone.Chinese);

        // print(lunar);
        // print(lunar[0]);
        // print(Dictionary.day_ch[lunar[0]]!);
        // print('*************************************************');
        String lunarDay = Dictionary.day_ch[lunar[0]]!;
        String lunarMonth = Dictionary.month_ch[lunar[1]]! + "月";
        String lunarStr = "";
        if (Dictionary.festival["$lunarMonth$lunarDay"] != null) {
          lunarStr = Dictionary.festival["$lunarMonth$lunarDay"]!;
        }
        if (Dictionary.festival["${date.month}月${date.day}日"] != null) {
          lunarStr = Dictionary.festival["${date.month}月${date.day}日"]!;
        }
        if (lunarStr == "") {
          if (lunarDay == "初一") {
            lunarStr = lunarMonth;
          } else {
            lunarStr = lunarDay;
          }
        }
        lunarWidget = Text(
          // Dictionary.day_ch[lunar[0]]!,
          lunarStr,
          // "初五",
          style: TextStyle(fontSize: 10, color: Colors.grey, height: 1),
        );
        return Container(
          decoration: decoration,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                dayWidget,
                lunarWidget                
              ],
            ),
          ),
        );
      },
      yearBuilder: ({
        required year,
        decoration,
        isCurrentYear,
        isDisabled,
        isSelected,
        textStyle,
      }) {
        return Center(
          child: Container(
            decoration: decoration,
            height: 36,
            width: 72,
            child: Center(
              child: Semantics(
                selected: isSelected,
                button: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      year.toString(),
                      style: textStyle,
                    ),
                    if (isCurrentYear == true)
                      Container(
                        padding: const EdgeInsets.all(5),
                        margin: const EdgeInsets.only(left: 5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flutter demo2")),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.lightBlueAccent[80],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Text("calendar_date_picker", style: TextStyle(fontSize: 18)),
            ),
            ElevatedButton(
              onPressed: () {
                showDatePicker(
                  context: context,
                  initialDate: DateTime.now(), // 初始化选中日期
                  firstDate: DateTime(2020, 6),  // 开始日期
                  lastDate: DateTime(2023, 12),  // 结束日期
                  // initialEntryMode: DatePickerEntryMode.input,  // 日历弹框样式

                  textDirection: TextDirection.ltr,  // 文字方向

                  currentDate: DateTime(2020, 10, 20),  // 当前日期
                  helpText: "helpText", // 左上方提示
                  cancelText: "cancelText",  // 取消按钮文案
                  confirmText: "confirmText",  // 确认按钮文案

                  errorFormatText: "errorFormatText",  // 格式错误提示
                  errorInvalidText: "errorInvalidText",  // 输入不在 first 与 last 之间日期提示

                  fieldLabelText: "fieldLabelText",  // 输入框上方提示
                  fieldHintText: "fieldHintText",  // 输入框为空时内部提示

                  initialDatePickerMode: DatePickerMode.day, // 日期选择模式，默认为天数选择
                  useRootNavigator: true, // 是否为根导航器
                  // 设置不可选日期，这里将 2020-10-15，2020-10-16，2020-10-17 三天设置不可选
                  selectableDayPredicate: (dayTime){
                    if(dayTime == DateTime(2020, 10, 15) || dayTime == DateTime(2020, 10, 16) || dayTime == DateTime(2020, 10, 17)) {
                      return false;
                    }
                    return true;
                  }
                );
              },
              child: const Text("打开日期选择框")
            ),
            ElevatedButton(
              onPressed: () {
                showDatePicker(
                  context: context,
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData(
                        cardColor: Colors.yellow,
                        brightness: Brightness.dark,
                      ),
                      child: child!,
                    );
                  },
                  initialDate: DateTime.now(), // 初始化选中日期
                  firstDate: DateTime(2018, 6),  // 开始日期
                  lastDate: DateTime(2025, 6),  // 结束日期
                  currentDate: DateTime(2020, 10, 20),  // 当前日期
                  helpText: "helpText", // 左上方提示
                  cancelText: "cancelText",  // 取消按钮文案
                  confirmText: "confirmText",  // 确认按钮文案

                  initialDatePickerMode: DatePickerMode.year, // 日期选择模式，默认为天数选择
                );
              },
              child: const Text("打开年份选择框")
            ),
            ElevatedButton(
              onPressed: () {
                showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 10, minute: 30),
                  cancelText: "cancelText",
                  helpText: "helpText",
                  confirmText: "confirmText"
                );
              },
              child: const Text("打开时间选择框")
            ),
            ElevatedButton(
              onPressed: () {
                showDateRangePicker(
                  context: context,
                  initialDateRange: DateTimeRange(
                    start: DateTime.now(), end: DateTime.now()
                  ), // 初始化选中日期
                  firstDate: DateTime(2020, 6),  // 开始日期
                  lastDate: DateTime(2023, 12),  // 结束日期
                  textDirection: TextDirection.ltr,  // 文字方向
                  currentDate: DateTime(2020, 10, 20),  // 当前日期
                  helpText: "helpText", // 左上方提示
                  cancelText: "cancelText",  // 取消按钮文案
                  confirmText: "confirmText",  // 确认按钮文案
                  errorFormatText: "errorFormatText",  // 格式错误提示
                  errorInvalidText: "errorInvalidText",  // 输入不在 first 与 last 之间日期提示
                  useRootNavigator: true, // 是否为根导航器
                  initialEntryMode: DatePickerEntryMode.calendarOnly, // 日历弹框样式
                );
              },
              child: const Text("打开日期范围选择")
            ),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Text("calendar_date_picker2", style: TextStyle(fontSize: 18)),
            ),
            ElevatedButton(
              onPressed: () async {
                var results = await showCalendarDatePicker2Dialog(
                  context: context,
                  config: config,
                  value: _dates,
                  borderRadius: BorderRadius.circular(15),
                  dialogSize: const Size(325, 400),
                );
                print(results);
                if (results != null) {
                  _dates = results;
                }
              },
              child: const Text("打开日期范围选择框")
            ),
            ElevatedButton(
              onPressed: () async {
                var results = await showCalendarDatePicker2Dialog(
                  context: context,
                  config: CalendarDatePicker2WithActionButtonsConfig(
                      calendarType: CalendarDatePicker2Type.multi,
                  ),
                  value: _dates,
                  borderRadius: BorderRadius.circular(15),
                  dialogSize: const Size(325, 400),
                );
                print(results);
                if (results != null) {
                  _dates = results;
                }
              },
              child: const Text("打开日期多选？")
            ),
            ElevatedButton(
              onPressed: () async {
                var results = await showCalendarDatePicker2Dialog(
                  context: context,
                  config: CalendarDatePicker2WithActionButtonsConfig(
                      calendarType: CalendarDatePicker2Type.single,
                  ),
                  value: _singleDate,
                  borderRadius: BorderRadius.circular(15),
                  dialogSize: const Size(325, 400),
                );
                print(results);
                if (results != null) {
                  _singleDate = results;
                }
              },
              child: const Text("打开日期单选？")
            ),

            RichText(
              text: TextSpan(
                text: 'Hello ',
                style: DefaultTextStyle.of(context).style,
                children: <InlineSpan>[
                  WidgetSpan(
                    alignment: PlaceholderAlignment.top,
                    child: Text(
                      'World',
                      style: TextStyle(fontSize: 24),
                    ),
                  )
                ],
              ),
            )

          ]
        ),
      )
    );
  }
}
