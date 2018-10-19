import 'dart:async';
import 'dart:convert' as convert;
import 'dart:convert';
import 'dart:html' as html;

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/content/deferred_content.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_datepicker/material_date_range_picker.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:intl/intl.dart';
import 'package:nightscout_reporter/src/forms/base-print.dart';
import 'package:nightscout_reporter/src/forms/print-daily-graphic.dart';
import 'package:nightscout_reporter/src/forms/print-daily-statistics.dart';
import 'package:nightscout_reporter/src/forms/print-percentile.dart';
import 'package:nightscout_reporter/src/forms/print-test.dart';
import 'package:nightscout_reporter/src/globals.dart' as globals;

import 'src/dsgvo/dsgvo_component.dart';
import 'src/forms/print-analysis.dart';
import 'src/forms/print-basalrate.dart';
import 'src/impressum/impressum_component.dart';
import 'src/settings/settings_component.dart';
import 'src/welcome/welcome_component.dart';

// AngularDart info: https://webdev.dartlang.org/angular
// Components info: https://webdev.dartlang.org/components

@Component(selector: 'my-app',
  styleUrls: ['app_component.css', 'package:angular_components/app_layout/layout.scss.css'],
  templateUrl: 'app_component.html',
  directives: [
    MaterialDateRangePickerComponent,
    MaterialCheckboxComponent,
    MaterialExpansionPanel,
    MaterialFabComponent,
    MaterialIconComponent,
    MaterialPersistentDrawerDirective,
    MaterialButtonComponent,
    DeferredContentDirective,
    SettingsComponent,
    ImpressumComponent,
    DSGVOComponent,
    WelcomeComponent,
    MaterialProgressComponent,
    MaterialToggleComponent,
    MaterialDropdownSelectComponent,
    MaterialSelectItemComponent,
    NgClass,
    NgFor,
    NgIf,
  ],
  providers: const <dynamic>[overlayBindings, materialProviders,])
