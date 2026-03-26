from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import re
import PyPDF2

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, replace "*" with your domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# -------- Request Model --------
class TextRequest(BaseModel):
    text: str


# -------- CLEANING FUNCTION --------
def clean_text(text):
    # Remove weird unicode characters (PDF junk)
    text = text.encode("ascii", "ignore").decode()

    # Remove extra spaces
    text = re.sub(r'\s+', ' ', text)

    # Keep only letters, numbers, dots, spaces
    text = re.sub(r'[^a-zA-Z0-9. ]', '', text)

    return text


# -------- SUMMARIZER --------
def summarize_text(text):
    print("RAW TEXT:", text)

    # ✅ USE CLEAN FUNCTION
    text = clean_text(text)

    print("CLEAN TEXT:", text)

    # Split sentences
    sentences = text.split(".")
    print("SENTENCES:", sentences)

    clean_sentences = []

    for s in sentences:
        s = s.strip()
        if len(s) > 10:
            clean_sentences.append(s.capitalize())

    print("FILTERED:", clean_sentences)

    if not clean_sentences:
        return ["• Text too short or not readable"]

    return ["- " + s for s in clean_sentences[:4]]
# -------- TEXT SUMMARIZE API --------
@app.post("/summarize")
def summarize(request: TextRequest):
    result = summarize_text(request.text)
    return {"summary": result}


# -------- PDF UPLOAD API --------
@app.post("/upload-pdf")
async def upload_pdf(file: UploadFile = File(...)):
    pdf_reader = PyPDF2.PdfReader(file.file)

    text = ""

    for page in pdf_reader.pages:
        extracted = page.extract_text()
        if extracted:
            text += extracted
            
    result = summarize_text(text)

    return {"summary": result}

