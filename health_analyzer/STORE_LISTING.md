# Google Play Store Listing Copy & Metadata

Use this document to copy-paste directly into your Google Play Developer Console when creating the app listing.

---

## 1. App Details

- **App Name:** LabLens - Blood Report Analyzer
- **Short Description (max 80 chars):**
  > AI-powered blood test analyzer, parameter tracker & health trend visualizer.
- **Category:** Medical or Health & Fitness
- **Tags:** Health, Medical Records, Lab Tests, Blood Pressure / Blood Tests, AI Assistant

---

## 2. Full Description (max 4000 chars)

```markdown
LabLens is an intelligent, offline-first blood test and medical report organizer that empowers you and your family to understand lab results and monitor long-term health trends.

With LabLens, you can easily digitize printed or digital blood test reports, organize records across multiple family profiles, and visualize key biomarker trends over time with clean interactive charts.

✨ KEY FEATURES:

🔍 AI-Powered Report Extraction
Quickly extract biomarkers from lab reports (images or PDFs) using state-of-the-art Google Gemini AI vision models. LabLens automatically reads parameter names, reference ranges, and measured values without tedious manual typing.

📊 Interactive Trend Charts
Track your biomarkers over time. See whether your Hemoglobin, Cholesterol, Blood Sugar (HbA1c), Platelets, or Vitamin D levels are improving, stable, or need attention with dynamic visual charts.

⚠️ Intelligent Out-of-Range Indicators
Instantly see which parameters fall outside standard reference intervals, helping you prepare informed questions for your next doctor's appointment.

👨‍👩‍👧‍👦 Multi-Profile Family Management
Create and organize separate profiles for yourself, children, parents, or dependants. Keep everyone's health records neatly categorized in one place.

🔒 Privacy-First & Offline Storage
Your sensitive health records belong to you. LabLens stores all profile information and medical data locally on your device in a secure private database. No accounts, no subscriptions, no tracking, and no external developer servers.

📤 Easy Data Import & Export
Export your reports to CSV or backup files to safely archive your medical records or share them with your physician.

🌓 Modern Material 3 Design
Enjoy a refined, intuitive experience featuring adaptive light, dark, and pure black AMOLED themes for comfortable viewing day or night.

---
⚠️ Medical Disclaimer:
LabLens is designed solely for informational, organizational, and personal reference purposes. LabLens is not a certified medical device and does not provide clinical diagnosis, medical evaluation, or treatment plans. Always seek the advice of a qualified healthcare professional with any questions regarding medical tests or health conditions.
```

---

## 3. Graphics & Asset Requirements

| Asset | Dimensions | Format | Note |
|---|---|---|---|
| **App Icon** | 512 x 512 px | 32-bit PNG | Exported from `assets/icon/app_icon.png` |
| **Feature Graphic** | 1024 x 500 px | PNG or JPEG | Banner displayed at top of store listing |
| **Phone Screenshots** | Min 2, max 8 (16:9 or 18:9) | PNG or JPEG | Min 1080px on shortest side |

**Recommended Screenshots to capture:**
1. **Home Screen**: Profile summary card and recent reports list.
2. **Scan / AI Extraction**: Scanning an image/PDF with real-time parameter detection.
3. **Report Details**: Clean breakdown with highlighted out-of-range parameters.
4. **Parameter Trends**: Beautiful interactive line chart comparing values over time.
5. **Dark Mode / AMOLED**: Showcase the sleek, high-contrast dark theme.

---

## 4. Play Console Policy & Questionnaire Cheat Sheet

### App Access
- **Selection:** *All functionality is available without special access restrictions.*

### Ads
- **Selection:** *No, my app does not contain ads.*

### Content Rating (IARC)
- **Category:** Utility / Reference / Health
- **Violence / Sexual content / Offensive language:** *No*
- **User interactions:** *No online chat, no location sharing.*
- **Expected Rating:** Everyone (PEGI 3).

### Target Audience & Content
- **Target Age:** 18 and older.
- **Children's Policy:** *Does not appeal to children.*

### Data Safety Form
- **Does your app collect or share user data?** -> *Yes* (only technical API transit for AI extraction).
- **Data Types Transferred:**
  - *Health Info / Photos / Files*: Ephemeral transit to Google Gemini API using user-provided API key for OCR.
  - *Collected by developer?* -> **No**. Data is stored only locally on user's device.
  - *Data encrypted in transit?* -> **Yes** (HTTPS to Google API).
  - *Account deletion?* -> Not applicable (no user accounts created).
