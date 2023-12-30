from flask import Flask, request, jsonify
import tensorflow as tf
import numpy as np
import base64
from PIL import Image
import io

app = Flask(__name__)

interpreter = tf.lite.Interpreter(model_path="path_to_your_model.tflite")
interpreter.allocate_tensors()

@app.route('/analyze', methods=['POST'])
def analyze():
    data = request.json
    base64_image = data['image']
    image = Image.open(io.BytesIO(base64.b64decode(base64_image)))

    image = image.resize((224, 224))
    image = np.array(image) / 255.0
    image = image.reshape(1, 224, 224, 3).astype(np.float32)

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    interpreter.set_tensor(input_details[0]['index'], image)
    interpreter.invoke()

    output_data = interpreter.get_tensor(output_details[0]['index'])
    result = output_data[0][0]

    return jsonify({'result': float(result)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
