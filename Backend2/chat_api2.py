#!/usr/bin/env python3
import os
import torch
from typing import List, Dict, Any, Literal, Optional
from typing_extensions import TypedDict
from operator import itemgetter
import re
import json
import asyncio
import uvicorn

# FastAPI imports
from fastapi import FastAPI, Query, HTTPException
from fastapi.responses import StreamingResponse
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
# from langchain_core.runnables import RunnableLambda # Not strictly needed for the final graph structure

# sentence-transformers import
from sentence_transformers import CrossEncoder

# --- CONFIGURATION (from RAG script) ---
DB1_PATH          = "vectorstore/db_chroma"
DB2_PATH          = "vectorstore1/db_chroma"
EMBEDDING_MODEL   = "thenlper/gte-small"
RERANKER_MODEL    = "BAAI/bge-reranker-base"
# IMPORTANT: Load API key securely in production (e.g., environment variable)
GEMINI_API_KEY    = "AIzaSyCgdlpsI4d6LiuDhx-8jJ_l3iU6MRtz6M4"
GEMINI_MODEL_NAME = "gemini-2.5-flash-preview-04-17"
TOP_K_RETRIEVAL   = 20
TOP_K_FINAL       = 5


# --- FastAPI Data Models ---
class Attachment(BaseModel):
    type: str  # Could be "image", "text", etc.
    data: str  # Base64 encoded data or text content

class ChatMessage(BaseModel):
    role: Literal["user", "llm"]
    content: str
    attachments: List[Attachment] = []

class GenerateRequest(BaseModel):
    prompt: str
    attachments: List[Attachment] = [] # Note: RAG pipeline doesn't currently handle attachments

class GenerateResponse(BaseModel):
    response: str

# --- RAG Pipeline Initialization ---
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
    # Depending on the desired behavior, you might want to exit or handle this differently.
    # For now, we'll raise the exception to halt execution if DBs are essential.
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

# --- LangGraph STATE DEFINITION ---
class AgentState(TypedDict):
    question: str
    documents: List[Document]
    context: str
    answer: str
    history: List[str] # Expects history as list of "Q: ... \nA: ..." strings

# --- LangGraph NODE FUNCTIONS ---
def retrieve_docs(state: AgentState) -> Dict[str, Any]:
    print("--- Retrieving Documents ---")
    q = state["question"]
    docs1 = retriever1.get_relevant_documents(q)
    docs2 = retriever2.get_relevant_documents(q)
    # Combine and deduplicate based on page content
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
        # Fallback: return original top K if reranking fails? Or return empty?
        # Returning the original top K might be safer.
        # return {"documents": docs[:TOP_K_FINAL]}
        return {"documents": []} # Or return empty to indicate failure


def format_context(state: AgentState) -> Dict[str, str]:
    print("--- Formatting Context ---")
    # Join the history strings (already formatted)
    history_text = "\n\n".join(state.get("history", []))

    docs = state["documents"]
    context_docs = "\n\n".join(
        # Ensure metadata and source exist gracefully
        f"Source: {d.metadata.get('source', 'unknown')}\n{d.page_content}"
        for d in docs
    )
    if not context_docs:
        context_docs = "No relevant documents found."

    # Combine history and current docs context
    full_context = history_text + "\n\n" + context_docs if history_text else context_docs
    # print(f"Full Context for LLM:\n{full_context[:500]}...") # Print beginning of context for debugging
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

# --- LangGraph BUILD & COMPILE ---
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

# Compile the graph
rag_app = graph.compile()
print("[INFO] LangGraph RAG Application compiled successfully.")

