from agents import Agent, Runner
from agents.mcp import MCPServerStdio, MCPServer
from agents import Agent, Runner, gen_trace_id, trace
from openai.types.responses import ResponseTextDeltaEvent
import asyncio
from dotenv import load_dotenv

# Load environment variables (e.g., OPENAI_API_KEY)
load_dotenv()

async def main():
    async with MCPServerStdio(
        name="Search MCP Server",
        params={
            "command": "uv",
            "args": ["run", "mcp-server/search-mcp.py"],
        },
    ) as server:
        trace_id = gen_trace_id()
        with trace(workflow_name="Search MCP Agent Example", trace_id=trace_id):
            print(f"View trace: https://platform.openai.com/traces/trace?trace_id={trace_id}\n")
            await run(server)

async def run(mcp_server: MCPServer):
    # Get system prompt from MCP server
    prompt_result = await mcp_server.get_prompt("system_prompt")
    instructions = prompt_result.messages[0].content.text
    
    # Create agent
    agent = Agent(
        name="Directory Search Agent",
        instructions=instructions,
        mcp_servers=[mcp_server],
        model="openai/gpt-4.1"
    )
    
    input_items = []

    print("=== Directory Search Agent ===")
    print("Type 'exit' to end the conversation")

    while True:
        # Get user input
        user_input = input("\nUser: ").strip()
        input_items.append({"content": user_input, "role": "user"})
        
        # Exit condition
        if user_input.lower() in ['exit', 'quit', 'bye']:
            print("\nGoodbye!")
            break
            
        if not user_input:
            continue

        result = Runner.run_streamed(
            agent,
            input=input_items,
        )
        print("\nAgent: ", end="", flush=True)
        
        async for event in result.stream_events():
            # Handle text delta events
            if event.type == "raw_response_event" and isinstance(event.data, ResponseTextDeltaEvent):
                print(event.data.delta, end="", flush=True)
            
            # Handle tool events
            elif event.type == "run_item_stream_event":
                if event.item.type == "tool_call_item":
                    tool_name = event.item.raw_item.name
                    if tool_name == "search_directory":
                        status_msg = "\n-- Searching directory..."
                    elif tool_name == "read_file_content":
                        status_msg = "\n-- Reading file content..."
                    elif tool_name == "fetch_search_instructions":
                        status_msg = "\n-- Fetching instructions..."
                    else:
                        status_msg = f"\n-- Calling {tool_name}..."
                    print(status_msg)
                
                elif event.item.type == "tool_call_output_item":
                    input_items.append({"content": f"{event.item.output}", "role": "user"})
                    print("-- Tool call completed.")
                
                elif event.item.type == "message_output_item":
                    input_items.append({"content": f"{event.item.raw_item.content[0].text}", "role": "assistant"})
                
                else:
                    pass  # Ignore other event types

        print("\n")  # Add a newline after each response

if __name__ == "__main__":
    asyncio.run(main())