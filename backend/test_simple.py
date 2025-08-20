from flask import Flask, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/api/test', methods=['GET'])
def test():
    return jsonify({
        'status': 'OK',
        'message': 'Test server is working!'
    })

if __name__ == '__main__':
    print("🚀 Запуск тестового сервера...")
    app.run(debug=True, host='0.0.0.0', port=5000)
