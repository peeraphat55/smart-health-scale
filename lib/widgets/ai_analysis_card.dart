import 'package:flutter/material.dart';
import 'package:project/core/app_theme.dart';

class AIAnalysisBox extends StatelessWidget {
  final Map<String, dynamic> aiData;
  const AIAnalysisBox({super.key, required this.aiData});

  @override
  Widget build(BuildContext context) {
    String predictionText = (aiData['prediction'] != null && aiData['prediction'] > 0) 
        ? (aiData['prediction'] as double).toStringAsFixed(2) : '-';
        
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardOrangeLight, 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.5))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.smart_toy, color: Colors.deepOrange),
              SizedBox(width: 10),
              Text("AI วิเคราะห์แนวโน้ม", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange))
            ],
          ),
          const Divider(color: Colors.orangeAccent),
          const SizedBox(height: 10),
          Center(child: Text("แนวโน้ม: ${aiData['trend'] ?? '-'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          Center(child: Text("คาดการณ์ BMI ครั้งถัดไป: $predictionText", style: const TextStyle(fontSize: 16))),
          const SizedBox(height: 20),
          const Text("📌 การประเมินสถานะ:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
          Text(aiData['evaluation'] ?? '-', style: const TextStyle(fontSize: 15, color: Colors.black87)),
          const SizedBox(height: 15),
          const Text("💡 คำแนะนำจากระบบ:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          Text(aiData['recommendation'] ?? '-', style: const TextStyle(fontSize: 15, color: Colors.black87)),
        ],
      ),
    );
  }
}