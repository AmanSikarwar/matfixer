# agents/rag_solution/nodes.py
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

# --- CONFIGURATION (Copied from root_cause, could be centralized) ---
DB1_PATH = os.getenv("DB1_PATH", "vectorstore/db_chroma")
DB2_PATH = os.getenv("DB2_PATH", "vectorstore1/db_chroma")
EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "thenlper/gte-small")
RERANKER_MODEL = os.getenv("RERANKER_MODEL", "BAAI/bge-reranker-base")
TOP_K_RETRIEVAL = int(os.getenv("TOP_K_RETRIEVAL", 20))
TOP_K_FINAL = int(os.getenv("TOP_K_FINAL", 5))

# --- RAG Component Initialization (Copied from root_cause) ---
# In a larger app, centralize this initialization
try:
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"[INFO RagSolution] Using device: {device}")

    embeddings = HuggingFaceEmbeddings(
        model_name=EMBEDDING_MODEL,
        model_kwargs={"device": device},
        encode_kwargs={"normalize_embeddings": True},
    )

    vs1 = Chroma(persist_directory=DB1_PATH, embedding_function=embeddings)
    retriever1 = vs1.as_retriever(search_type="similarity", search_kwargs={"k": TOP_K_RETRIEVAL})
    vs2 = Chroma(persist_directory=DB2_PATH, embedding_function=embeddings)
    retriever2 = vs2.as_retriever(search_type="similarity", search_kwargs={"k": TOP_K_RETRIEVAL})

    print(f"[INFO RagSolution] Initializing reranker: {RERANKER_MODEL}")
    cross_encoder = CrossEncoder(RERANKER_MODEL, device=device)
    print("[INFO RagSolution] RAG Components Initialized.")

except Exception as e:
    print(f"[ERROR RagSolution] Failed to initialize RAG components: {e}")
    traceback.print_exc()
    embeddings = retriever1 = retriever2 = cross_encoder = None

# --- Helper Functions (Copied from root_cause) ---
# Ideally, put these in a shared utility file
def retrieve_docs_for_node(question: str) -> List[Document]:
    if not retriever1 or not retriever2: return []
    try:
        docs1 = retriever1.get_relevant_documents(question)
        docs2 = retriever2.get_relevant_documents(question)
        unique = {d.page_content: d for d in (docs1 + docs2)}
        print(f"[INFO RagSolution] Retrieved {len(unique)} unique docs.")
        return list(unique.values())
    except Exception as e: print(f"[ERROR RagSolution] Retrieval failed: {e}"); return []

def rerank_docs_for_node(query: str, docs: List[Document]) -> List[Document]:
    if not cross_encoder or not docs: return docs
    try:
        pairs = [(query, d.page_content) for d in docs]
        scores = cross_encoder.predict(pairs, show_progress_bar=False)
        ranked = sorted(zip(docs, scores), key=lambda x: x[1], reverse=True)
        top_docs = [doc for doc, _ in ranked[:TOP_K_FINAL]]
        print(f"[INFO RagSolution] Reranked to top {len(top_docs)} docs.")
        return top_docs
    except Exception as e: print(f"[ERROR RagSolution] Reranking failed: {e}"); return docs[:TOP_K_FINAL]

def format_context_for_node(docs: List[Document]) -> str:
    if not docs: return "No relevant documents found in the knowledge base."
    context = "\n\n".join(
        f"Source Document {i+1}:\n{d.page_content}"
        for i, d in enumerate(docs)
    )
    return context

# --- Solution Prompt ---
SOLUTION_PROMPT = PromptTemplate(
    input_variables=["context", "question"],
    template=(
        "You are a helpful assistant knowledgeable in programming, particularly topics covered in "
        "Stack Overflow and MATLAB documentation. Use the following retrieved excerpts and your knowledge to answer the user's question concisely in about 20-25 lines.\n\n"
        "Retrieved Documents:\n{context}\n\n"
        "User's Question:\n{question}\n\n"
        "Answer based on Documents:"
    ),
)

# --- Solution RAG Node ---
def find_solution_rag(state: AppState) -> Dict[str, Any]:
    """
    Finds a solution to the user's query using RAG against ChromaDBs.
    """
    print("--- Node: Finding Solution (RAG ChromaDB) ---")
    query = state['query']
    current_error = state.get('error')

    # Allow running even if root cause had non-critical error
    # Only skip if RAG components failed init or critical upstream error
    if not all([embeddings, retriever1, retriever2, cross_encoder, llm]):
         error_msg = "RAG components (embeddings, retriever, reranker, llm) failed to initialize."
         print(f"[ERROR RagSolution] {error_msg}")
         # Don't overwrite critical upstream error if it exists
         final_error = current_error if current_error else error_msg
         return {"rag_solution": None, "error": final_error}

    try:
        # 1. Retrieve
        retrieved_docs = retrieve_docs_for_node(query)

        # 2. Rerank
        reranked_docs = rerank_docs_for_node(query, retrieved_docs)

        # 3. Format Context
        formatted_context = format_context_for_node(reranked_docs)

        # 4. Generate Solution
        rag_chain = (
            {"context": lambda x: x["context"], "question": lambda x: x["question"]}
            | SOLUTION_PROMPT
            | llm
            | StrOutputParser()
        )

        print("[INFO RagSolution] Invoking LLM for RAG solution...")
        solution = rag_chain.invoke({"context": formatted_context, "question": query})
        print("[INFO RagSolution] RAG Solution Generation Complete.")

        # Keep potential previous non-critical errors
        return {"rag_solution": solution}

    except Exception as e:
        error_msg = f"Error during RAG solution node: {e}"
        print(f"[ERROR RagSolution] {error_msg}")
        traceback.print_exc()
        final_error = current_error if current_error else error_msg
        return {"rag_solution": None, "error": final_error}