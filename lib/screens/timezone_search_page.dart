import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../helpers/icon_helper.dart';
import '../helpers/preferences_helper.dart';

class TimezoneSearchPage extends StatefulWidget {
  @override
  _TimezoneSearchPageState createState() => _TimezoneSearchPageState();
}

class _TimezoneSearchPageState extends State<TimezoneSearchPage> {
  final List<String> allTimezones = tz.timeZoneDatabase.locations.keys.toList();
  List<String> filtered = [];
  List<String> selected = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones();
    filtered = allTimezones;

    searchController.addListener(() {
      final query = searchController.text;
      setState(() {
        filtered = allTimezones
            .where((tz) => tz.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final nowUtc = DateTime.now().toUtc();
    final colorTheme = Theme.of(context).colorScheme;
    final is24HourFormat = PreferencesHelper.getString("timeFormat") == "24 hr";

    return Scaffold(
      backgroundColor: colorTheme.surfaceContainerHigh,
      appBar: AppBar(
        title: TextField(
          style: TextStyle(fontSize: 16, color: colorTheme.onSurface),
          controller: searchController,
          decoration: InputDecoration(
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            hintText: "Search...",
          ),
        ),
        titleSpacing: 0,
        toolbarHeight: 65,
        backgroundColor: colorTheme.surfaceContainerHigh,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: colorTheme.outline.withOpacity(0.8),
            width: 2,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final tzName = filtered[i];
                final location = tz.getLocation(tzName);
                final tzTime = tz.TZDateTime.from(nowUtc, location);
                final offset = tzTime.timeZoneOffset;

                final isLast = i == filtered.length - 1;

                String offsetSign = offset.isNegative ? '-' : '+';
                int hours = offset.inHours.abs();
                int minutes = offset.inMinutes.abs() % 60;
                final offsetStr = '$offsetSign${hours}h ${minutes}m';
                final tzTimeFormatted = is24HourFormat
                    ? DateFormat('HH:mm').format(tzTime)
                    : DateFormat('hh:mm a').format(tzTime);

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: isLast
                        ? MediaQuery.of(context).padding.bottom + 20
                        : 0,
                  ),
                  child: CheckboxListTile(
                    title: Text(tzName),
                    subtitle: Text('$tzTimeFormatted • Offset: $offsetStr'),
                    value: selected.contains(tzName),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          selected.add(tzName);
                        } else {
                          selected.remove(tzName);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: selected.isEmpty
            ? null
            : () {
                Navigator.pop(context, selected);
              },
        label: Text("Add", style: TextStyle(fontSize: 18)),
        heroTag: "idk_insane_random_tag",

        icon: IconWithWeight(Symbols.add),
      ),
    );
  }
}
