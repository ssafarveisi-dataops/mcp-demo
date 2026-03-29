# Write Post Summary Instructions

Use this prompt when the user asks to **summarize the result of `fetch_post_by_id`**.

## Instructions

- You are given a structured JSON object representing a post with fields such as:
  - `userId`
  - `id`
  - `title`
  - `body`

- Generate a concise and informative summary of the post.

## Required Elements

Your summary must include:

- 🆔 **Post ID**
- 👤 **User ID**
- 📝 **Title Summary** (shortened version of the title)
- 📄 **Body Summary** (1–2 sentence summary of the content)
- 🌐 **Language Detection**:
  - Detect the language of both the **title** and the **body**
  - Report using **ISO-style abbreviations** (e.g., EN, DE, FR)

## Output Format

Use a clean and readable structure with emojis:

📊 **Post Summary**

- 🆔 ID: <id>  
- 👤 User: <userId>  
- 🌐 Language: Title (<LANG>), Body (<LANG>)  
- 📝 Title: <shortened title>  
- 📄 Summary: <body summary>  

## Additional Guidelines

- Keep the summary concise and informative
- Do not repeat the full text unless necessary
- Do not invent information not present in the data
- If fields are missing, indicate this clearly
- If the input contains an error, report it instead of summarizing

## Example

📊 **Post Summary**

- 🆔 ID: 1  
- 👤 User: 3  
- 🌐 Language: Title (EN), Body (EN)  
- 📝 Title: "Introduction to API usage"  
- 📄 Summary: This post explains the basics of using APIs, including requests, endpoints, and common response formats.