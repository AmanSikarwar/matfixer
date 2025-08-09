#!/usr/bin/env python3
import os
import torch
from typing import List, Dict, Any, Literal, Optional
from typing_extensions import TypedDict
from operator import itemgetter
import re
import json
import asyncio # Keep asyncio if other parts might need it, but not strictly for the modified endpoints
import uvicorn

# FastAPI imports
from fastapi import FastAPI, Query, HTTPException
# ****** MODIFIED IMPORT ******
from fastapi.responses import StreamingResponse, JSONResponse # Added JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# LangChain / Chroma / Gemini imports
from langchain_core.prompts import PromptTemplate
from langchain_core.documents import Document
from langchain_core.output_parsers import StrOutputParser
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma
from langchain_google_genai import ChatGoogleGenerativeAI

# LangGraph imports
from langgraph.graph import StateGraph, END

# sentence-transformers import
from sentence_transformers import CrossEncoder

# --- CONFIGURATION (from RAG script) ---
DB1_PATH          = "vectorstore/db_chroma"
DB2_PATH          = "vectorstore1/db_chroma"
EMBEDDING_MODEL   = "thenlper/gte-small"
RERANKER_MODEL    = "BAAI/bge-reranker-base"
# IMPORTANT: Load API key securely in production (e.g., environment variable)
GEMINI_API_KEY    = "AIzaSyCgdlpsI4d6LiuDhx-8jJ_l3iU6MRtz6M4" # Replace or set env var
GEMINI_MODEL_NAME = "gemini-2.5-flash-preview-04-17"
TOP_K_RETRIEVAL   = 20
TOP_K_FINAL       = 5


# --- FastAPI Data Models --- (Keep as is)
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

# --- RAG Pipeline Initialization --- (Keep as is)
device = "cuda" if torch.cuda.is_available() else "cpu"
print(f"[INFO] Using device: {device}")
# Embeddings
embeddings = HuggingFaceEmbeddings(
    model_name=EMBEDDING_MODEL,
    model_kwargs={"device": device},
    encode_kwargs={"normalize_embeddings": True},
)
# Vector stores & retrievers
try:
    vs1 = Chroma(persist_directory=DB1_PATH, embedding_function=embeddings)
    retriever1 = vs1.as_retriever(search_type="similarity", search_kwargs={"k": TOP_K_RETRIEVAL})
    vs2 = Chroma(persist_directory=DB2_PATH, embedding_function=embeddings)
    retriever2 = vs2.as_retriever(search_type="similarity", search_kwargs={"k": TOP_K_RETRIEVAL})
    print("[INFO] Chroma databases loaded successfully.")
except Exception as e:
    print(f"[ERROR] Failed to load Chroma databases: {e}")
    print("Please ensure the vectorstore directories exist and contain valid data.")
    raise
# Reranker
try:
    cross_encoder = CrossEncoder(RERANKER_MODEL, device=device)
    print(f"[INFO] Reranker model '{RERANKER_MODEL}' loaded successfully.")
except Exception as e:
    print(f"[ERROR] Failed to load Reranker model: {e}")
    raise
# LLM
llm = ChatGoogleGenerativeAI(
    model=GEMINI_MODEL_NAME,
    google_api_key=GEMINI_API_KEY,
    temperature=0.0,
    convert_system_message_to_human=True,
)
# Prompt template
prompt_template = PromptTemplate(
    input_variables=["context", "question"],
    template=(
        "You are a helpful and knowledgeable programming assistant. You specialize in topics from Stack Overflow and MATLAB documentation. "
        "Use the provided context and info you have to answer the user's question.\n\n"
        "Only include MATLAB code when code is required. Ensure it is complete, runnable, and relevant.\n\n"
        "Instead of citing sources inline, list **all** cited source filenames at the end under a 'Sources:' section. "
        "Use the 'Source:' metadata from the context.\n\n"
        "Context:\n{context}\n\n"
        "Question:\n{question}\n\n"
        "Answer (only MATLAB code when needed; cite all sources at the end like: Sources: [filename.md, ...]):\n"
    ),
)

# --- LangGraph STATE DEFINITION --- (Keep as is)
class AgentState(TypedDict):
    question: str
    documents: List[Document]
    context: str
    answer: str
    history: List[str]

# --- LangGraph NODE FUNCTIONS --- (Keep as is)
def retrieve_docs(state: AgentState) -> Dict[str, Any]:
    print("--- Retrieving Documents ---")
    q = state["question"]
    docs1 = retriever1.get_relevant_documents(q)
    docs2 = retriever2.get_relevant_documents(q)
    unique_docs_dict = {d.page_content: d for d in (docs1 + docs2)}
    unique_docs_list = list(unique_docs_dict.values())
    print(f"Retrieved {len(docs1) + len(docs2)} docs, {len(unique_docs_list)} unique.")
    return {"documents": unique_docs_list}

