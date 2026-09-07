"""
Retry: gemini-3.5-transcribe (without thinkingConfig) + image models with delays.
Tests whether transcribe model can process PDF inlineData at all.
"""
import base64, json, re, time
from pathlib import Path
import urllib.request, urllib.error
import os

API_KEY  = os.environ.get('GEMINI_API_KEY', '')
API_BASE = "https://generativelanguage.googleapis.com/v1beta/models"

# Use just the first PDF to conserve quota
PDF_PATH = r"C:\Users\Devasy\OneDrive\Desktop\Hwiz\2025-11-02 14_37_07.pdf"

# Models with explicit thinkingConfig handling
MODELS = [
    # (model_id, label, add_thinking_config)
    ("gemini-3.5-transcribe",  "Transcribe model (no thinkingConfig)", False),
    ("gemini-2.5-flash-image", "Flash Image specialist",               False),
    ("gemini-3-pro-image",     "Pro Image specialist",                 True),
    ("gemini-3.5-flash",       "3.5 Flash baseline",                   True),
]

EXTRACTION_PROMPT = """You are a medical lab data extractor.
Extract ALL blood test parameters from this lab report.
Return ONLY valid JSON (no markdown, no extra text):
{
  "test_date": "YYYY-MM-DD or null",
  "lab_name": "string or null",
  "patient_name": "string or null",
  "parameters": {
    "<snake_case_name>": {
      "raw_name": "original name",
      "value": <number>,
      "unit": "string",
      "ref_min": <number or null>,
      "ref_max": <number or null>,
      "status": "normal|low|high|critical"
    }
  }
}"""

def load_pdf_b64(path):
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode()

def call_model(model_id, pdf_b64, use_thinking=True):
    url = f"{API_BASE}/{model_id}:generateContent"
    gen_config = {"temperature": 0.0, "maxOutputTokens": 8192}
    if use_thinking:
        gen_config["thinkingConfig"] = {"thinkingLevel": "minimal"}

    payload = {
        "contents": [{
            "role": "user",
            "parts": [
                {"text": EXTRACTION_PROMPT},
                {"inlineData": {"mimeType": "application/pdf", "data": pdf_b64}},
            ],
        }],
        "generationConfig": gen_config,
    }
    data = json.dumps(payload).encode()
    req = urllib.request.Request(
        url, data=data,
        headers={"Content-Type": "application/json", "x-goog-api-key": API_KEY},
        method="POST",
    )
    t0 = time.time()
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return json.loads(resp.read()), time.time() - t0
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        try:
            msg = json.loads(body)["error"]["message"]
        except Exception:
            msg = body[:400]
        return {"error": msg, "http_status": e.code}, time.time() - t0
    except Exception as ex:
        return {"error": str(ex)}, time.time() - t0

def get_text(resp):
    parts = resp.get("candidates", [{}])[0].get("content", {}).get("parts", [])
    return "".join(p.get("text", "") for p in parts if not p.get("thought"))

def parse_json(text):
    cleaned = re.sub(r"```(?:json)?", "", text).strip().strip("`")
    m = re.search(r"\{.*\}", cleaned, re.DOTALL)
    if not m:
        return None
    try:
        return json.loads(m.group())
    except Exception:
        return None

def score(parsed):
    if not parsed or "parameters" not in parsed:
        return {"ok": False, "params": 0, "complete": 0}
    ps = parsed["parameters"]
    complete = sum(1 for v in ps.values()
                   if isinstance(v, dict) and v.get("value") is not None and v.get("unit"))
    return {"ok": True, "params": len(ps), "complete": complete,
            "sample": list(ps.keys())[:8]}

# ── Run ───────────────────────────────────────────────────────────────────────
print(f"Loading PDF...", end=" ", flush=True)
pdf_b64 = load_pdf_b64(PDF_PATH)
print(f"done ({len(pdf_b64)//1024} KB encoded)\n")

results = {}
DELAY_BETWEEN = 8  # seconds between calls to stay under rate limit

for i, (model_id, label, use_thinking) in enumerate(MODELS):
    if i > 0:
        print(f"  (waiting {DELAY_BETWEEN}s to avoid rate limit...)")
        time.sleep(DELAY_BETWEEN)

    print(f"{'='*60}")
    print(f"Model : {model_id}")
    print(f"Label : {label}")
    print(f"Think : {use_thinking}")
    print(f"Calling...", end=" ", flush=True)

    resp, elapsed = call_model(model_id, pdf_b64, use_thinking)

    if "error" in resp:
        code = resp.get("http_status", "?")
        msg  = resp["error"][:250]
        print(f"ERROR HTTP {code}")
        print(f"  Message: {msg}")
        results[model_id] = {"error": msg, "elapsed": round(elapsed, 1)}
        continue

    text   = get_text(resp)
    parsed = parse_json(text)
    s      = score(parsed)
    finish = resp.get("candidates", [{}])[0].get("finishReason", "?")
    usage  = resp.get("usageMetadata", {})

    print(f"done in {elapsed:.1f}s  [{finish}]")
    print(f"  tokens : in={usage.get('promptTokenCount','?')} out={usage.get('candidatesTokenCount','?')}")
    print(f"  JSON   : {s['ok']}")
    print(f"  params : {s['params']} total, {s['complete']} complete")
    if s.get("sample"):
        print(f"  sample : {', '.join(s['sample'])}")
    if not s["ok"]:
        print(f"  raw[:500]: {text[:500]}")

    results[model_id] = {
        "elapsed": round(elapsed, 1),
        "finish": finish,
        "in_tokens": usage.get("promptTokenCount"),
        "out_tokens": usage.get("candidatesTokenCount"),
        **s,
    }

# ── Summary ───────────────────────────────────────────────────────────────────
print(f"\n{'='*60}")
print("FINAL SUMMARY")
print(f"{'='*60}")
print(f"{'Model':<28} {'Params':>6} {'Complete':>8} {'Time':>7}  JSON")
print("-" * 58)
for mid, r in results.items():
    if "error" in r:
        print(f"{mid:<28} {'ERR':>6} {'ERR':>8} {r['elapsed']:>6.1f}s  N")
    else:
        print(f"{mid:<28} {r.get('params',0):>6} {r.get('complete',0):>8} {r['elapsed']:>6.1f}s  {'Y' if r.get('ok') else 'N'}")

# Save
out = r"C:\Users\Devasy\OneDrive\Desktop\Hwiz\transcription_comparison.json"
with open(out, "w") as f:
    json.dump(results, f, indent=2)
print(f"\nSaved to {out}")
