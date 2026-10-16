# SCANine — Flutter App

**SCANine** is an AI-assisted mobile application that helps dog owners identify possible skin conditions using images. It uses MobileNetV3-Large for image classification and CAM/Grad-CAM-style heatmaps to visualize the image regions contributing to predictions.

## Overview

SCANine aims to provide dog owners with a convenient preliminary screening tool for common dog skin conditions. It displays prediction results, confidence scores, visual explanations, basic recommendations, and nearby veterinary clinic locations.

The application is intended for preliminary support only and does not replace professional veterinary diagnosis.

## Features

- **AI Skin Disease Detection** – Classifies dog skin images using MobileNetV3.
- **Image Upload and Capture** – Allows users to select or capture images for analysis.
- **Confidence Scores** – Displays the model's confidence for its predictions.
- **Explainable AI** – Generates CAM/Grad-CAM-style heatmaps highlighting image regions contributing to the prediction.
- **Skin Image Analysis** – Provides supplementary redness and texture measurements.
- **Basic Recommendations** – Displays supporting information and recommendations.
- **Nearby Veterinary Clinics** – Helps users find veterinary clinics using location services and Google Places API.
- **User and Pet Management** – Supports user accounts, pet profiles, and analysis history.

**Note:** The current application supports dog-owner access only. Veterinarians cannot log in to assess cases or directly contact dog owners through the application.

## How to Run

### Prerequisites

- Flutter SDK and Dart
- Android Studio or Visual Studio Code
- Android emulator or Android device
- Python and the required backend dependencies, if running the backend locally

### 1. Clone the Repository

```bash
git clone https://github.com/yysfall/SCANine
cd SCANine
```

### 2. Install Flutter Dependencies

Navigate to the Flutter project directory:

```bash
flutter pub get
```

### 3. Configure the Application

Set up the required configuration for:

- Supabase authentication
- Google Places API
- Backend API URL
- TensorFlow Lite model files

Keep API keys and other secrets out of public repositories.

### 4. Run the Backend

If the backend is stored separately, navigate to its directory and install its dependencies:

```bash
pip install -r requirements.txt
```

Start the FastAPI server, assuming the entry point is `main.py` and the application instance is named `app`:

```bash
uvicorn main:app --reload
```

### 5. Run the Mobile Application

Start an Android emulator or connect an Android device, then run:

```bash
flutter run
```

Ensure the backend URL and API configuration match your environment before testing features that require them.

**Backend Repository Link:** https://github.com/yysfall/SCANine_backend   
**Backend API Link(RENDER):** https://scanine-backend.onrender.com/docs

## Disclaimer

SCANine is an academic research project. Its predictions are not confirmed diagnoses and should not be used as the sole basis for treatment decisions. Consult a licensed veterinarian for professional assessment and treatment.