def rerank_docs(state: AgentState) -> Dict[str, List[Document]]:
    print("--- Reranking Documents ---")
    docs = state["documents"]
    if not docs:
        print("No documents to rerank.")
        return {"documents": []}
    q = state["question"]
    pairs = [(q, d.page_content) for d in docs]
    try:
        scores = cross_encoder.predict(pairs, show_progress_bar=False)
        ranked = sorted(zip(docs, scores), key=lambda x: x[1], reverse=True)
        top_docs = [doc for doc, _ in ranked[:TOP_K_FINAL]]
        print(f"Reranked {len(docs)} docs, keeping top {len(top_docs)}.")
        return {"documents": top_docs}
    except Exception as e:
        print(f"[ERROR] Reranking failed: {e}")
        return {"documents": []}

def format_context(state: AgentState) -> Dict[str, str]:
    print("--- Formatting Context ---")
    history_text = "\n\n".join(state.get("history", []))
    docs = state["documents"]
    context_docs = "\n\n".join(
        f"Source: {d.metadata.get('source', 'unknown')}\n{d.page_content}"
        for d in docs
    )
    if not context_docs:
        context_docs = "No relevant documents found."
    full_context = history_text + "\n\n" + context_docs if history_text else context_docs
    return {"context": full_context.strip()}

def generate_answer(state: AgentState) -> Dict[str, str]:
    print("--- Generating Answer ---")
    chain = prompt_template | llm | StrOutputParser()
    try:
        output = chain.invoke({"context": state["context"], "question": state["question"]})
        print("LLM generation complete.")
        return {"answer": output}
    except Exception as e:
        print(f"[ERROR] LLM generation failed: {e}")
        return {"answer": "Sorry, I encountered an error while generating the answer."}

# --- LangGraph BUILD & COMPILE --- (Keep as is)
graph = StateGraph(state_schema=AgentState)
graph.add_node("retrieve", retrieve_docs)
graph.add_node("rerank", rerank_docs)
graph.add_node("format_context", format_context)
graph.add_node("generate", generate_answer)
graph.set_entry_point("retrieve")
graph.add_edge("retrieve", "rerank")
graph.add_edge("rerank", "format_context")
graph.add_edge("format_context", "generate")
graph.add_edge("generate", END)
rag_app = graph.compile()
print("[INFO] LangGraph RAG Application compiled successfully.")

# --- Helper Functions (Citation Processing) --- (Keep as is)
def extract_source_link(file_path):
    """Attempts to read the 'Source:' line from a markdown file."""
    try:
        if not os.path.exists(file_path):
             print(f"[WARN] Citation file not found: {file_path}")
             potential_path = os.path.join("Matlab-Docs", os.path.basename(file_path))
             if os.path.exists(potential_path):
                 file_path = potential_path
             else:
                 return None
        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f:
                if line.startswith("Source:"):
                    return line[len("Source:"):].strip()
    except Exception as e:
        print(f"[WARN] Error reading citation file {file_path}: {e}")
    return None

def citation(s: str) -> str:
    """Processes the generated answer to replace .md filenames with source links."""
    md_files = re.findall(r'\b[\w-]+\.md\b', s)
    if not md_files:
        return s
    print(f"--- Processing Citations: Found {md_files} ---")
    s = s.replace("Matlab-Docs/", "")
    cit_replacements = {}
    for md_file in set(md_files):
        replacement_target = md_file
        link = None
        if md_file == "cleaned_stack.md":
            link = "Stack Overflow"
        else:
            file_path = os.path.join("Matlab-Docs", md_file)
            link = extract_source_link(file_path)
            if link is None:
                 file_path_fallback = md_file
                 link = extract_source_link(file_path_fallback)
        cit_replacements[replacement_target] = link if link else md_file
        print(f"Citation mapping: {replacement_target} -> {cit_replacements[replacement_target]}")
    processed_s = s
    for old, new in cit_replacements.items():
        processed_s = processed_s.replace(old, new)
    return processed_s

# --- FastAPI Application Setup ---
# Using 'app' as the standard variable name now for simplicity and uvicorn compatibility
app = FastAPI(title="Flutter AI Toolkit Provider API - RAG Backend")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory store for chat histories
chat_histories: Dict[str, List[ChatMessage]] = {}

# --- FastAPI Endpoints ---

