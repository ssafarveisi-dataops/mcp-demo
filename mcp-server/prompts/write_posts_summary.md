# Write Post Summary Instructions

Use this prompt when the user asks to **summarize the result of `fetch_posts`**.

---

## Instructions

* You are given a structured JSON object representing the response of `fetch_posts` with the following structure:

```json
{
  "count": <number>,
  "results": [
    {
      "post_id": <number>,
      "data": {
        "userId": <number>,
        "id": <number>,
        "title": <string>,
        "body": <string>
      }
    },
    {
      "post_id": <number>,
      "error": <string>
    }
  ]
}
```

* The `results` array may contain:

  * ✅ Successful responses (`data`)
  * ❌ Error entries (`error`)

* Generate a concise and informative summary for **each item** in `results`.

---

## Required Elements

### ✅ If `data` exists:

Include:

* 🆔 **Post ID**
* 👤 **User ID**
* 📝 **Title Summary** (shortened version of the title)
* 📄 **Body Summary** (1–2 sentence summary of the content)
* 🌐 **Language Detection**

  * Detect the language of both the **title** and the **body**
  * Use **ISO-style abbreviations** (e.g., EN, DE, FR)

---

### ❌ If `error` exists:

Include:

* 🆔 **Post ID**
* ⚠️ **Error Message**

---

## Output Format

Use a clean and readable structure with emojis.

For multiple results, output each summary separately:

---

📊 **Post Summary**

* 🆔 ID: <id>
* 👤 User: <userId>
* 🌐 Language: Title (<LANG>), Body (<LANG>)
* 📝 Title: <shortened title>
* 📄 Summary: <body summary>

---

📊 **Post Summary (Error)**

* 🆔 ID: <post_id>
* ⚠️ Error: <error message>

---

## Additional Guidelines

* Iterate over **all results**
* Preserve the **original order** of results
* Keep summaries concise and informative
* Do not repeat full text unless necessary
* Do not invent missing information
* Clearly distinguish between **successful** and **failed** results
* If required fields are missing, indicate this explicitly

---

## Example

📊 **Post Summary**

* 🆔 ID: 1
* 👤 User: 3
* 🌐 Language: Title (EN), Body (EN)
* 📝 Title: "Introduction to API usage"
* 📄 Summary: This post explains the basics of using APIs, including requests, endpoints, and common response formats.

---

📊 **Post Summary (Error)**

* 🆔 ID: 999
* ⚠️ Error: Post not found