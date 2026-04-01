# Write a S3 file summary instructions

Use this prompt when the user asks you to write a **summary of a file retrieved from S3 using the `read_s3_file_content`** tool.

## Instructions

- You are given the **raw text content** of a file fetched from S3.
- Generate a concise and informative summary of the file.

---

## Required Elements

Your summary must include:

- 🪣 **S3 Bucket**
- 📂 **S3 Key**
- 📝 **Content Summary** (3–5 sentences capturing the main ideas)
- 📌 **Key Points** (2–4 bullet points)

---

## Additional Guidelines

- Keep the summary concise and informative
- Use your own words (no large copy-paste)
- Do not invent missing information
- If the content is empty or invalid, report it clearly
- Ignore low-value noise (e.g., logs, boilerplate)

---

## Example

📊 **S3 File Summary**

- 🪣 Bucket: my-bucket  
- 📂 Key: logs/app.log  
- 📝 Summary: This file contains application logs highlighting recent errors and system activity. Most entries relate to failed API calls and timeout issues.

📌 **Key Points**
- Multiple error logs detected  
- Frequent timeout issues  
- API failures concentrated in one service  