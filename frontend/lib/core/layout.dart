import 'package:flutter/widgets.dart';

const kWideBreakpoint = 840.0;

bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= kWideBreakpoint;
