# api_models.py
from pydantic import BaseModel
from typing import Optional

class QueryRequest(BaseModel):
    """Request model for submitting a query."""
    query: str

class ReportResponse(BaseModel):
    """Response model for returning the report."""
    query: str  # Echo back the original query
    report: Optional[str] = None # The generated Markdown report
    error: Optional[str] = None  # Any error message encountered