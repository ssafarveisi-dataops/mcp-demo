import uuid
from typing import Optional

from pydantic import BaseModel, Field, ValidationError
from bedrock_agentcore.runtime import BedrockAgentCoreApp

app = BedrockAgentCoreApp()
log = app.logger


class RequestModel(BaseModel):
    id: str = Field(..., description="Unique identifier for the request")
    prompt: str = Field(..., min_length=1, description="Input prompt for the agent")


@app.entrypoint
async def invoke(payload, context):
    request_uuid = str(uuid.uuid4())
    log.info(f"Received request UUID={request_uuid}, payload={payload}")

    try:
        # Validate input
        data = RequestModel(**payload)

    except ValidationError as e:
        log.error(f"Validation failed for UUID={request_uuid}: {e}")
        return {
            "error": "Invalid input",
            "details": e.errors(),
            "request_uuid": request_uuid,
        }

    log.info(f"Processing id={data.id}")

    return {
        "id": data.id,
        "prompt": data.prompt,
        "response": f"Agent worked successfully for id={data.id} (request_uuid={request_uuid})",
    }


if __name__ == "__main__":
    app.run()
