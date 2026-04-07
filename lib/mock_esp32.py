import sys
import requests
import time
import random

sys.stdout.reconfigure(encoding='utf-8')
# ⚠️ URL เดิมของคุณ
FIREBASE_URL = "https://realtime-34e55-default-rtdb.asia-southeast1.firebasedatabase.app/smart_scale.json"

print("เริ่มจำลองการส่งข้อมูลเครื่องชั่งน้ำหนักและ Heart Rate...")

loop_count = 0
current_hr = 205 # ค่าเริ่มต้น

try:
    while True:
        # 1. สุ่มน้ำหนักทุกๆ 2 วินาที (เหมือนเดิม)
        weight = round(random.uniform(50.0, 70.0), 1)
        data = {"current_weight": weight}
        
        # 2. เช็คว่าครบ 30 รอบ (60 วินาที) หรือยัง ถ้าครบให้สุ่ม Heart Rate ใหม่
        if loop_count % 30 == 0:
            current_hr = random.randint(200, 230)
            data["current_heart_rate"] = current_hr
            print(f"❤️ อัปเดต Heart Rate: {current_hr} BPM")
            
        # 3. ส่งข้อมูลไปอัปเดตที่ Firebase
        response = requests.patch(FIREBASE_URL, json=data)
        
        if response.status_code == 200:
            print(f"ส่งข้อมูลสำเร็จ: Weight {weight} Kg")
        else:
            print(f"เกิดข้อผิดพลาด: {response.text}")
            
        # เพิ่มตัวนับรอบ และหน่วงเวลา 2 วินาที
        loop_count += 1
        time.sleep(2)

except KeyboardInterrupt:
    print("\nหยุดการจำลองข้อมูล")