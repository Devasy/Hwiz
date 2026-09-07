# Privacy Policy for LabLens

**Last Updated:** September 6, 2026

**LabLens** ("we", "our", or "the app") is committed to protecting your privacy. This Privacy Policy outlines how your information is handled when you use the LabLens mobile application.

---

## 1. Summary: Offline-First & Privacy-Focused

LabLens is designed with privacy as a foundational principle:
- **No Account Required:** You do not need to create an account or provide personal contact information (e.g., email or phone number) to use the app.
- **On-Device Storage:** All profiles, blood test reports, and historical parameter trends are stored locally on your device in the application's private SQLite sandbox. When you choose to run AI extraction or insights, selected document images and parameters are transmitted securely via HTTPS directly to Google's Gemini API.
- **No Developer Servers:** We do not operate external servers that collect, store, or sell your health data.
- **No Third-Party Analytics or Ads:** The app contains no third-party trackers, telemetry, or advertising frameworks.

---

## 2. Information We Handle

### A. Health & Profile Data (Stored Locally)

- **Profile Details:** Name, optional date of birth, optional gender, and local profile photo.
- **Blood Test Documents:** Images and PDF reports that you choose to scan or import.
- **Medical Parameters:** Extracted test names, numeric values, units, and reference ranges.

*All profile and health data resides locally on your device in the application sandbox, with the exception of on-demand transmissions to Google's Gemini API when you initiate AI report extraction or trend analysis.*

### B. Device Permissions

- **Camera / Photo Library / File Storage:** Used exclusively to select, capture, or import lab reports and profile photos chosen by you.
- **Internet Access:** Used solely to communicate with Google's Gemini API for OCR and report extraction when an API key is configured.

---

## 3. Third-Party Services: Google Gemini API

When you scan a lab report using the AI extraction feature:
- The selected document (image or PDF) is sent directly from your device to the **Google Gemini API** (`generativelanguage.googleapis.com`) using your personal API key.
- This request is subject to [Google's Privacy Policy](https://policies.google.com/privacy) and [Google AI Terms of Service](https://ai.google.dev/terms).
- We do not intercept, relay, or store this transmission on any intermediary server.

---

## 4. Medical Disclaimer

LabLens is a personal health data organization and trend-tracking tool. It is provided for informational purposes only. LabLens is **not a certified medical device** and does **not provide medical diagnosis, clinical treatment, or professional advice**. Always consult a qualified healthcare provider regarding test results or medical conditions.

---

## 5. Data Security & Retention

- Because your data is stored locally on your device, its security depends on your device's security settings (e.g., screen lock, biometric authentication).
- You have complete control over your data: you can edit, export, or permanently delete any profile, report, or parameter at any time directly within the app.
- Uninstalling the application will remove all locally stored database records unless you have created an external export.

---

## 6. Children's Privacy

LabLens is intended for use by adults managing personal and family health records. We do not knowingly collect personal data from children. Parents or guardians may store family member records on their own personal devices under their supervision.

---

## 7. Changes to This Policy

We may update this Privacy Policy from time to time to reflect app updates or regulatory requirements. The updated policy will be posted within the application and repository.

---

## 8. Contact Us

If you have questions or concerns about this Privacy Policy, please open an issue or contact:
- **Developer:** Devasy Patel
- **GitHub:** https://github.com/Devasy23
