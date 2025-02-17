from flask import Flask, request, jsonify
from app import switch_model

app = Flask(__name__)

@app.route('/api/switch_model', methods=['POST'])
def api_switch_model():
    new_model = request.args.get('model')
    response = switch_model(new_model)
    return jsonify({"message": response})
