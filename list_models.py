"""
Step 1: List all available Gemini models from the API
and identify any transcribe / document-specific models.
"""
import json
import urllib.request
import urllib.error
import os

API_KEY = os.environ.get('GEMINI_API_KEY', '')

req = urllib.request.Request(
    "https://generativelanguage.googleapis.com/v1beta/models?pageSize=200",
    headers={"x-goog-api-key": API_KEY},
)

with urllib.request.urlopen(req, timeout=30) as resp:
    data = json.loads(resp.read())

models = data.get("models", [])
print(f"Total models available: {len(models)}\n")

print("=== ALL MODEL NAMES ===")
for m in sorted(models, key=lambda x: x["name"]):
    name = m["name"]
    display = m.get("displayName", "")
    methods = m.get("supportedGenerationMethods", [])
    print(f"  {name:<60} | {display:<40} | methods: {methods}")

print("\n=== TRANSCRIBE / DOCUMENT / VISION MODELS ===")
keywords = ["transcribe", "document", "vision", "preview", "exp", "pro", "2.5", "3.5"]
for m in models:
    name = m["name"].lower()
    if any(k in name for k in keywords):
        methods = m.get("supportedGenerationMethods", [])
        print(f"  {m['name']:<60} methods={methods}")
