import time
import requests
import random

# ก๊อปปี้ URL ของ Realtime Database จากหน้าเว็บ Firebase มาใส่ตรงนี้
# (เช่น https://smart-health-scale-default-rtdb.asia-southeast1.firebasedatabase.app)
DATABASE_URL = "https://ใส่-URL-ฐานข้อมูลของคุณตรงนี้.firebasedatabase.app"

print("🚀 กำลังจำลองการทำงานของเครื่องชั่ง ESP32...")
while True:
    # สุ่มน้ำหนักและชีพจร
    mock_weight = round(random.uniform(60.0, 65.0), 1)
    mock_hr = random.randint(75, 90)
    
    data = {
        "current_weight": mock_weight,
        "current_heart_rate": mock_hr
    }
    
    try:
        # ส่งค่าไปที่ Firebase
        requests.put(f"{DATABASE_URL}/smart_scale.json", json=data)
        print(f"📡 ส่งข้อมูลแล้ว: น้ำหนัก {mock_weight} Kg, ชีพจร {mock_hr} BPM")
    except Exception as e:
        print("❌ ส่งข้อมูลไม่สำเร็จ:", e)
        
    time.sleep(3) # ส่งข้อมูลทุกๆ 3 วินาที