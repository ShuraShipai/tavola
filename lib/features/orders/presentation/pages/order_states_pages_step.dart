part of 'order_states_pages.dart';

class _Step extends StatelessWidget {
  const _Step(this.icon, this.label, this.time, this.active);
  final String icon, label, time;
  final bool active;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      CircleAvatar(
        radius: 18,
        backgroundColor: (active ? TavolaColors.primary : TavolaColors.border)
            .withValues(alpha: .18),
        child: Text(icon),
      ),
      const SizedBox(height: TavolaSpace.xs),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      Text(
        time,
        style: const TextStyle(fontSize: 11, color: TavolaColors.textMuted),
      ),
    ],
  );
}
