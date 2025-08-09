# # agents/synthesizer/nodes.py
# import traceback
# from typing import Dict, Any, Optional

# # LangChain imports
# from langchain_core.prompts import PromptTemplate
# from langchain_core.output_parsers import StrOutputParser

# # Local Imports
# # Assuming the Gemini LLM is initialized in a shared place, like the scraper_synthesizer agent
# # If not, you might need to initialize it here or pass it during graph setup.
# # Let's assume it's importable like this for now:
# try:
#     from gen_models.llm import llm as synthesizer_llm
# except ImportError:
#     print("[ERROR Synthesizer] Failed to import shared LLM.")
#     synthesizer_llm = None

# from graph.state import AppState

# # --- Synthesis Prompt ---
# SYNTHESIS_PROMPT = PromptTemplate(
#     input_variables=["query", "root_cause", "rag_solution", "web_search_results"],
#     template=(
#         "You are an expert technical analyst tasked with creating a comprehensive report based on internal analysis and web research.\n\n"
#         "Synthesize the information gathered from the following sources into a single, well-structured report. The report should clearly outline:\n"
#         "1.  **Problem Description:** Briefly restate the user's original query or problem.\n"
#         "2.  **Root Cause Analysis:** Summarize the findings from the internal knowledge base regarding the underlying cause.\n"
#         "3.  **Proposed Solution / Findings:** Combine insights from the internal knowledge base solution and the web search results. Provide a clear, actionable solution or explanation. If findings conflict, acknowledge it and offer the most plausible interpretation.\n\n"
#         "--- INPUTS ---\n\n"
#         "**Original User Query:**\n{query}\n\n"
#         "**Internal Root Cause Analysis:**\n{root_cause}\n\n"
#         "**Internal Knowledge Base Solution Suggestion:**\n{rag_solution}\n\n"
#         "**Web Search Findings:**\n{web_search_results}\n\n"
#         "--- END INPUTS ---\n\n"
#         "**Comprehensive Report:**"
#     ),  
# )

# # --- Synthesizer Node ---
# def synthesize_results(state: AppState) -> Dict[str, Any]:
#     """
#     Synthesizes the results from RAG and Web Search agents into a final report.
#     """
#     print("--- Node: Synthesizing Results ---")
#     query = state['query']
#     rag_root_cause = state.get('rag_root_cause_analysis')
#     rag_solution = state.get('rag_solution')
#     web_search = state.get('web_search_result')
#     current_error = state.get('error')

#     # If critical upstream error occurred, maybe just pass it along
#     # Or attempt synthesis with whatever is available
#     if current_error:
#         print(f"Synthesizing results despite previous error: {current_error}")
#         # Optionally decide based on error type if synthesis is feasible

#     if not synthesizer_llm:
#         error_msg = "Synthesizer LLM failed to initialize or import."
#         print(f"[ERROR Synthesizer] {error_msg}")
#         final_error = current_error if current_error else error_msg
#         return {"final_report": None, "error": final_error}

#     # Prepare inputs for the prompt, handling None values
#     input_data = {
#         "query": query,
#         "root_cause": rag_root_cause if rag_root_cause else "No root cause analysis available.",
#         "rag_solution": rag_solution if rag_solution else "No solution found in internal knowledge base.",
#         "web_search_results": web_search if web_search else "No relevant information found via web search."
#     }

#     try:
#         # Create the synthesis chain
#         synthesis_chain = (
#             SYNTHESIS_PROMPT
#             | synthesizer_llm
#             | StrOutputParser()
#         )

#         print("[INFO Synthesizer] Invoking LLM for final report synthesis...")
#         final_report = synthesis_chain.invoke(input_data)
#         print("[INFO Synthesizer] Final report generated.")

#         # Keep previous error if one existed, otherwise report success
#         return {"final_report": final_report} # Clear error if synthesis succeeds? Or keep it? Let's clear it if synthesis works.
#         # return {"final_report": final_report, "error": current_error} # Option to preserve previous non-critical errors

#     except Exception as e:
#         error_msg = f"Error during final synthesis node: {e}"
#         print(f"[ERROR Synthesizer] {error_msg}")
#         traceback.print_exc()
#         final_error = current_error if current_error else error_msg
#         # Return None for the report, ensuring the error is captured
#         return {"final_report": None, "error": final_error}

# agents/synthesizer/nodes.py
import traceback
from typing import Dict, Any, Optional

# LangChain imports
# Use ChatPromptTemplate for system/human message structure
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

# Local Imports
try:
    # Import the initialized LLM instance variable
    from gen_models.llm import llm as shared_llm
    if shared_llm is None:
        print("[ERROR Synthesizer] Shared LLM imported but was None (initialization failed).")
        synthesizer_llm = None
    else:
        synthesizer_llm = shared_llm
        print("[INFO Synthesizer] Using shared LLM.")
