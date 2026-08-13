import 'package:flutter/material.dart';
import 'package:project/core/app_theme.dart';
import 'package:project/providers/weight_provider_bluetooth.dart';
import 'package:provider/provider.dart';

class MeasurementFlowDialog extends StatelessWidget {
  const MeasurementFlowDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeightProvider>();
    final stage = provider.measurementStage;

    String title;
    String instructions;
    IconData icon;
    Color color;
    bool finished = false;

    switch (stage) {
      case 'move_feet':
        title = 'กำลังวัดน้ำหนัก';
        instructions =
            'เชื่อมต่อเครื่องชั่งแล้ว\nกรุณาขยับเท้าเล็กน้อย เพื่อให้เครื่องชั่งส่งค่าน้ำหนักครั้งใหม่';
        icon = Icons.directions_walk;
        color = AppTheme.warning;
        break;
      case 'hold_still':
        title = 'กำลังวัดส่วนสูงและชีพจร';
        instructions =
            'ได้น้ำหนัก ${provider.currentWeight.toStringAsFixed(1)} กก.\n\n'
            'กรุณายืนนิ่ง ๆ และวางนิ้วหรือมือบนเซนเซอร์วัดชีพจรค้างไว้ประมาณ 5 วินาที';
        icon = Icons.favorite;
        color = AppTheme.warning;
        break;
      case 'retry_vitals':
        title = 'ยังอ่านค่าได้ไม่ครบ';
        instructions =
            'กรุณายืนนิ่ง และวางนิ้วหรือมือบนเซนเซอร์ให้แนบสนิทอีก 5 วินาที';
        icon = Icons.refresh;
        color = Colors.orange;
        break;
      case 'complete':
        title = 'วัดเสร็จสิ้น';
        instructions =
            'น้ำหนัก ${provider.currentWeight.toStringAsFixed(1)} กก.\n'
            'ส่วนสูง ${provider.heightCm.toStringAsFixed(1)} ซม.\n'
            'อัตราการเต้นหัวใจ ${provider.currentHeartRate} BPM\n'
            'BMI ${provider.bmi.toStringAsFixed(1)}';
        icon = Icons.check_circle;
        color = AppTheme.success;
        finished = true;
        break;
      default:
        title = 'กำลังรอเครื่องชั่ง';
        instructions =
            'กรุณาขึ้นเหยียบเครื่องชั่ง\nระบบจะเริ่มทำงานเมื่อได้รับค่าน้ำหนักครั้งแรก';
        icon = Icons.monitor_weight_outlined;
        color = Colors.blue;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            instructions,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          if (!finished) ...[
            const SizedBox(height: 22),
            const CircularProgressIndicator(),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (finished)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'เสร็จสิ้น',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        else
          TextButton(
            onPressed: () {
              provider.resetMeasurementFlow();
              Navigator.pop(context);
            },
            child: const Text(
              'ยกเลิกการวัด',
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
