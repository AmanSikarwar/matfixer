# agents/rag_root_cause/nodes.py
import os
import torch
import traceback
from typing import Dict, Any, List, Sequence
from operator import itemgetter

# LangChain / Chroma / Gemini imports
from langchain_core.prompts import PromptTemplate
from langchain_core.documents import Document
from langchain_core.output_parsers import StrOutputParser
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma
from langchain_core.runnables import RunnableLambda, RunnableParallel, RunnablePassthrough

# sentence-transformers import
from sentence_transformers import CrossEncoder

# Local Imports
from gen_models.llm import llm # Use the shared Gemini LLM
from graph.state import AppState

# --- CONFIGURATION (from .env or defaults) ---
DB1_PATH = os.getenv("DB1_PATH", "vectorstore/db_chroma")
DB2_PATH = os.getenv("DB2_PATH", "vectorstore1/db_chroma")
EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "thenlper/gte-small")
RERANKER_MODEL = os.getenv("RERANKER_MODEL", "BAAI/bge-reranker-base")
TOP_K_RETRIEVAL = int(os.getenv("TOP_K_RETRIEVAL", 20))
TOP_K_FINAL = int(os.getenv("TOP_K_FINAL", 5))

# --- RAG Component Initialization ---
try:
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"[INFO RagRootCause] Using device: {device}")

    embeddings = HuggingFaceEmbeddings(
        model_name=EMBEDDING_MODEL,
        model_kwargs={"device": device},
        encode_kwargs={"normalize_embeddings": True},
    )

    vs1 = Chroma(persist_directory=DB1_PATH, embedding_function=embeddings)
    retriever1 = vs1.as_retriever(search_type="similarity", search_kwargs={"k": TOP_K_RETRIEVAL})
    vs2 = Chroma(persist_directory=DB2_PATH, embedding_function=embeddings)
    retriever2 = vs2.as_retriever(search_type="similarity", search_kwargs={"k": TOP_K_RETRIEVAL})

    print(f"[INFO RagRootCause] Initializing reranker: {RERANKER_MODEL}")
    cross_encoder = CrossEncoder(RERANKER_MODEL, device=device)
    print("[INFO RagRootCause] RAG Components Initialized.")

except Exception as e:
    print(f"[ERROR RagRootCause] Failed to initialize RAG components: {e}")
    traceback.print_exc()
    # Set components to None to indicate failure? Or raise error?
    # For now, let the node fail later if components are None.
    embeddings = retriever1 = retriever2 = cross_encoder = None

# --- Helper Functions (Adapted from your RAG code) ---
def retrieve_docs_for_node(question: str) -> List[Document]:
    """Retrieves and dedupes documents from both stores."""
    if not retriever1 or not retriever2:
        print("[WARN RagRootCause] Retrievers not initialized.")
        return []
    try:
        docs1 = retriever1.get_relevant_documents(question)
        docs2 = retriever2.get_relevant_documents(question)
        unique = {d.page_content: d for d in (docs1 + docs2)}
        print(f"[INFO RagRootCause] Retrieved {len(unique)} unique docs for query.")
        return list(unique.values())
    except Exception as e:
        print(f"[ERROR RagRootCause] Retrieval failed: {e}")
        traceback.print_exc()
        return []

def rerank_docs_for_node(query: str, docs: List[Document]) -> List[Document]:
    """Reranks documents using CrossEncoder."""
    if not cross_encoder or not docs:
        return docs # Return original if no reranker or no docs
    try:
        pairs = [(query, d.page_content) for d in docs]
        scores = cross_encoder.predict(pairs, show_progress_bar=False)
        ranked = sorted(zip(docs, scores), key=lambda x: x[1], reverse=True)
        top_docs = [doc for doc, _ in ranked[:TOP_K_FINAL]]
        print(f"[INFO RagRootCause] Reranked to top {len(top_docs)} docs.")
        return top_docs
    except Exception as e:
        print(f"[ERROR RagRootCause] Reranking failed: {e}")
        traceback.print_exc()
        return docs[:TOP_K_FINAL] # Fallback: return top K original docs

def format_context_for_node(docs: List[Document]) -> str:
    """Formats documents into a context string."""
    if not docs:
        return "No relevant documents found in the knowledge base."
    context = "\n\n".join(
        f"Source Document {i+1}:\n{d.page_content}" # Simplified source naming
        # f"Source: {d.metadata.get('source','unknown')}\n{d.page_content}" # Original source if needed
        for i, d in enumerate(docs)
    )
    return context

# --- Root Cause Prompt ---
ROOT_CAUSE_PROMPT = PromptTemplate(
    input_variables=["context", "question"],
    template=(
        "You are an expert analyst. Based on the following retrieved documents from our knowledge base, "
        "identify the most likely underlying problem, question, or root cause behind the user's original query. "
        "Explain the core issue according to the provided documents in about 10 lines. Do not provide a solution.\n\n"
        "Retrieved Documents:\n{context}\n\n"
        "User's Original Query:\n{question}\n\n"
        "Root Cause Analysis based on Documents:"
    ),
)

# --- Root Cause RAG Node ---
def analyze_root_cause_rag(state: AppState) -> Dict[str, Any]:
    """
    Analyzes the user's query using RAG against ChromaDBs to determine root cause.
    """
    print("--- Node: Analyzing Root Cause (RAG ChromaDB) ---")
    query = state['query']
    current_error = state.get('error')

    if current_error: # Skip if critical upstream error occurred
        print(f"Skipping RAG root cause analysis due to previous error: {current_error}")
        return {"rag_root_cause_analysis": None}

    if not all([embeddings, retriever1, retriever2, cross_encoder, llm]):
         error_msg = "RAG components (embeddings, retriever, reranker, llm) failed to initialize."
         print(f"[ERROR RagRootCause] {error_msg}")
         return {"rag_root_cause_analysis": None, "error": error_msg}

    try:
        # 1. Retrieve
        retrieved_docs = retrieve_docs_for_node(query)

        # 2. Rerank
        reranked_docs = rerank_docs_for_node(query, retrieved_docs)

        # 3. Format Context
        formatted_context = format_context_for_node(reranked_docs)

        # 4. Generate Root Cause Analysis
        rag_chain = (
            {"context": lambda x: x["context"], "question": lambda x: x["question"]} # Prepare input dict
            | ROOT_CAUSE_PROMPT
            | llm
            | StrOutputParser()
        )

        print("[INFO RagRootCause] Invoking LLM for RAG root cause...")
        analysis = rag_chain.invoke({"context": formatted_context, "question": query})
        print("[INFO RagRootCause] RAG Root Cause Analysis Complete.")

        return {"rag_root_cause_analysis": analysis} # Keep potential previous non-critical errors

    except Exception as e:
        error_msg = f"Error during RAG root cause analysis node: {e}"
        print(f"[ERROR RagRootCause] {error_msg}")
        traceback.print_exc()
        final_error = current_error if current_error else error_msg
        return {"rag_root_cause_analysis": None, "error": final_error}