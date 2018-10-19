import 'dart:math';

import 'package:intl/intl.dart';

import '../globals.dart' as globals;
import 'base-print.dart';

class PrintDailyStatistics extends BasePrint
{
  @override
  String id = "daystats";

  @override
  String name = Intl.message("Tagesstatistik");

  @override
  String title = Intl.message("Tagesstatistik");

  @override
  bool get isPortrait
  => false;

  PrintDailyStatistics()
  {
    init();
  }

  @override
  prepareData_(vars)
  {
    return vars;
  }

  msgLow(value)
  {
    value = "\n<$value";
    return Intl.message("Tief${value}", args: [value], name: "msgLow");
  }

  msgHigh(value)
  {
    value = "\n>=$value";
    return Intl.message("Hoch${value}", args: [value], name: "msgHigh");
  }

  get msgDate
  => Intl.message("Datum");
  get msgDistribution
  => Intl.message("Verteilung");
  get msgNormal
  => Intl.message("Normal");
  get msgValues
  => Intl.message("Messwerte");
  get msgMin
  => Intl.message("Min");
  get msgMax
  => Intl.message("Max");
  get msgAverage
  => Intl.message("Mittelwert");
  get msgDeviation
  => Intl.message("Std.\nAbw.");
  get msg25
  => Intl.message("25%");
  get msg75
  => Intl.message("75%");

  headLine(globals.SettingsData settings)
  {
    var ret = [];
    ret.add({"text": msgDate, "style": "total", "alignment": "center"});
    ret.add({"text": msgDistribution, "style": "total", "alignment": "center"});
    ret.add({"text": msgLow(settings.thresholds.bgTargetBottom), "style": "total", "alignment": "center", "fillColor": colLow});
    ret.add({"text": msgNormal, "style": "total", "alignment": "center", "fillColor": colNorm});
    ret.add({"text": msgHigh(settings.thresholds.bgTargetTop), "style": "total", "alignment": "center", "fillColor": colHigh});
    ret.add({"text": msgValues, "style": "total", "alignment": "center"});
    ret.add({"text": msgMin, "style": "total", "alignment": "center"});
    ret.add({"text": msgMax, "style": "total", "alignment": "center"});
    ret.add({"text": msgAverage, "style": "total", "alignment": "center"});
    ret.add({"text": msgDeviation, "style": "total", "alignment": "center"});
    ret.add({"text": msg25, "style": "total", "alignment": "center"});
    ret.add({"text": msgMedian, "style": "total", "alignment": "center"});
    ret.add({"text": msg75, "style": "total", "alignment": "center"});

    return ret;
  }

