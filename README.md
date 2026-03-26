#  AI Study Companion

An AI-powered study assistant that helps students quickly understand large amounts of text and PDF documents by generating clean, readable summaries.

---

##  Overview

AI Study Companion is a full-stack project built to simplify studying.  
Instead of reading long chapters or notes, users can paste text or upload PDFs and instantly get concise summaries.

This project combines a **FastAPI backend** with a **Flutter frontend**, making it both functional and visually interactive.

---

##  Features

-  Text Summarization  
  Paste any paragraph and get key points instantly

-  PDF Summarization  
  Upload study material (books/notes) and extract important ideas

-  Fast Processing  
  Lightweight backend for quick responses

-  Clean UI  
  Built with Flutter for a smooth and modern experience

---

##  Tech Stack

### Frontend
- Flutter (Dart)

### Backend
- FastAPI (Python)
- Uvicorn

### Libraries Used
- PyPDF2 (PDF text extraction)
- Pydantic (data validation)
- python-multipart (file uploads)
- Regex (text cleaning)

---

##  Project Structure
AI-Study-Companion/
│
├── backend/
│ ├── main.py
│ ├── requirements.txt
│
├── frontend/
│ ├── lib
│ ├── web
│ ├── android
│ ├── pubspec.yaml
│
└──.gitgnore
└── README.md

##  How to Run

###  Backend Setup

```bash
cd backend
install the dependeies in requirements.txt
uvicorn main:app --reload
```

###  FrontEnd Setup
```bash
cd frontend
flutter pub get
flutter run
```

## How It Works
- User inputs text or uploads a PDF
- Backend extracts and cleans the text
- Text is split into meaningful sentences
- Important sentences are selected
- Clean bullet-point summary is returned

