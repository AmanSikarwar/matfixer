import os
from langchain_groq import ChatGroq  # Make sure this library is installed
from dotenv import load_dotenv
load_dotenv('../../.env')

groq_api_key = os.getenv("GROQ_API_KEY")
groq_model_name = os.getenv("GROQ_MODEL_NAME", "llama3-70b-8192")  # default model

if not groq_api_key:
    print("Warning: GROQ_API_KEY not found in environment variables.")

llm = ChatGroq(
    model_name=groq_model_name,
    temperature=0,
    groq_api_key=groq_api_key
)

print(f"LLM configured to use Groq model: {groq_model_name}")
_all_=["llm"]