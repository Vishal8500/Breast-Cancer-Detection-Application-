from flask import Flask, request, jsonify
from flask_cors import CORS
from PIL import Image
import numpy as np
import tensorflow as tf
import os

app = Flask(__name__)
CORS(app, resources={r"/predict": {"origins": "*"}})

MODEL_PATH = os.environ.get("MODEL_PATH", "my_model3.h5")

# Load the model
try:
    model = tf.keras.models.load_model(MODEL_PATH, compile=False)
    print(f"✅ Model loaded successfully from {MODEL_PATH}")
except Exception as e:
    print(f"❌ ERROR: Failed to load the model from {MODEL_PATH}!", str(e))
    model = None

def preprocess_image(image_file):
    img = Image.open(image_file).convert('RGB')
    img = img.resize((512, 512))
    img_array = np.array(img) / 255.0
    img_array = np.expand_dims(img_array, axis=0)
    return img_array

@app.route('/predict', methods=['POST', 'OPTIONS'])
def predict():
    if request.method == 'OPTIONS':
        return '', 204
        
    try:
        if 'image' not in request.files:
            return jsonify({"error": "No image uploaded"}), 400

        file = request.files['image']
        if file.filename == '':
            return jsonify({"error": "No selected image"}), 400

        if model is None:
            return jsonify({"error": "Model not loaded"}), 500

        image_array = preprocess_image(file)
        prediction = model.predict(image_array)
        result = "Cancerous" if prediction[0][0] >= 0.5 else "Non-Cancerous"
        
        return jsonify({
            "prediction": result,
            "confidence": float(prediction[0][0])
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
