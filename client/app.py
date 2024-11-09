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
    data = request.get_json()
    print('req-data', data)
    
    # Assuming data is pre-processed appropriately
    prediction = model.predict([data['volatility']])
    return jsonify({'prediction': prediction.tolist()})

print("Starting the server")
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=6000)
