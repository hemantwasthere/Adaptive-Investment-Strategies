# app.py
import pickle
from flask import Flask, request, jsonify
import numpy as np

app = Flask(__name__)

# Load the model
with open('decision_tree_model.pkl', 'rb') as f:
    model = pickle.load(f)

@app.route('/predict', methods=['POST'])
def predict():
    volatility_val = np.array(0.00001).reshape(-1, 1) 

    # print(request.form)
    # data = request.json
    # Assuming data is pre-processed appropriately
    prediction = model.predict(volatility_val)
    return jsonify({'prediction': prediction.tolist()})

print("Starting the server")
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=6000)