class AppComponent
  implements OnInit
{
  globals.Globals g = globals.Globals();
  bool drawerVisible = false;
  String _currPage;
  String _lastPage = "welcome";
  String get currPage
  => _currPage;
  set currPage(String value)
  {
    _lastPage = currPage;
    _currPage = value;
  }

  static String startPage = "normal";
  Date today = Date.today();
  Map<String, bool> appTheme = <String, bool>{};
  List<DatepickerPreset> dateRanges = List<DatepickerPreset>();
  DateRangePickerConfiguration drConfig = DateRangePickerConfiguration.basic;
  List<BasePrint> listForms = List<BasePrint>();
  bool sendDisabled = true;
  String pdfData = null;
  String progressText = null;
  int progressMax = 100;
  int progressValue = 0;
  String sendIcon = "send";
  String get createIcon
  => isDebug && sendIcon == "send" ? "bug_report" : sendIcon;
  String pdfUrl = "";
  bool isDebug = false;
  globals.Msg message = globals.Msg();
  bool get hasMenuIcon
  => currPage != "impressum" && currPage != "dsgvo" && currPage != "welcome";

  msgLoadingData(error, stacktrace)
  => Intl.message("Fehler beim Laden der Daten:\n$error\n$stacktrace", args: [error, stacktrace], name: "msgLoadingData");
  msgLoadingDataFor(date)
  => Intl.message("Lade Daten für $date...", args: [date], name: "msgLoadingDataFor", desc: "displayed when data of a day is loading");
  dynamic currLang = {};
  String get msgClose
  => Intl.message("Schliessen");
  String get msgEmptyRange
  => Intl.message("Bitte einen Zeitraum wählen.");
  String get msgPreparingData
  => Intl.message("Bereite Daten vor...", desc: "text when data was received and is being prepared to be used in the report");
  String get msgCreatingPDF
  => Intl.message("Erzeuge PDF...", desc: "text when pdf is being created");
  String get msgImpressum
  => Intl.message("Impressum");
  String get msgDSGVO
  => Intl.message("Datenschutzerklärung");
  String get msgNightscoutReport
  => Intl.message("Nightscout Berichte");
  String get msgApply
  => Intl.message("ok");
  String get msgCancel
  => Intl.message("verwerfen");
  String get msgPDFCreated
  => Intl.message("Das PDF wurde erstellt. Wenn es nicht angezeigt wird, dann ist vermutlich ein Popup-Blocker aktiv, der die Anzeige verhindert. Diesen bitte deaktivieren.");

  @override
  Future<Null> ngOnInit()
  async {
    /// fill list with forms
    listForms = List<BasePrint>();
    listForms.add(PrintAnalysis());
    listForms.add(PrintDailyStatistics());
    listForms.add(PrintDailyGraphic());
    listForms.add(PrintBasalrate());
    listForms.add(PrintPercentile());
    listForms.add(PrintTest());

//    await findSystemLocale();
//    await initializeDateFormatting();
    String title = Intl.message("Zeitraum");
    if (g != null && g.dateRange != null && g.dateRange.comparison != null)title = g.dateRange.comparison.title;
    dateRanges.clear();
    dateRanges.add(DatepickerPreset(Intl.message("Heute"), DatepickerDateRange(title, Date.today(), Date.today())));
    dateRanges.add(DatepickerPreset(Intl.message("Letzte 2 Tage"), DatepickerDateRange(title, Date.today().add(days: -1), Date.today())));
    dateRanges.add(DatepickerPreset(Intl.message("Letzte 3 Tage"), DatepickerDateRange(title, Date.today().add(days: -2), Date.today())));
    dateRanges.add(DatepickerPreset(Intl.message("Letzte Woche"), DatepickerDateRange(title, Date.today().add(days: -7), Date.today())));
    dateRanges.add(DatepickerPreset(Intl.message("Letzte 2 Wochen"), DatepickerDateRange(title, Date.today().add(days: -14), Date.today())));
    dateRanges.add(DatepickerPreset(Intl.message("Letzte 3 Wochen"), DatepickerDateRange(title, Date.today().add(days: -21), Date.today())));
    dateRanges.add(DatepickerPreset(Intl.message("Letzter Monat"), DatepickerDateRange(title, Date.today().add(months: -1), Date.today())));
    dateRanges.add(DatepickerPreset(Intl.message("Letzte 3 Monate"), DatepickerDateRange(title, Date.today().add(months: -3), Date.today())));
    currLang = g.language;

    display(null);
    g.checkSetup().then((String error)
    {
      g.isConfigured = error == null;
      _currPage = g.isConfigured ? "normal" : _lastPage;
    });
  }

  void toggleHelp()
  {
  }

  void togglePage(String id)
  {
    currPage = currPage == id ? "normal" : id;
  }

  void displayLink(String title, String url, {bool clear: false, String type: null, String btnClass: ""})
  {
    if (!isDebug)return;

    if (clear)message.links = [];

    message.links.add({"url": url, "title": title, "class": btnClass});
    message.okText = msgClose;
    message.ok = message.clear;
    if (type != null)message.type = type;
  }

  void display(String msg, {bool append: false, ok() = null, cancel() = null})
  {
    if (append)msg = "${message.isEmpty ? '' : '${message.text}<br />'}$msg";
    message.links = [];
    message.text = msg;
    message.ok = ok;
    message.cancel = cancel;
    message.type = "msg";
  }

  void callNightscout()
  {
    String url = g.apiUrl;
    int pos = url.indexOf("/api");
    if (pos >= 0)url = url.substring(0, pos);
    navigate(url);
  }

  void callNightscoutReports()
  {
    navigate("${g.reportUrl}/report");
  }

  void navigate(String url)
  {
    if (url == "showPlayground" || url == "showPdf")
    {
      pdfUrl = url == "showPlayground" ? "http://pdf.zreptil.de/playground.php" : "https://nightscout-reporter.zreptil.de/pdfmake/pdfmake.php";
      Future.delayed(Duration(milliseconds: 1), ()
      {
        var form = html.querySelector("#postForm") as html.FormElement;
        form.submit();
//        display(msgPDFCreated);
      });
    }
    else
    {
      html.window.open(url, "_blank");
    }
  }

  void settingsResult(html.UIEvent evt)
  {
    switch (evt.type)
    {
      case "ok":
        g.save();
        checkSetup();
        break;
      default:
        g.load();
        _currPage = _lastPage;
        break;
    }
  }

  void checkSetup()
  {
    display(null);
    g.checkSetup().then((String error)
    {
      g.isConfigured = error == null;
      _currPage = g.isConfigured ? "normal" : _lastPage;

      if (error != null)display(error);
    });
  }

  void checkPrint()
  {
    sendDisabled = true;
    for (BasePrint form in listForms)
      if (form.checked)sendDisabled = false;
  }

  globals.ReportData reportData = null;
  Future<globals.ReportData> loadData()
  async {
    if (reportData != null && reportData.begDate == g.dateRange.range.start && reportData.endDate == g.dateRange.range.end)return reportData;

    globals.ReportData data = globals.ReportData(g, g.dateRange.range.start, g.dateRange.range.end);
    reportData = data;
    DateTime bd = DateTime(data.begDate.year, data.begDate.month, data.begDate.day);
    DateTime ed = DateTime(data.endDate.year, data.endDate.month, data.endDate.day);

    progressMax = ed
      .difference(bd)
      .inDays;
    progressValue = 0;

    Date begDate = data.begDate;
    Date endDate = data.endDate;

    message.links = [];
    message.type = "msg toggle-debug";

    while (begDate <= endDate)
    {
      DateTime beg = DateTime(begDate.year, begDate.month, begDate.day, 0, 0, 0).toUtc();
      DateTime end = DateTime(begDate.year, begDate.month, begDate.day, 23, 59, 59).toUtc();

      progressText = msgLoadingDataFor(begDate.format(g.fmtDateForDisplay));
      String url = "${g.apiUrl}entries.json?find[dateString][\$gte]=${beg.toIso8601String()}&find[dateString][\$lte]=${end.toIso8601String()}&count=100000";
      displayLink("e${begDate.format(g.fmtDateForDisplay)}", url);
      List<dynamic> src = json.decode(await html.HttpRequest.getString(url));
      for (dynamic entry in src)
      {
        globals.EntryData e = globals.EntryData.fromJson(entry);
        if (e.gluc > 0)
        {
          data.ns.entries.add(e);
        }
      }
      url = "${g.apiUrl}treatments.json?find[created_at][\$gte]=${beg.toIso8601String()}&find[created_at][\$lte]=${end.toIso8601String()}&count=100000";
      displayLink("t${begDate.format(g.fmtDateForDisplay)}", url);
      src = json.decode(await html.HttpRequest.getString(url));
      for (dynamic treatment in src)
        data.ns.treatments.add(globals.TreatmentData.fromJson(treatment));

      begDate = begDate.add(days: 1);
      data.dayCount++;
      progressValue++;
      if (sendIcon != "clear")return data;
    }

    if (sendIcon == "clear")
    {
      progressText = msgPreparingData;
      progressValue = progressMax + 1;

      data.ns.entries.sort((a, b)
      => a.time.compareTo(b.time));
      data.ns.treatments.sort((a, b)
      => a.createdAt.compareTo(b.createdAt));

      int diffTime = 5;
//*
      // Create an array with values every [diffTime] minutes
      List<globals.EntryData> entryList = List<globals.EntryData>();
      DateTime target = DateTime(data.ns.entries.first.time.year, data.ns.entries.first.time.month, data.ns.entries.first.time.day);
      globals.EntryData prev = data.ns.entries.first;
      globals.EntryData next = globals.EntryData();
      next.time = target;
      // distribute entries
      for (globals.EntryData entry in data.ns.entries)
      {
        DateTime current = DateTime(entry.time.year, entry.time.month, entry.time.day, entry.time.hour, entry.time.minute);
        if (current.isAtSameMomentAs(target))
        {
          prev = entry;
          prev.time = current;
          entry.type = "copied";
          entryList.add(entry);
          target = target.add(Duration(minutes: diffTime));
        }
        else if (current.isBefore(target))
        {
          next.slice(entry, next, 0.5);
        }
        else
        {
          next = entry.copy;
          int max = current
            .difference(prev.time)
            .inMinutes;
          while (current.isAfter(target) || current.isAtSameMomentAs(target))
          {
            double factor = max == 0 ? 0 : target
              .difference(prev.time)
              .inMinutes / max;
            next = next.copy;
            next.time = target;
            if (current.isAtSameMomentAs(target))
            {
              next.type = "copied";
              next.slice(entry, entry, 1.0);
            }
            else
            {
              next.slice(prev, entry, factor);
            }
            entryList.add(next);
            target = target.add(Duration(minutes: diffTime));
          }
          prev = entry;
          prev.time = current;
          next = entry;
        }
      }
      data.calc.entries = entryList;

      String url = "${g.apiUrl}status.json";
      displayLink("status", url);
      String content = await html.HttpRequest.getString(url);
      data.status = globals.StatusData.fromJson(json.decode(content));
      g.glucMGDL = data.status.settings.units == "mg/dl";
      url = "${g.apiUrl}profile.json";
      displayLink("profile", url);
      content = await html.HttpRequest.getString(url);
      if (g.dateRange.range.start == null || g.dateRange.range.end == null)
      {
        data.error = StateError(msgEmptyRange);
        return data;
      }
      try
      {
        List<dynamic> src = json.decode(content);
        for (dynamic entry in src)
          data.profiles.add(globals.ProfileData.fromJson(entry));
//        display("${ret.begDate.toString()} - ${ret.endDate.toString()}");
      }
      catch (ex)
      {
        if (ex is Error)display("${ex.toString()}\n${ex.stackTrace}");
        else
          display(ex.toString());
      }

      data.profiles.sort((a, b)
      => a.startDate.compareTo(b.startDate));

      // Create an array with values every 5 minutes
//      List<globals.TreatmentData> treatList = List<globals.TreatmentData>();
//      target = DateTime(data.ns.treatments.first.createdAt.year, data.ns.treatments.first.createdAt.month, data.ns.treatments.first.createdAt.day);
//      globals.TreatmentData prevTreat = data.ns.treatments.first;
//      globals.TreatmentData nextTreat = globals.TreatmentData();
//      nextTreat.createdAt = target;
//      // distribute treatments
//      for (globals.TreatmentData treat in data.ns.treatments)
//      {
//        DateTime current = DateTime(treat.createdAt.year, treat.createdAt.month, treat.createdAt.day, treat.createdAt.hour, treat.createdAt.minute);
//        if (current.isAtSameMomentAs(target))
//        {
//          prevTreat = treat;
//          prevTreat.createdAt = current;
//          treat.eventType = "copied";
//          treatList.add(treat);
//          target = target.add(Duration(minutes: diffTime));
//        }
//        else if (current.isBefore(target))
//        {
//          nextTreat.slice(treat, nextTreat, 0.5);
//        }
//        else
//        {
//          nextTreat = treat.copy;
//          int max = current
//            .difference(prevTreat.createdAt)
//            .inMinutes;
//          while (current.isAfter(target) || current.isAtSameMomentAs(target))
//          {
//            double factor = max == 0 ? 0 : target
//              .difference(prevTreat.createdAt)
//              .inMinutes / max;
//            nextTreat = nextTreat.copy;
//            nextTreat.createdAt = target;
//            if (current.isAtSameMomentAs(target))
//            {
//              nextTreat.eventType = "copied";
//              nextTreat.slice(treat, treat, 1.0);
//            }
//            else
//            {
//              nextTreat.slice(prevTreat, treat, factor);
//            }
//            treatList.add(nextTreat);
//            target = target.add(Duration(minutes: diffTime));
//          }
//          prevTreat = treat;
//          prevTreat.createdAt = current;
//          nextTreat = treat;
//        }
//      }
//      data.calc.treatments = treatList;
      data.calc.treatments = data.ns.treatments;
      data.calc.extractData(data);
      data.ns.extractData(data);
// */
//      done(data);
    }
    else
    {
    }
    return data;
  }

  void sendClick()
  {
    if (sendIcon == "send")
    {
      sendIcon = "clear";
      createPDF();
    }
    else
    {
      sendIcon = "send";
    }
  }

  void createPDF()
  {
    g.save();
    display("");
    loadData().then((globals.ReportData vars)
    async {
      if (vars.error != null)
      {
        display(msgLoadingData(vars.error.toString(), vars.error.stackTrace.toString()));
        return;
      }
      progressText = msgCreatingPDF;
      progressValue = progressMax + 1;
      var doc = null;
      for (BasePrint form in listForms)
      {
        if (form.checked && (!form.isDebugOnly || isDebug))
        {
          var data = await form.getFormData(vars);
          if (doc == null)
          {
            doc = {
              "pageSize": "a4",
              "pageOrientation": form.isPortrait ? "portrait" : "landscape",
              "pageMargins": [form.cm(0), form.cm(1.0), form.cm(0), form.cm(0.0)],
              "content": data,
              "images": form.images,
              "styles": {
                "infoline": {"margin": [0, form.cm(0.25), 0, form.cm(0.25)]},
                "perstitle": {"fontSize": 10, "alignment": "right"},
                "persdata": {"fontSize": 10, "color": "#0000ff"},
                "infotitle": {"fontSize": 10, "alignment": "left"},
                "infodata": {"fontSize": 10, "alignment": "right", "color": "#0000ff"},
                "infounit": {"margin": [0, form.cm(0.07), 0, 0], "fontSize": 8, "color": "#0000ff"},
                "hba1c": {"color": "#5050ff"},
                "total": {"bold": true, "fillColor": "#d0d0d0"}
              }
            };
          }
          else
          {
            var pagebreak = {"text": "", "pageBreak": "after", "pageSize": "a4", "pageOrientation": form.isPortrait ? "portrait" : "landscape",};
            doc["content"].add(pagebreak);
            for (var entry in data)
              doc["content"].add(entry);

            for (String key in form.images.keys)
            {
              (doc["images"] as Map<String, String>)[key] = form.images[key];
            }

/*
            if (data["images"] == null)data["images"] = [];
            Map<String, String> map = data["images"];
            for (var key in map.keys)
              (doc["images"] as Map<String, String>)[key] = map[key];
// */
          }
        }
      }

      doc = "${convert.jsonEncode(doc)}";
      pdfData = convert.base64.encode(convert.utf8.encode(doc));
//*
      if (!isDebug)
      {
        navigate("showPdf");
      }
      else
      {
        displayLink("playground", "showPlayground", btnClass: "action");
        displayLink("pdf", "showPdf", btnClass: "action");
      }
// */
      sendIcon = "send";
      progressText = null;
    }).catchError((error)
    {
      if (error is Error)display("${error.toString()}\n${error.stackTrace}");
      else
        display(error.toString());
      sendIcon = "send";
      progressText = null;
      return -1;
    });
  }
}