except ImportError:
    print("[ERROR Synthesizer] Failed to import shared LLM from 'gen_models.llm'.")
    synthesizer_llm = None # Ensure it's None if import fails

from graph.state import AppState

# --- Synthesis Chat Prompt ---
# Using ChatPromptTemplate for clearer role definition and multi-turn simulation
SYNTHESIS_PROMPT = ChatPromptTemplate.from_messages(
    [
        ("system",
         "You are an expert technical analyst for matlab query troubleshooter synthesizing information from internal analysis (root cause, potential solutions) "
         "and web research findings into a comprehensive report for the user. "
         "Generate the report in **Markdown format**. Structure the report clearly using the following headings:\n"
         "1.  **Problem Description**\n"
         "2.  **Root Cause Analysis**\n"
         "3.  **Proposed Solution / Findings**\n\n"
         "Combine insights from the internal knowledge base solution and the web search results for the 'Proposed Solution / Findings' section. "
         "Provide clear, actionable explanations. If findings conflict, acknowledge it and offer the most plausible interpretation based on the evidence.\n"
         "If information for any section is unavailable or an error occurred during its retrieval (indicated by messages like 'No root cause analysis available.' or 'No solution found...'), "
         "clearly state this under the relevant heading in the report (e.g., '**Root Cause Analysis:**\n\nNo root cause analysis was available from the internal knowledge base.').\n"
         "Focus on presenting the available information logically and concisely within the requested Markdown structure."
        ),
        ("human",
         "Please synthesize a final report in Markdown format based on the following information gathered for the user's query:\n\n"
         "--- INPUTS ---\n\n"
         "**Original User Query:**\n{query}\n\n"
         "**Internal Root Cause Analysis:**\n{root_cause}\n\n"
         "**Internal Knowledge Base Solution Suggestion:**\n{rag_solution}\n\n"
         "**Web Search Findings:**\n{web_search_results}\n\n"
         "--- END INPUTS ---\n\n"
         "**Comprehensive Report (Markdown Format):**"
        ),
    ]
)


# --- Synthesizer Node ---
def synthesize_results(state: AppState) -> Dict[str, Any]:
    """
    Synthesizes the results from RAG and Web Search agents into a final Markdown report.
    """
    print("--- Node: Synthesizing Results ---")
    query = state['query']
    # Use .get() with default messages matching placeholders for robustness
    rag_root_cause = state.get('rag_root_cause_analysis', "No root cause analysis available.")
    rag_solution = state.get('rag_solution', "No solution found in internal knowledge base.")
    web_search = state.get('web_search_result', "No relevant information found via web search.")
    current_error = state.get('error') # Keep track of upstream errors

    # Log if synthesizing despite prior errors
    if current_error:
        print(f"[WARN Synthesizer] Synthesizing results despite previous error: {current_error}")
        # Incorporate the error message into one of the inputs if desired,
        # or let the prompt handle the default messages for missing data.
        # Example: If rag_root_cause is None due to error, the default message handles it.

    if not synthesizer_llm:
        error_msg = "Synthesizer LLM is not available (failed to initialize or import)."
        print(f"[ERROR Synthesizer] {error_msg}")
        # Preserve upstream error if it exists, otherwise report this LLM issue
        final_error = current_error if current_error else error_msg
        return {"final_report": None, "error": final_error}

    # Prepare the dictionary for the prompt's input variables
    input_data = {
        "query": query,
        "root_cause": rag_root_cause if rag_root_cause else "No root cause analysis available.", # Handle potential None explicitly
        "rag_solution": rag_solution if rag_solution else "No solution found in internal knowledge base.",
        "web_search_results": web_search if web_search else "No relevant information found via web search."
    }

    try:
        # Create the synthesis chain using the ChatPromptTemplate
        synthesis_chain = (
            SYNTHESIS_PROMPT
            | synthesizer_llm
            | StrOutputParser()
        )

        print("[INFO Synthesizer] Invoking LLM for final report synthesis (Markdown)...")
        final_report = synthesis_chain.invoke(input_data)
        print("[INFO Synthesizer] Final Markdown report generated.")

        # Decide on error handling: Clear error if synthesis succeeds? Or keep upstream error?
        # Let's keep the upstream error if one occurred, otherwise clear it.
        return {"final_report": final_report, "error": current_error}

    except Exception as e:
        error_msg = f"Error during final synthesis node: {e}"
        print(f"[ERROR Synthesizer] {error_msg}")
        traceback.print_exc()
        # Preserve upstream error if it existed, otherwise report this synthesis error
        final_error = current_error if current_error else error_msg
        # Return None for the report, ensuring the error is captured
        return {"final_report": None, "error": final_error}