# agents/web_searcher/nodes.py
import os
import traceback
from typing import Dict, Any, List, Optional

from dotenv import load_dotenv

# LangChain / LangGraph / External API imports
from langchain_groq import ChatGroq
from langchain_community.tools.tavily_search import TavilySearchResults
from langgraph.prebuilt import create_react_agent
from langchain_core.messages import HumanMessage, AIMessage, BaseMessage

# Local Imports
from graph.state import AppState # Assuming your AppState is in graph/state.py

# --- Environment & API Key Loading ---
load_dotenv() # Load variables from .env file

GROQ_API_KEY = os.environ.get("GROQ_API_KEY")
TAVILY_API_KEY = os.environ.get("TAVILY_API_KEY")

# --- Agent Component Initialization ---
web_llm = None
search_tool = None
web_agent_executor = None
initialization_error = None

system_prompt="""
You are an AI system. I will provide you with text retrieved from multiple web sources related to a user query. 
Your task is to analyze the retrieved content and generate a concise summary in about 15-20 lines that directly answers the user's query based on the 
information provided.
"""

try:
    if not GROQ_API_KEY:
        raise ValueError("GROQ_API_KEY not found in environment variables.")
    if not TAVILY_API_KEY:
        raise ValueError("TAVILY_API_KEY not found in environment variables.")
    print("[INFO WebSearcher] Initializing Groq LLM...")
    web_llm = ChatGroq(model="llama3-70b-8192", groq_api_key=GROQ_API_KEY) # Adjusted model name based on common Groq offerings

    # Initialize the Search Tool
    print("[INFO WebSearcher] Initializing Tavily Search Tool...")
    search_tool = TavilySearchResults(max_results=4, tavily_api_key=TAVILY_API_KEY)
    tools = [search_tool]

    print("[INFO WebSearcher] Creating ReAct Agent Executor...")
    web_agent_executor = create_react_agent(model=web_llm, tools=tools,state_modifier=system_prompt)
    print("[INFO WebSearcher] Web Searcher Agent Components Initialized.")

except Exception as e:
    initialization_error = f"Failed to initialize Web Searcher components: {e}"
    print(f"[ERROR WebSearcher] {initialization_error}")
    traceback.print_exc()

# --- Web Searcher Node ---
def search_web_for_query(state: AppState) -> Dict[str, Any]:
    """
    Uses a ReAct agent with Tavily Search to find information related to the query online.
    """
    print("--- Node: Searching Web (Tavily ReAct Agent) ---")
    query = state['query']
    current_error = state.get('error')

    # If initialization failed, prevent execution and report error
    if initialization_error:
        print(f"[ERROR WebSearcher] Skipping node execution due to initialization error: {initialization_error}")
        # Don't overwrite a critical upstream error if it exists
        final_error = current_error if current_error else initialization_error
        return {"web_search_result": None, "error": final_error}

    # Skip if critical upstream error occurred (optional, depends on desired graph flow)
    # if current_error:
    #     print(f"Skipping web search due to previous error: {current_error}")
    #     return {"web_search_result": None}

    if not web_agent_executor:
         # This case should ideally be caught by initialization_error check, but belts and suspenders
         error_msg = "Web agent executor is not available."
         print(f"[ERROR WebSearcher] {error_msg}")
         final_error = current_error if current_error else error_msg
         return {"web_search_result": None, "error": final_error}

    try:
        print(f"[INFO WebSearcher] Invoking agent for query: '{query}'")
        # The ReAct agent expects input in the format {"messages": [BaseMessage(...)]}
        agent_input = {"messages": [HumanMessage(content=query)]}
        response = web_agent_executor.invoke(agent_input)

        # Extract the final response from the agent's messages
        messages: List[BaseMessage] = response.get("messages", [])
        final_answer = None
        # The final answer is typically the last AIMessage in the sequence
        for message in reversed(messages):
            if isinstance(message, AIMessage):
                final_answer = message.content
                break

        if final_answer:
            print("[INFO WebSearcher] Web search completed successfully.")
            # Ensure previous non-critical errors are preserved if necessary
            return {"web_search_result": final_answer}
        else:
            print("[WARN WebSearcher] Agent finished but no final AIMessage found in response.")
            # Decide how to handle this - maybe return None or a specific message
            return {"web_search_result": "Agent did not produce a final answer."} # Or None

    except Exception as e:
        error_msg = f"Error during web search node execution: {e}"
        print(f"[ERROR WebSearcher] {error_msg}")
        traceback.print_exc()
        final_error = current_error if current_error else error_msg
        return {"web_search_result": None, "error": final_error}