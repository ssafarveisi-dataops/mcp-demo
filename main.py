import os

from agents.mcp import MCPServerStdio, MCPServer
from agents import Agent, Runner, gen_trace_id, trace
from openai.types.responses import ResponseTextDeltaEvent
import asyncio
from dotenv import load_dotenv

# Load environment variables (e.g., OPENAI_API_KEY)
load_dotenv()


async def main():
    """
    Start the MCP server for the Search Agent with proper environment variables
    and trace the session for debugging and monitoring.
    """
    # Copy current environment variables to pass to the MCP server
    env_vars = (
        os.environ.copy()
    )  # e.g., includes custom CA bundle for corporate proxies like Zscaler

    # Start the MCP server using standard I/O transport
    async with MCPServerStdio(
        name="Search MCP Server",
        params={
            "command": "uv",
            "args": ["run", "mcp-server/search-mcp.py"],
            "env": env_vars,
        },
    ) as server:
        # Generate a unique trace ID for monitoring this session
        trace_id = gen_trace_id()

        # Context manager for tracing workflow
        with trace(workflow_name="Search MCP Agent Example", trace_id=trace_id):
            print(
                f"View trace: https://platform.openai.com/traces/trace?trace_id={trace_id}\n"
            )

            # Run the agent loop
            await run(server)


async def run(mcp_server: MCPServer):
    """
    Run an interactive session with the Directory Search Agent.
    """

    # Fetch system prompt from the MCP server
    prompt_result = await mcp_server.get_prompt("system_prompt")
    instructions = prompt_result.messages[0].content.text

    # Initialize the agent
    agent = Agent(
        name="Directory Search Agent",
        instructions=instructions,
        mcp_servers=[mcp_server],
        model="gpt-4o-mini-2024-07-18",
    )

    conversation_history = []

    print("=== Directory Search Agent ===")
    print("Type 'exit', 'quit', or 'bye' to end the conversation.")

    while True:
        user_input = input("\nUser: ").strip()

        # Exit condition
        if user_input.lower() in ["exit", "quit", "bye"]:
            print("\nGoodbye!")
            break

        if not user_input:
            continue

        # Add user input to conversation history
        conversation_history.append({"role": "user", "content": user_input})

        # Run the agent in streamed mode
        result = Runner.run_streamed(agent, input=conversation_history)

        print("\nAgent: ", end="", flush=True)

        async for event in result.stream_events():
            # Handle partial text responses
            if event.type == "raw_response_event" and isinstance(
                event.data, ResponseTextDeltaEvent
            ):
                print(event.data.delta, end="", flush=True)

            # Handle tool events
            elif event.type == "run_item_stream_event":
                item = event.item
                if item.type == "tool_call_item":
                    tool_name = item.raw_item.name
                    status_msg = {
                        "search_directory": "-- Searching directory...",
                        "check_path_type": "-- Checking path type...",
                        "read_file_content": "-- Reading file content...",
                        "fetch_post_by_id": "-- Fetching a post...",
                        "read_s3_file_content": "-- Reading S3 file content...",
                        "fetch_search_instructions": "-- Fetching instructions...",
                    }.get(tool_name, f"-- Calling {tool_name}...")
                    print(status_msg)

                elif item.type == "tool_call_output_item":
                    conversation_history.append(
                        {"role": "user", "content": str(item.output)}
                    )
                    print("-- Tool call completed.")

                elif item.type == "message_output_item":
                    msg_text = item.raw_item.content[0].text
                    conversation_history.append(
                        {"role": "assistant", "content": msg_text}
                    )

        print("\n")  # Add newline after each response


if __name__ == "__main__":
    asyncio.run(main())