  @override
  getFormData_(globals.ReportData src)
  {
    titleInfo = "${fmtDate(src.begDate)} - ${fmtDate(src.endDate)}";

    var body = [];
    var widths = ["auto", "*", cm(1.5), cm(1.5), cm(1.5), "auto", "auto", "auto", "auto", "auto", cm(1.5), cm(1.5), cm(1.5)];
    double f = 3.4 / 100;

    globals.ProfileGlucData prevProfile = null;
    int lineCount = 0;
    var ret = [header];
    int totalCount = 0;
    double totalMin = 100000;
    double totalMax = 0;
    int totalLow = 0;
    int totalHigh = 0;
    int totalNorm = 0;
    for (globals.DayData day in src.ns.days)
    {
      day.init();
      globals.ProfileGlucData profile = src.profile(src, DateTime(day.date.year, day.date.month, day.date.day));
      if (prevProfile == null || profile.targetLow != prevProfile.targetLow || profile.targetHigh != prevProfile.targetHigh)
      {
        body.add(headLine(src.status.settings));
        lineCount += 2;
      }
      prevProfile = profile;

      var row = [];
      row.add({"text": fmtDate(day.date)});
      row.add({
        "canvas": [
          {"type": "rect", "color": colLow, "x": cm(0), "y": cm(0), "w": cm(day.lowPrz * f), "h": cm(0.5)},
          {"type": "rect", "color": colNorm, "x": cm(day.lowPrz * f), "y": cm(0), "w": cm(day.normPrz * f), "h": cm(0.5)},
          {"type": "rect", "color": colHigh, "x": cm((day.lowPrz + day.normPrz) * f), "y": cm(0), "w": cm(day.highPrz * f), "h": cm(0.5)}
        ]
      });
      row.add({"text": "${fmtNumber(day.lowPrz, 0)} %", "alignment": "right"});
      row.add({"text": "${fmtNumber(day.normPrz, 0)} %", "alignment": "right"});
      row.add({"text": "${fmtNumber(day.highPrz, 0)} %", "alignment": "right"});
      row.add({"text": "${fmtNumber(day.entryCount, 0)}", "alignment": "right"});
      row.add({"text": "${fmtNumber(day.min, 0)}", "alignment": "right"});
      row.add({"text": "${fmtNumber(day.max, 0)}", "alignment": "right"});
      row.add({"text": "${fmtNumber(day.mid, 1)}", "alignment": "right"});
      row.add({"text": "${fmtNumber(day.stdAbw, 1)}", "alignment": "right"});
      row.add({"text": "${fmtNumber(globals.Globals.percentile(day.entries, 25), 1)}", "alignment": "right"});
      row.add({"text": "${fmtNumber(globals.Globals.percentile(day.entries, 50), 1)}", "alignment": "right"});
      row.add({"text": "${fmtNumber(globals.Globals.percentile(day.entries, 75), 1)}", "alignment": "right"});
      body.add(row);
      totalCount += day.entryCount;
      totalMin = min(day.min, totalMin);
      totalMax = max(day.max, totalMax);
      totalLow += day.lowCount;
      totalHigh += day.highCount;
      totalNorm += day.normCount;
      lineCount ++;
      if (lineCount == 21 && day != src.ns.days.last)
      {
        ret.add({"margin": [cm(2.2), cm(2.5), cm(2.2), cm(0.0)], "table": {"widths": widths, "body": body}});
        lineCount = 0;
        if (day != src.ns.days.last)
        {
          ret.add(footer(addPageBreak: true));
          ret.add(header);
        }
        else
        {
          ret.add(footer());
        }
        body = [];
        prevProfile = null;
      }
    }

    double lowPrz = totalCount == 0 ? 0 : totalLow / totalCount * 100;
    double normPrz = totalCount == 0 ? 0 : totalNorm / totalCount * 100;
    double highPrz = totalCount == 0 ? 0 : totalHigh / totalCount * 100;
    var row = [];
    row.add({"text": "${src.ns.days.length} Tage", "style": "total", "alignment": "center"});
    row.add({
      "canvas": [
        {"type": "rect", "color": colLow, "x": cm(0), "y": cm(0), "w": cm(lowPrz * f), "h": cm(0.5)},
        {"type": "rect", "color": colNorm, "x": cm(lowPrz * f), "y": cm(0), "w": cm(normPrz * f), "h": cm(0.5)},
        {"type": "rect", "color": colHigh, "x": cm((lowPrz + normPrz) * f), "y": cm(0), "w": cm(highPrz * f), "h": cm(0.5)}
      ],
      "style": "total"
    });
    row.add({"text": "${fmtNumber(lowPrz, 0)} %", "alignment": "right", "style": "total", "fillColor": colLow});
    row.add({"text": "${fmtNumber(normPrz, 0)} %", "alignment": "right", "style": "total", "fillColor": colNorm});
    row.add({"text": "${fmtNumber(highPrz, 0)} %", "alignment": "right", "style": "total", "fillColor": colHigh});
    row.add({"text": "${fmtNumber(totalCount, 0)}", "alignment": "right", "style": "total"});
    row.add({"text": "${fmtNumber(totalMin, 0)}", "alignment": "right", "style": "total"});
    row.add({"text": "${fmtNumber(totalMax, 0)}", "alignment": "right", "style": "total"});
    row.add({"text": "", "alignment": "right", "style": "total"});
    row.add({"text": "", "alignment": "right", "style": "total"});
    row.add({"text": "", "alignment": "right", "style": "total"});
    row.add({"text": "", "alignment": "right", "style": "total"});
    row.add({"text": "", "alignment": "right", "style": "total"});
    body.add(row);

    if (prevProfile != null)
    {
      ret.add({"margin": [cm(2.2), cm(2.5), cm(2.2), cm(0.0)], "table": {"widths": widths, "body": body}});
      ret.add(footer());
    }

    return ret;
  }
}