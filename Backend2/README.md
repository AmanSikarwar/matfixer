# MatFixer - Backend 2

This backend service provides a simpler Retrieval-Augmented Generation (RAG) pipeline for answering MATLAB-related queries. It uses LangGraph (defined within the API file), FastAPI, ChromaDB, and the Google Gemini LLM.

## Architecture

This backend implements a straightforward RAG workflow using LangGraph:

1. **`retrieve` (Node):**
    * Takes the user `question`.
    * Retrieves relevant documents from two ChromaDB vector stores (`vectorstore/db_chroma` and `vectorstore1/db_chroma`) using `thenlper/gte-small` embeddings.
    * Deduplicates retrieved documents.
2. **`rerank` (Node):**
    * Takes the retrieved `documents` and the `question`.
    * Reranks the documents using a CrossEncoder model (`BAAI/bge-reranker-base`) to prioritize the most relevant ones.
3. **`format_context` (Node):**
    * Takes the reranked `documents`.
    * Formats the content and source metadata of the top documents into a context string suitable for the LLM prompt. Optionally includes chat `history`.
4. **`generate` (Node):**
    * Takes the formatted `context` and the original `question`.
    * Uses a Google Gemini LLM (`gemini-2.5-flash-preview-04-17`) via `ChatGoogleGenerativeAI` and a specific prompt template to generate an answer.
    * The prompt instructs the LLM to act as a programming assistant, use the context, only include MATLAB code when necessary, and cite sources at the end.

The LangGraph definition (`AgentState`, nodes, edges) is contained within the `chat_api2.py` file. The service also includes citation processing logic (`citation` function) to replace source filenames (`.md`) in the LLM response with actual source links read from the markdown files.

**Note:** `smartapi.py` appears to be a very similar implementation, potentially an alternative endpoint running on port 8001, returning a slightly different JSON structure (`{"new_content": ...}`). The main Flutter app seems configured to use the endpoints from `chat_api2.py` on port 8002.

## API

The FastAPI application (`chat_api2.py`) provides the following endpoints:

* `POST /generate`: Takes a `GenerateRequest` (`{"prompt": "...", "attachments": [...]}`) and runs the RAG workflow (ignoring attachments and history). Returns a `GenerateResponse` (`{"response": "..."}`).
* `POST /send-message`: Takes a `GenerateRequest` and a `session_id` query parameter. Manages chat history in memory (`chat_histories`). Runs the RAG workflow, potentially including history in the context (though the `format_context` node needs adjustment to use the passed history). Updates the in-memory history and returns a `GenerateResponse`.
* `GET /history/{session_id}`: Retrieves chat history for a given session (managed in memory by FastAPI).
* `PUT /history/{session_id}`: Sets chat history for a given session (managed in memory by FastAPI).

Request/Response models are defined within `chat_api2.py`.

## Setup

1. **Create Virtual Environment:**

    ```bash
    python -m venv venv
    source venv/bin/activate  # Linux/macOS
    # venv\Scripts\activate  # Windows
    ```

2. **Install Dependencies:**

    ```bash
    pip install -r requirements.txt
    ```

3. **API Key:**
    * **IMPORTANT:** This backend currently has the Google Gemini API Key **hardcoded** in `chat_api2.py` and `smartapi.py`. This is **not recommended** for production.
    * **Recommendation:** Modify the code to load the `GEMINI_API_KEY` from an environment variable (e.g., using `python-dotenv` like Backend1) and set it in your environment or a `.env` file.

    ```python
    # Example modification in chat_api2.py (around line 39)
    # import os
    # from dotenv import load_dotenv
    # load_dotenv()
    # GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
    # if not GEMINI_API_KEY:
    #     print("[ERROR] GEMINI_API_KEY not found in environment variables!")
    #     # Handle error appropriately, e.g., raise Exception or exit
    ```

4. **ChromaDB Setup:** Ensure the ChromaDB vector stores at `vectorstore/db_chroma` and `vectorstore1/db_chroma` exist and contain the necessary embeddings for MATLAB documentation and Stack Overflow data. These need to be created separately.
5. **Citation Files:** Ensure the markdown source files (e.g., within a `Matlab-Docs` directory relative to where the script is run) are available for the `citation` function to read source links from.

## Running

```bash
uvicorn chat_api2:app --host 0.0.0.0 --port 8002 --reload
```

The API will be available at `http://localhost:8002`.

*(If using `smartapi.py`, run `uvicorn smartapi:app --host 0.0.0.0 --port 8001 --reload`)*

## Key Dependencies

* `fastapi`: Web framework
* `uvicorn`: ASGI server
* `langgraph`: Agent orchestration
* `langchain`, `langchain-community`, `langchain-core`, `langchain-google-genai`, `langchain-huggingface`: Core LangChain components, LLM integrations, embedding models
* `langchain-chroma`: ChromaDB integration
* `sentence-transformers`: For embeddings and reranking
* `torch`: Required by sentence-transformers