# --- Helper Functions (Citation Processing) ---
def extract_source_link(file_path):
    """Attempts to read the 'Source:' line from a markdown file."""
    try:
        # Ensure the path exists relative to the script or use absolute paths
        if not os.path.exists(file_path):
             print(f"[WARN] Citation file not found: {file_path}")
             # Try looking relative to Matlab-Docs if it's missing
             potential_path = os.path.join("Matlab-Docs", os.path.basename(file_path))
             if os.path.exists(potential_path):
                 file_path = potential_path
             else:
                 return None # File not found

        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f:
                if line.startswith("Source:"):
                    return line[len("Source:"):].strip()
    except Exception as e:
        print(f"[WARN] Error reading citation file {file_path}: {e}")
    return None

def citation(s: str) -> str:
    """Processes the generated answer to replace .md filenames with source links."""
    # Find potential markdown filenames (simple pattern)
    md_files = re.findall(r'\b[\w-]+\.md\b', s) # Allow hyphens in filenames
    if not md_files:
        return s # No citations found

    print(f"--- Processing Citations: Found {md_files} ---")
    s = s.replace("Matlab-Docs/", "") # Clean up potential path prefix in the text
    cit_replacements = {} # Store replacements {old: new}

    for md_file in set(md_files): # Process unique filenames
        replacement_target = md_file # The string to replace in the answer
        link = None
        if md_file == "cleaned_stack.md":
            link = "Stack Overflow" # Special case
        else:
            # Assume files are relative to a 'Matlab-Docs' directory or script location
            file_path = os.path.join("Matlab-Docs", md_file)
            link = extract_source_link(file_path)
            if link is None:
                 # Try finding the file in the current directory as a fallback
                 file_path_fallback = md_file
                 link = extract_source_link(file_path_fallback)


        # Use the original filename if no link is found
        cit_replacements[replacement_target] = link if link else md_file
        print(f"Citation mapping: {replacement_target} -> {cit_replacements[replacement_target]}")

    # Replace all occurrences using the gathered replacements
    processed_s = s
    # Be careful with replacement order if filenames are substrings of others
    # Replacing longer matches first might be safer, but unlikely with .md
    for old, new in cit_replacements.items():
        processed_s = processed_s.replace(old, new)

    return processed_s

# --- FastAPI Application Setup ---
app = FastAPI(title="Flutter AI Toolkit Provider API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Store for chat history
chat_histories = {}

@app.post("/generate", response_model=GenerateResponse)
async def generate(request: GenerateRequest):
    """
    Non-streaming implementation of generateStream
    """
    # Initialize state for your RAG pipeline
    state = {"question": request.prompt, "documents": [], "context": "", "answer": ""}
    
    # Run the RAG pipeline
    result = rag_app.invoke(state)
    
    # Process and apply citation formatting
    answer = citation(result["answer"])
    
    return GenerateResponse(response=answer)

@app.post("/send-message", response_model=GenerateResponse)
async def send_message(request: GenerateRequest, session_id: str = Query(...)):
    """
    Non-streaming implementation of sendMessageStream
    """
    # Initialize history for this session if needed
    if session_id not in chat_histories:
        chat_histories[session_id] = []
    
    # Add user message to history
    chat_histories[session_id].append(
        ChatMessage(role="user", content=request.prompt, attachments=request.attachments)
    )
    
    # Initialize state for the RAG pipeline
    state = {"question": request.prompt, "documents": [], "context": "", "answer": ""}
    
    # Use the existing RAG pipeline
    result = rag_app.invoke(state)
    answer = citation(result["answer"])
    
    # Add LLM response to history
    chat_histories[session_id].append(
        ChatMessage(role="llm", content=answer)
    )
    
    return GenerateResponse(response=answer)

@app.get("/history/{session_id}")
async def get_history(session_id: str):
    """
    Get the chat history for a session
    """
    if session_id not in chat_histories:
        return {"history": []}
    
    return {"history": chat_histories[session_id]}

@app.put("/history/{session_id}")
async def set_history(session_id: str, history: List[ChatMessage]):
    """
    Set the chat history for a session
    """
    chat_histories[session_id] = history
    return {"success": True}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8002)
