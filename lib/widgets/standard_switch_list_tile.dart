import 'package:flutter/material.dart';
import 'package:whats_for_dino_2/theme/theme.dart';

class StandardSwitchListTile extends StatelessWidget {
  final String title;
  final bool value;
  final void Function(bool) onChanged;
  final Color activeColour;

  const StandardSwitchListTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.activeColour,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        value: value,
        activeColor: defaultPrimary,
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        inactiveTrackColor: Colors.grey[700],
        thumbColor: WidgetStateProperty.all(Colors.white),
        inactiveThumbColor: Colors.white,
        onChanged: onChanged,
      ),
    );
  }
}
