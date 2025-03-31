from flask import Flask, jsonify
import mysql.connector
from dotenv import load_dotenv
import os

load_dotenv(dotenv_path="./.env", override=True)

app = Flask(__name__)
app.config['DEBUG'] = True

def get_db_connection():
    try:
        connection = mysql.connector.connect(
            host=os.getenv("MYSQL_HOST"),
            user=os.getenv("MYSQL_USER"),
            password=os.getenv("MYSQL_PASSWORD"),
            database=os.getenv("MYSQL_DB"),
            ssl_ca=os.getenv("SSL_CA"),
            ssl_verify_cert=True
        )
        return connection
    except mysql.connector.Error as err:
        print("Database connection error: ", str(err))
        return None

@app.route('/users', methods=['GET'])
def get_users():
    connection = get_db_connection()
    if connection is None:
        return jsonify({"error": "Database connection error"}), 500
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute('SELECT * FROM users')
        users = cursor.fetchall()
        cursor.close()
        connection.close()
        return jsonify(users)
    except Exception as e:
        print("Query error: ", str(e))
        return jsonify({"error": "Failed to fetch data"}), 500 

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)



