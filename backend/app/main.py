"""FastAPI application entry point."""
import os
import logging
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from dotenv import load_dotenv
from app.routes import router
from app.db import init_db

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create FastAPI application
app = FastAPI(title="AutoIDE Controller")

# Include routes
app.include_router(router)


@app.on_event("startup")
async def startup_event():
    """Initialize database and log startup."""
    try:
        init_db()
        logger.info("Server started on http://0.0.0.0:5757")
        
        # Check for GEMINI_API_KEY
        gemini_key = os.getenv("GEMINI_API_KEY")
        if not gemini_key:
            logger.warning("GEMINI_API_KEY not set in environment variables")
        else:
            logger.info("GEMINI_API_KEY loaded successfully")
            
    except Exception as e:
        logger.error(f"Failed to start server: {e}")
        raise


@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all incoming requests."""
    logger.info(f"{request.method} {request.url.path}")
    response = await call_next(request)
    return response


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle Pydantic validation errors."""
    logger.error(f"Validation error: {exc}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": exc.errors()}
    )


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Handle general exceptions."""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error"}
    )


@app.get("/")
async def root():
    """Root endpoint for health check."""
    return {
        "message": "AutoIDE Controller API",
        "status": "running",
        "version": "1.0.0"
    }


if __name__ == "__main__":
    import uvicorn
    # Optimize uvicorn for lower CPU usage
    uvicorn.run(
        app, 
        host="0.0.0.0", 
        port=5757,
        workers=1,  # Single worker to reduce CPU usage
        loop="asyncio",  # Use asyncio event loop
        log_level="info"
    )