# ****** MODIFIED ENDPOINT: /generate ******
@app.post("/generate", response_model=Dict[str, str]) # Define response model for documentation
async def generate(request: GenerateRequest):
    """
    Implements the generate method (no history).
    Invokes the RAG pipeline and returns the full response as JSON.
    """
    print(f"\n--- Received /generate request ---")
    print(f"Prompt: {request.prompt[:100]}...")

    # Initialize state for the RAG pipeline (no history)
    state = {
        "question": request.prompt,
        "documents": [],
        "context": "",
        "answer": "",
        "history": []
    }

    try:
        # Run the RAG pipeline
        result = rag_app.invoke(state)

        # Process and apply citation formatting
        final_answer = citation(result.get("answer", "Error: No answer generated."))
        print(f"Final Answer (generate): {final_answer[:200]}...")

        # Return the complete answer in the desired JSON format
        return {"new_content": final_answer}

    except Exception as e:
        print(f"[ERROR] Error during /generate: {e}")
        # Return a JSON error response
        error_message = f"An error occurred during generation: {e}"
        # Use status_code 500 for internal server errors
        return JSONResponse(status_code=500, content={"error": error_message})


# ****** MODIFIED ENDPOINT: /send-message ******
@app.post("/send-message", response_model=Dict[str, str]) # Define response model
async def send_message(request: GenerateRequest, session_id: str = Query(...)):
    """
    Implements the sendMessage method (with history).
    Retrieves history, invokes RAG pipeline, updates history, and returns full response as JSON.
    """
    print(f"\n--- Received /send-message request ---")
    print(f"Session ID: {session_id}")
    print(f"Prompt: {request.prompt[:100]}...")

    # Initialize or retrieve history for this session
    if session_id not in chat_histories:
        chat_histories[session_id] = []

    # Prepare history for LangGraph AgentState
    formatted_history = []
    current_session_history = chat_histories[session_id]
    user_q = None
    for msg in current_session_history:
        if msg.role == "user":
            user_q = f"Q: {msg.content}"
        elif msg.role == "llm" and user_q:
            formatted_history.append(f"{user_q}\nA: {msg.content}")
            user_q = None

    # Add current user message to the FastAPI history store FIRST
    user_message = ChatMessage(role="user", content=request.prompt, attachments=request.attachments)
    chat_histories[session_id].append(user_message)

    # Initialize state for the RAG pipeline, including formatted history
    state = {
        "question": request.prompt,
        "documents": [],
        "context": "",
        "answer": "",
        "history": formatted_history # Pass the converted history (up to the previous turn)
    }

    try:
        # Run the RAG pipeline
        result = rag_app.invoke(state)

        # Process answer and apply citation formatting
        llm_answer_raw = result.get("answer", "Error: No answer generated.")
        final_answer = citation(llm_answer_raw)
        print(f"Final Answer (send-message): {final_answer[:200]}...")

        # Add LLM response to the FastAPI history store AFTER generation
        llm_message = ChatMessage(role="llm", content=final_answer)
        chat_histories[session_id].append(llm_message)

        # Return the complete answer in the desired JSON format
        return {"new_content": final_answer}

    except Exception as e:
        print(f"[ERROR] Error during /send-message: {e}")
        # Return a JSON error response
        error_message = f"An error occurred during message sending: {e}"
        # Use status_code 500 for internal server errors
        return JSONResponse(status_code=500, content={"error": error_message})


# --- History Endpoints (Keep as is) ---
@app.get("/history/{session_id}", response_model=Dict[str, List[ChatMessage]])
async def get_history(session_id: str):
    """
    Get the chat history for a session.
    """
    print(f"--- Received /history/{session_id} GET request ---")
    history = chat_histories.get(session_id, [])
    return {"history": history}

@app.put("/history/{session_id}")
async def set_history(session_id: str, history: List[ChatMessage]):
    """
    Set (overwrite) the chat history for a session.
    """
    print(f"--- Received /history/{session_id} PUT request ---")
    chat_histories[session_id] = history
    print(f"History set for session {session_id}. Length: {len(history)}")
    return {"success": True}

@app.delete("/history/{session_id}")
async def delete_history(session_id: str):
    """
    Delete the chat history for a session.
    """
    print(f"--- Received /history/{session_id} DELETE request ---")
    if session_id in chat_histories:
        del chat_histories[session_id]
        print(f"History deleted for session {session_id}.")
        return {"success": True}
    else:
        print(f"Session {session_id} not found for deletion.")
        raise HTTPException(status_code=404, detail="Session not found")


# --- Server Execution ---
if __name__ == "__main__":
    print("[INFO] Starting FastAPI server...")
    # Use the standard 'app' variable and the string format for uvicorn runner
    # This makes it compatible with both `python script.py` and `uvicorn script:app`
    # Get the filename dynamically
    module_name = os.path.splitext(os.path.basename(__file__))[0]
    uvicorn.run(f"{module_name}:app", host="0.0.0.0", port=8001, reload=True)
    # Alternatively, if only running via `python script.py`:
    # uvicorn.run(app, host="0.0.0.0", port=8000)
