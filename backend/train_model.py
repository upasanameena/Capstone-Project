#!/usr/bin/env python3
"""
Initial ML Model Training Script
Trains a Logistic Regression model for the WAF using sample data.
"""

import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import pickle
import os
import csv
import re
from urllib import parse

# Feature extraction function (same as in Proxy_server.py)
badwords = [
    'select', 'union', 'or', 'and', 'where', 'from', 'insert', 'update', 'delete',
    'drop', 'table', 'database', 'exec', 'execute', 'script', 'waitfor', 'delay',
    'sleep', 'order by', 'group by', 'having', 'join', 'inner join', 'outer join',
    'script', '<script', '</script>', 'javascript:', 'onerror', 'onclick', 'onload',
    'alert', 'eval', 'document.cookie', 'document.write',
    'admin', 'uid', 'password', 'passwd', 'root', 'system', 'cmd', 'command',
    'shell', 'phpinfo', 'base64', 'char(', 'ascii('
]

def ExtractFeatures(path, body):
    """Extract 12 numerical features from path and body."""
    path = str(path)
    body = str(body)
    combined_raw = path + body
    raw_percentages = combined_raw.count("%")
    raw_spaces = combined_raw.count(" ")

    raw_percentages_count = raw_percentages if raw_percentages > 3 else 0
    raw_spaces_count = raw_spaces if raw_spaces > 3 else 0

    path_decoded = parse.unquote_plus(path)
    body_decoded = parse.unquote_plus(body)

    single_q = path_decoded.count("'") + body_decoded.count("'")
    double_q = path_decoded.count('"') + body_decoded.count('"')
    dashes = path_decoded.count("--") + body_decoded.count("--")
    braces = path_decoded.count("(") + body_decoded.count("(")
    spaces = path_decoded.count(" ") + body_decoded.count(" ")
    semicolons = path_decoded.count(";") + body_decoded.count(";")
    angle_brackets = path_decoded.count("<") + path_decoded.count(">") + body_decoded.count("<") + body_decoded.count(">")
    special_chars = sum(path_decoded.count(c) + body_decoded.count(c) for c in '$&|')
    badwords_count = sum(path_decoded.lower().count(word) + body_decoded.lower().count(word) for word in badwords)
    path_length = len(path_decoded)
    body_length = len(body_decoded)

    return [single_q, double_q, dashes, braces, spaces, raw_percentages_count,
            semicolons, angle_brackets, special_chars, path_length, body_length, badwords_count]

def generate_training_data():
    """Generate sample training data if CSV files don't exist."""
    print("Generating sample training data...")
    
    # Benign examples
    benign_samples = [
        ("/", ""),
        ("/index.html", ""),
        ("/about", ""),
        ("/products?id=123", ""),
        ("/search?q=hello", ""),
        ("/api/users", ""),
        ("/login", "username=user&password=pass123"),
        ("/register", "email=test@example.com&name=John"),
        ("/api/data", '{"key":"value"}'),
        ("/contact", "message=Hello world"),
    ]
    
    # Malicious examples
    malicious_samples = [
        ("/?id=1' OR '1'='1", ""),
        ("/login?user=admin'--", ""),
        ("/search?q=1' UNION SELECT * FROM users--", ""),
        ("/api?id=1; DROP TABLE users--", ""),
        ("/page?id=1' OR 1=1--", ""),
        ("/login", "username=admin' OR '1'='1&password=x"),
        ("/api", '{"name":"<script>alert(1)</script>"}'),
        ("/upload", "file=../../../etc/passwd"),
        ("/api?id=1; exec('rm -rf /')", ""),
        ("/page", "data=javascript:alert('XSS')"),
        ("/admin?id=1' UNION SELECT password FROM users--", ""),
        ("/search", "q=1' OR '1'='1'--"),
        ("/api", '{"cmd":"; cat /etc/passwd"}'),
        ("/page?id=1' AND 1=1--", ""),
        ("/login", "user=admin' OR 1=1--&pass=x"),
    ]
    
    # Create CSV files
    os.makedirs("Data_Collection", exist_ok=True)
    
    # Write benign samples
    with open("benign_payloads.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        for path, body in benign_samples:
            features = ExtractFeatures(path, body)
            writer.writerow([path, body] + features)
    
    # Write malicious samples
    with open("malicious_payloads.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        for path, body in malicious_samples:
            features = ExtractFeatures(path, body)
            writer.writerow([path, body] + features)
    
    print(f"✅ Generated {len(benign_samples)} benign and {len(malicious_samples)} malicious samples")
    return benign_samples, malicious_samples

def load_training_data():
    """Load training data from CSV files or generate if missing."""
    benign_data = []
    malicious_data = []
    
    # Try to load from existing CSVs
    if os.path.exists("benign_payloads.csv"):
        with open("benign_payloads.csv", "r", encoding="utf-8") as f:
            reader = csv.reader(f)
            for row in reader:
                if len(row) >= 2:
                    path, body = row[0], row[1]
                    features = ExtractFeatures(path, body)
                    benign_data.append(features)
    
    if os.path.exists("malicious_payloads.csv"):
        with open("malicious_payloads.csv", "r", encoding="utf-8") as f:
            reader = csv.reader(f)
            for row in reader:
                if len(row) >= 2:
                    path, body = row[0], row[1]
                    features = ExtractFeatures(path, body)
                    malicious_data.append(features)
    
    # If no data, generate sample data
    if not benign_data and not malicious_data:
        print("No existing CSV files found. Generating sample training data...")
        generate_training_data()
        return load_training_data()
    
    return benign_data, malicious_data

def train_model():
    """Train the Logistic Regression model."""
    print("\n" + "="*60)
    print("ML Model Training for Dual-Layer Firewall")
    print("="*60 + "\n")
    
    # Load training data
    print("Loading training data...")
    benign_data, malicious_data = load_training_data()
    
    if not benign_data and not malicious_data:
        print("❌ No training data available!")
        return False
    
    # Prepare features and labels
    X = benign_data + malicious_data
    y = [0] * len(benign_data) + [1] * len(malicious_data)
    
    print(f"✅ Loaded {len(benign_data)} benign samples")
    print(f"✅ Loaded {len(malicious_data)} malicious samples")
    print(f"✅ Total samples: {len(X)}\n")
    
    # Convert to numpy arrays
    X = np.array(X)
    y = np.array(y)
    
    # Split into train and test sets
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    print("Training Logistic Regression model...")
    # Train Logistic Regression model
    model = LogisticRegression(
        max_iter=1000,
        random_state=42,
        solver='lbfgs',
        class_weight='balanced'  # Handle imbalanced data
    )
    
    model.fit(X_train, y_train)
    
    # Evaluate model
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    
    print(f"\n✅ Model trained successfully!")
    print(f"   Accuracy: {accuracy:.2%}")
    print(f"\nClassification Report:")
    print(classification_report(y_test, y_pred, target_names=['Benign', 'Malicious']))
    print(f"\nConfusion Matrix:")
    print(confusion_matrix(y_test, y_pred))
    
    # Save model
    model_path = "training_model.pkl"
    with open(model_path, "wb") as f:
        pickle.dump(model, f)
    
    print(f"\n✅ Model saved to: {model_path}")
    print("\n" + "="*60)
    print("Training complete! You can now run Proxy_server.py")
    print("="*60 + "\n")
    
    return True

if __name__ == "__main__":
    try:
        train_model()
    except Exception as e:
        print(f"\n❌ Error during training: {e}")
        import traceback
        traceback.print_exc()
        exit(1)

