# MatFixer - Backend 1

This backend service implements the primary, more complex agentic workflow for the MatFixer application using LangGraph, FastAPI, ChromaDB, Groq, and Tavily Search. It analyzes user queries about MATLAB problems, performs Retrieval-Augmented Generation (RAG) and web searches, and synthesizes a comprehensive report.

## Architecture

This backend uses LangGraph to orchestrate a sequence of specialized agents:

1. **`analyze_rag_root_cause` (Node):**
    * Takes the user `query`.
    * Performs RAG using ChromaDB (containing MATLAB docs & Stack Overflow data) and a CrossEncoder reranker (`BAAI/bge-reranker-base`).
    * Uses a Groq LLM (`gen_models/llm.py`) to analyze the retrieved context and identify the potential root cause of the problem.
    * Defined in `agents/rag_root_cause/nodes.py`.
2. **`find_rag_solution` (Node):**
    * Takes the user `query`.
    * Performs a similar RAG process as the root cause node against the same ChromaDB stores.
    * Uses the Groq LLM to generate a potential solution based on the retrieved documents.
    * Defined in `agents/rag_solution/nodes.py`.
3. **`execute_web_search` (Node):**
    * Takes the user `query`.
    * Uses a ReAct agent (`langgraph.prebuilt.create_react_agent`) powered by a Groq LLM (`llama3-70b-8192`) and the Tavily Search tool (`TavilySearchResults`).
    * Searches the web for relevant information and summarizes the findings.
    * Defined in `agents/web_searcher/nodes.py`.
4. **`synthesize_final_report` (Node):**
    * Receives the `query`, `rag_root_cause_analysis`, `rag_solution`, and `web_search_result`.
    * Uses the Groq LLM to synthesize these inputs into a final, structured Markdown report containing Problem Description, Root Cause Analysis, and Proposed Solution/Findings.
    * Defined in `agents/synthesizer/nodes.py`.

The overall workflow and state management are defined in:

* `graph/graph.py`: Defines the LangGraph structure, nodes, and edges.
* `graph/state.py`: Defines the `AppState` TypedDict which carries data between nodes.

The service exposes its functionality via a FastAPI application.

## API

The FastAPI application (`chat_api1.py`) provides the following main endpoints:

* `POST /invoke`: (Legacy?) Takes a `QueryRequest` (`{"query": "..."}`) and runs the full LangGraph workflow, returning a `ReportResponse` (`{"query": "...", "report": "...", "error": "..."}`).
* `POST /generate`: Takes a `GenerateRequest` (`{"prompt": "...", "attachments": [...]}`) and runs the workflow (ignoring attachments for now), returning a `GenerateResponse` (`{"response": "..."}` containing the final report). This endpoint does not use chat history.
* `POST /send-message`: Similar to `/generate` but takes a `session_id` query parameter. It's intended for chat interactions but currently doesn't seem to leverage the history stored in `chat_histories` within the LangGraph state itself (history is managed locally in the API handler). Returns `GenerateResponse`.
* `GET /history/{session_id}`: Retrieves chat history for a given session (managed in memory by FastAPI).
* `PUT /history/{session_id}`: Sets chat history for a given session (managed in memory by FastAPI).
* `GET /`: Root endpoint with a welcome message.

Request/Response models are defined in `api_models.py` and `chat_api1.py`.

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

3. **Environment Variables:** Create a `.env` file in the `Backend1` directory with the following keys:

    ```dotenv
    GROQ_API_KEY=your_groq_api_key
    TAVILY_API_KEY=your_tavily_api_key

    # Optional: Specify ChromaDB paths if different from defaults
    # DB1_PATH=path/to/vectorstore/db_chroma
    # DB2_PATH=path/to/vectorstore1/db_chroma

    # Optional: Specify embedding/reranker models if different
    # EMBEDDING_MODEL=thenlper/gte-small
    # RERANKER_MODEL=BAAI/bge-reranker-base

    # Optional: Specify Groq model name
    # GROQ_MODEL_NAME=llama3-70b-8192
    ```

4. **ChromaDB Setup:** Ensure the ChromaDB vector stores specified by `DB1_PATH` and `DB2_PATH` exist and contain the necessary embeddings for MATLAB documentation and Stack Overflow data. These databases need to be created separately (e.g., using a data ingestion script not included in this structure).

## Running

```bash
uvicorn chat_api1:app --host 0.0.0.0 --port 8000 --reload
```

The API will be available at `http://localhost:8000`.

## Key Dependencies

* `fastapi`: Web framework
* `uvicorn`: ASGI server
* `langgraph`: Agent orchestration
* `langchain`, `langchain-community`, `langchain-core`, `langchain-groq`, `langchain-huggingface`: Core LangChain components, LLM integrations, and embedding models
* `langchain-chroma`: ChromaDB integration
* `sentence-transformers`: For embeddings and reranking
* `torch`: Required by sentence-transformers
* `python-dotenv`: For loading environment variables
* `tavily-python`: For Tavily Search tool (via langchain)
