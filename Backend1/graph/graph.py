# graph/graph.py
import os
from langgraph.graph import StateGraph, END
from .state import AppState # Import the AppState TypedDict

# --- Import Node Functions ---
try:
    from agents.rag_root_cause.nodes import analyze_root_cause_rag
    from agents.rag_solution.nodes import find_solution_rag # Keep function name the same
    from agents.web_searcher.nodes import search_web_for_query
    from agents.synthesizer.nodes import synthesize_results
except ImportError as e:
    print(f"Error importing node functions: {e}")
    print("Please ensure agent node files exist and are correctly structured.")
    exit(1)

# --- Initialize and Build the Workflow ---
print("[Graph Setup] Initializing StateGraph with AppState...")
workflow = StateGraph(AppState)

# --- Add Nodes ---
print("[Graph Setup] Adding nodes to the graph...")
try:
    # Use distinct names for nodes, different from state keys
    workflow.add_node("analyze_rag_root_cause", analyze_root_cause_rag) # Renamed for consistency
    workflow.add_node("find_rag_solution", find_solution_rag)       # <--- RENAMED NODE
    workflow.add_node("execute_web_search", search_web_for_query) # Renamed for consistency
    workflow.add_node("synthesize_final_report", synthesize_results) # Renamed for consistency

    print("[Graph Setup] Nodes added successfully: analyze_rag_root_cause, find_rag_solution, execute_web_search, synthesize_final_report") # Updated print
except Exception as e:
    print(f"Error adding nodes to the graph: {e}")
    exit(1)

# --- Define Edges ---
# Use the new node names when defining edges

# Set the entry point
workflow.set_entry_point("analyze_rag_root_cause") # Use new node name
print("[Graph Setup] Entry point set to 'analyze_rag_root_cause'.")

# Define the sequential flow
print("[Graph Setup] Adding edges for sequential flow...")
try:
    workflow.add_edge("analyze_rag_root_cause", "find_rag_solution")   # Use new node name
    workflow.add_edge("find_rag_solution", "execute_web_search")     # <--- USE RENAMED NODE
    workflow.add_edge("execute_web_search", "synthesize_final_report") # Use new node name
    workflow.add_edge("synthesize_final_report", END)                # Use new node name

    print("[Graph Setup] Edges added: analyze_rag_root_cause -> find_rag_solution -> execute_web_search -> synthesize_final_report -> END") # Updated print
except Exception as e:
    print(f"Error adding edges to the graph: {e}")
    exit(1)

# --- Compile the Graph ---
print("[Graph Setup] Compiling the graph...")
try:
    app = workflow.compile()
    print("[Graph Setup] Graph compiled successfully.")
except Exception as e:
    print(f"Error compiling the graph: {e}")
    exit(1)

# Optional visualization code remains the same...

# Optional: Attempt to generate a visualization if graphviz is installed
# try:
#     output_path = "workflow_graph.png"
#     print(f"[Graph Setup] Attempting to generate graph visualization: {output_path}")
#     # Requires `pip install pygraphviz` or `conda install pygraphviz`
#     app.get_graph().draw_mermaid_png(output_file=output_path)
#     print(f"[Graph Setup] Graph visualization saved to {output_path}")
# except Exception as viz_error:
#     print(f"[Graph Setup] Warning: Could not generate graph visualization. Is graphviz installed and in PATH? Error: {viz_error}")