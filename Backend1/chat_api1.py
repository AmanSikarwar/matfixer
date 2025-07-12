import os
import traceback
import uvicorn
import json
import asyncio
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, status, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import List, Dict, Literal

# --- Environment Setup ---
print("--- API Server Start ---")
print("[Main] Loading environment variables from .env file...")
load_dotenv()
print("[Main] Environment variables loaded.")

# --- Import and initialize LangGraph application ---
print("[Main] Importing compiled graph application from graph.graph...")
try:
    from graph.graph import app as langgraph_app
    print("[Main] LangGraph 'app' imported successfully.")
except Exception as import_err:
    print(f"[Main] FATAL ERROR: Failed to import or compile the LangGraph app: {import_err}")
    traceback.print_exc()
    exit(1)

# --- FastAPI Application Setup ---
app = FastAPI(
    title="Agentic Report Generator API",
    description="Provides generation of answers via LangGraph workflow.",
    version="1.0.0"
)
print("[Main] FastAPI app created.")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Data Models ---
class Attachment(BaseModel):
    type: str
    data: str

class ChatMessage(BaseModel):
    role: Literal["user", "llm"]
    content: str
    attachments: List[Attachment] = []

class GenerateRequest(BaseModel):
    prompt: str
    attachments: List[Attachment] = []

class GenerateResponse(BaseModel):
    response: str

# Import legacy models
from api_models import QueryRequest, ReportResponse

# In-memory chat history store
chat_histories: Dict[str, List[ChatMessage]] = {}

# Utility for citation formatting
def citation(text: str) -> str:
    return text

# --- Non-streaming generate endpoint ---
@app.post("/generate", response_model=GenerateResponse)
async def generate(request: GenerateRequest):
    # Initialize state
    state = {"query": request.prompt, "documents": [], "context": "", "answer": ""}
    # Run the RAG pipeline synchronously
    final_state = await langgraph_app.ainvoke(state, {"recursion_limit": 15})
    # Extract and format
    answer = citation(final_state.get("final_report", ""))
    return GenerateResponse(response=answer)

# --- Non-streaming chat endpoint ---
@app.post("/send-message", response_model=GenerateResponse)
async def send_message(request: GenerateRequest, session_id: str = Query(...)):
    # Initialize history
    if session_id not in chat_histories:
        chat_histories[session_id] = []
    # Append user message
    chat_histories[session_id].append(
        ChatMessage(role="user", content=request.prompt, attachments=request.attachments)
    )
    # Initialize state
    state = {"query": request.prompt, "documents": [], "context": "", "answer": ""}
    # Run the RAG pipeline
    final_state = await langgraph_app.ainvoke(state, {"recursion_limit": 15})
    answer = citation(final_state.get("final_report", ""))
    # Append llm message
    chat_histories[session_id].append(
        ChatMessage(role="llm", content=answer)
    )
    return GenerateResponse(response=answer)

# --- History endpoints ---
@app.get("/history/{session_id}")
async def get_history(session_id: str):
    return {"history": chat_histories.get(session_id, [])}

@app.put("/history/{session_id}")
async def set_history(session_id: str, history: List[ChatMessage]):
    chat_histories[session_id] = history
    return {"success": True}

# --- Legacy synchronous endpoint for backward compatibility ---
@app.post("/invoke", response_model=ReportResponse, tags=["Workflow"])
async def invoke_workflow(request: QueryRequest):
    print(f"[API /invoke] Received: {request.query}")
    try:
        final_state = await langgraph_app.ainvoke({"query": request.query}, {"recursion_limit": 15})
        report = final_state.get('final_report')
        error_message = final_state.get('error')
        return ReportResponse(query=request.query, report=report, error=error_message)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

# --- Root endpoint ---
@app.get("/", tags=["General"])
async def read_root():
    return {"message": "Welcome to the Agentic Report Generator API. Use /docs for details."}

# --- Run the API Server ---
if __name__ == "__main__":
    print("[Main] Starting Uvicorn server...")
    uvicorn.run("new:app", host="0.0.0.0", port=8000, reload=True)
