import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split

print("1. กำลังสร้างข้อมูลจำลองการแพทย์...")
np.random.seed(42)
n_samples = 2000

# ข้อมูล Input: เพศ(0/1), อายุ, BMI, ความชันกราฟย้อนหลัง(Slope)
genders = np.random.choice([0, 1], size=n_samples) 
ages = np.random.randint(18, 65, size=n_samples)
bmis = np.random.uniform(16.0, 35.0, size=n_samples)
slopes = np.random.uniform(-0.8, 0.8, size=n_samples)

# จัดกลุ่ม Class คำแนะนำ (0 ถึง 5) 
labels = []
for g, a, bmi, m in zip(genders, ages, bmis, slopes):
    if bmi >= 25.0:
        labels.append(1 if m > 0.1 else 2) 
    elif 18.5 <= bmi < 25.0:
        if m > 0.3: labels.append(3)       
        elif m < -0.3: labels.append(4)    
        else: labels.append(0)             
    else:
        labels.append(5)                   

X = np.column_stack((genders, ages, bmis, slopes))
y = np.array(labels)

print("2. กำลังเทรนโมเดล AI (Neural Network)...")
model = tf.keras.Sequential([
    tf.keras.layers.Dense(16, activation='relu', input_shape=(4,)),
    tf.keras.layers.Dense(8, activation='relu'),
    tf.keras.layers.Dense(6, activation='softmax')
])

model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])
model.fit(X, y, epochs=100, batch_size=32, verbose=0)

print("3. กำลังแปลงเป็น TensorFlow Lite (.tflite)...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

with open('health_model.tflite', 'wb') as f:
    f.write(tflite_model)
    
print("✅ สำเร็จ! ได้ไฟล์ 'health_model.tflite' แล้ว")