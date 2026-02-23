# Agent Skills: Authoring Best Practices

> Source: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices

Learn how to write effective Skills that Claude can discover and use successfully.

Good Skills are concise, well-structured, and tested with real usage. This guide provides practical authoring decisions to help you write Skills that Claude can discover and use effectively.

---

## Core principles

### Concise is key

The context window is a public good. Your Skill shares the context window with everything else Claude needs to know, including:

- The system prompt
- Conversation history
- Other Skills' metadata
- Your actual request

Not every token in your Skill has an immediate cost. At startup, only the metadata (name and description) from all Skills is pre-loaded. Claude reads SKILL.md only when the Skill becomes relevant, and reads additional files only as needed. However, being concise in SKILL.md still matters: once Claude loads it, every token competes with conversation history and other context.

**Default assumption: Claude is already very smart.**

Only add context Claude doesn't already have. Challenge each piece of information:

- "Does Claude really need this explanation?"
- "Can I assume Claude knows this?"
- "Does this paragraph justify its token cost?"

**Good example: Concise** (~50 tokens):

```markdown
## Extract PDF text

Use pdfplumber for text extraction:

```python
import pdfplumber

with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```
```

**Bad example: Too verbose** (~150 tokens):

```markdown
## Extract PDF text

PDF (Portable Document Format) files are a common file format that contains
text, images, and other content. To extract text from a PDF, you'll need to
use a library. There are many libraries available for PDF processing, but
pdfplumber is recommended because it's easy to use and handles most cases well.
First, you'll need to install it using pip. Then you can use the code below...
```

The concise version assumes Claude knows what PDFs are and how libraries work.

---

### Set appropriate degrees of freedom

Match the level of specificity to the task's fragility and variability.

**High freedom** (text-based instructions):

Use when multiple approaches are valid, decisions depend on context, or heuristics guide the approach.

```markdown
## Code review process

1. Analyze the code structure and organization
2. Check for potential bugs or edge cases
3. Suggest improvements for readability and maintainability
4. Verify adherence to project conventions
```

**Medium freedom** (pseudocode or scripts with parameters):

Use when a preferred pattern exists, some variation is acceptable, or configuration affects behavior.

```markdown
## Generate report

Use this template and customize as needed:

```python
def generate_report(data, format="markdown", include_charts=True):
    # Process data
    # Generate output in specified format
    # Optionally include visualizations
```
```

**Low freedom** (specific scripts, few or no parameters):

Use when operations are fragile and error-prone, consistency is critical, or a specific sequence must be followed.

```markdown
## Database migration

Run exactly this script:

```bash
python scripts/migrate.py --verify --backup
```

Do not modify the command or add additional flags.
```

**Analogy — the narrow bridge vs. open field:**

- **Narrow bridge with cliffs on both sides**: There's only one safe way forward. Provide specific guardrails and exact instructions (low freedom). Example: database migrations that must run in exact sequence.
- **Open field with no hazards**: Many paths lead to success. Give general direction and trust Claude to find the best route (high freedom). Example: code reviews where context determines the best approach.

---

### Test with all models you plan to use

Skills act as additions to models, so effectiveness depends on the underlying model.

**Testing considerations by model:**

- **Claude Haiku** (fast, economical): Does the Skill provide enough guidance?
- **Claude Sonnet** (balanced): Is the Skill clear and efficient?
- **Claude Opus** (powerful reasoning): Does the Skill avoid over-explaining?

What works perfectly for Opus might need more detail for Haiku. If you plan to use your Skill across multiple models, aim for instructions that work well with all of them.

---

## Skill structure

### YAML frontmatter requirements

The SKILL.md frontmatter requires two fields:

**`name`:**
- Maximum 64 characters
- Must contain only lowercase letters, numbers, and hyphens
- Cannot contain XML tags
- Cannot contain reserved words: "anthropic", "claude"

**`description`:**
- Must be non-empty
- Maximum 1024 characters
- Cannot contain XML tags
- Should describe what the Skill does and when to use it

---

### Naming conventions

Use consistent naming patterns. Consider **gerund form** (verb + -ing), as this clearly describes the activity or capability.

**Good naming examples (gerund form):**

- `processing-pdfs`
- `analyzing-spreadsheets`
- `managing-databases`
- `testing-code`
- `writing-documentation`

**Acceptable alternatives:**

- Noun phrases: `pdf-processing`, `spreadsheet-analysis`
- Action-oriented: `process-pdfs`, `analyze-spreadsheets`

**Avoid:**

- Vague names: `helper`, `utils`, `tools`
- Overly generic: `documents`, `data`, `files`
- Reserved words: `anthropic-helper`, `claude-tools`
- Inconsistent patterns within your skill collection

---

### Writing effective descriptions

The `description` field enables Skill discovery and should include both **what** the Skill does and **when** to use it.

> **Always write in third person.** The description is injected into the system prompt, and inconsistent point-of-view can cause discovery problems.
>
> - **Good:** "Processes Excel files and generates reports"
> - **Avoid:** "I can help you process Excel files"
> - **Avoid:** "You can use this to process Excel files"

Be specific and include key terms. Each Skill has exactly one description field. The description is critical for skill selection: Claude uses it to choose the right Skill from potentially 100+ available Skills.

**Effective examples:**

```yaml
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
```

```yaml
description: Analyze Excel spreadsheets, create pivot tables, generate charts. Use when analyzing Excel files, spreadsheets, tabular data, or .xlsx files.
```

```yaml
description: Generate descriptive commit messages by analyzing git diffs. Use when the user asks for help writing commit messages or reviewing staged changes.
```

**Avoid vague descriptions:**

```yaml
description: Helps with documents
```
```yaml
description: Processes data
```
```yaml
description: Does stuff with files
```

---

### Progressive disclosure patterns

SKILL.md serves as an overview that points Claude to detailed materials as needed, like a table of contents in an onboarding guide.

**Practical guidance:**

- Keep SKILL.md body under 500 lines for optimal performance
- Split content into separate files when approaching this limit
- Use the patterns below to organize instructions, code, and resources effectively

**Example skill directory structure:**

```text
pdf/
├── SKILL.md              # Main instructions (loaded when triggered)
├── FORMS.md              # Form-filling guide (loaded as needed)
├── reference.md          # API reference (loaded as needed)
├── examples.md           # Usage examples (loaded as needed)
└── scripts/
    ├── analyze_form.py   # Utility script (executed, not loaded)
    ├── fill_form.py      # Form filling script
    └── validate.py       # Validation script
```

#### Pattern 1: High-level guide with references

```markdown
---
name: pdf-processing
description: Extracts text and tables from PDF files, fills forms, and merges documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
---

# PDF Processing

## Quick start

Extract text with pdfplumber:
```python
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```

## Advanced features

**Form filling**: See [FORMS.md](FORMS.md) for complete guide
**API reference**: See [REFERENCE.md](REFERENCE.md) for all methods
**Examples**: See [EXAMPLES.md](EXAMPLES.md) for common patterns
```

Claude loads `FORMS.md`, `REFERENCE.md`, or `EXAMPLES.md` only when needed.

#### Pattern 2: Domain-specific organization

For Skills with multiple domains, organize content by domain to avoid loading irrelevant context.

```text
bigquery-skill/
├── SKILL.md (overview and navigation)
└── reference/
    ├── finance.md (revenue, billing metrics)
    ├── sales.md (opportunities, pipeline)
    ├── product.md (API usage, features)
    └── marketing.md (campaigns, attribution)
```

```markdown
# BigQuery Data Analysis

## Available datasets

**Finance**: Revenue, ARR, billing → See [reference/finance.md](reference/finance.md)
**Sales**: Opportunities, pipeline, accounts → See [reference/sales.md](reference/sales.md)
**Product**: API usage, features, adoption → See [reference/product.md](reference/product.md)
**Marketing**: Campaigns, attribution, email → See [reference/marketing.md](reference/marketing.md)

## Quick search

```bash
grep -i "revenue" reference/finance.md
grep -i "pipeline" reference/sales.md
```
```

#### Pattern 3: Conditional details

Show basic content, link to advanced content:

```markdown
# DOCX Processing

## Creating documents

Use docx-js for new documents. See [DOCX-JS.md](DOCX-JS.md).

## Editing documents

For simple edits, modify the XML directly.

**For tracked changes**: See [REDLINING.md](REDLINING.md)
**For OOXML details**: See [OOXML.md](OOXML.md)
```

---

### Avoid deeply nested references

Claude may partially read files when they're referenced from other referenced files. **Keep references one level deep from SKILL.md.** All reference files should link directly from SKILL.md.

**Bad — too deep:**

```
# SKILL.md → advanced.md → details.md → actual info
```

**Good — one level deep:**

```markdown
# SKILL.md

**Basic usage**: [instructions in SKILL.md]
**Advanced features**: See [advanced.md](advanced.md)
**API reference**: See [reference.md](reference.md)
**Examples**: See [examples.md](examples.md)
```

---

### Structure longer reference files with table of contents

For reference files longer than 100 lines, include a table of contents at the top. This ensures Claude can see the full scope of available information even when previewing with partial reads.

```markdown
# API Reference

## Contents
- Authentication and setup
- Core methods (create, read, update, delete)
- Advanced features (batch operations, webhooks)
- Error handling patterns
- Code examples

## Authentication and setup
...
```

---

## Workflows and feedback loops

### Use workflows for complex tasks

Break complex operations into clear, sequential steps. For particularly complex workflows, provide a checklist that Claude can copy into its response and check off as it progresses.

**Example: Research synthesis workflow (no code):**

```markdown
## Research synthesis workflow

Copy this checklist and track your progress:

```
Research Progress:
- [ ] Step 1: Read all source documents
- [ ] Step 2: Identify key themes
- [ ] Step 3: Cross-reference claims
- [ ] Step 4: Create structured summary
- [ ] Step 5: Verify citations
```

**Step 1: Read all source documents**
Review each document in the `sources/` directory. Note the main arguments and supporting evidence.

**Step 2: Identify key themes**
Look for patterns across sources. What themes appear repeatedly? Where do sources agree or disagree?
...
```

**Example: PDF form filling workflow (with code):**

```markdown
## PDF form filling workflow

Copy this checklist and check off items as you complete them:

```
Task Progress:
- [ ] Step 1: Analyze the form (run analyze_form.py)
- [ ] Step 2: Create field mapping (edit fields.json)
- [ ] Step 3: Validate mapping (run validate_fields.py)
- [ ] Step 4: Fill the form (run fill_form.py)
- [ ] Step 5: Verify output (run verify_output.py)
```

**Step 1: Analyze the form**
Run: `python scripts/analyze_form.py input.pdf`

**Step 3: Validate mapping**
Run: `python scripts/validate_fields.py fields.json`
Fix any validation errors before continuing.
```

---

### Implement feedback loops

**Common pattern**: Run validator → fix errors → repeat.

**Example: Style guide compliance (no code):**

```markdown
## Content review process

1. Draft your content following the guidelines in STYLE_GUIDE.md
2. Review against the checklist:
   - Check terminology consistency
   - Verify examples follow the standard format
   - Confirm all required sections are present
3. If issues found:
   - Note each issue with specific section reference
   - Revise the content
   - Review the checklist again
4. Only proceed when all requirements are met
```

**Example: Document editing process (with code):**

```markdown
## Document editing process

1. Make your edits to `word/document.xml`
2. **Validate immediately**: `python ooxml/scripts/validate.py unpacked_dir/`
3. If validation fails:
   - Review the error message carefully
   - Fix the issues in the XML
   - Run validation again
4. **Only proceed when validation passes**
5. Rebuild: `python ooxml/scripts/pack.py unpacked_dir/ output.docx`
```

---

## Content guidelines

### Avoid time-sensitive information

Don't include information that will become outdated.

**Bad — time-sensitive (will become wrong):**

```markdown
If you're doing this before August 2025, use the old API.
After August 2025, use the new API.
```

**Good — use "old patterns" section:**

```markdown
## Current method

Use the v2 API endpoint: `api.example.com/v2/messages`

## Old patterns

<details>
<summary>Legacy v1 API (deprecated 2025-08)</summary>

The v1 API used: `api.example.com/v1/messages`

This endpoint is no longer supported.
</details>
```

---

### Use consistent terminology

Choose one term and use it throughout the Skill.

| Good (consistent) | Bad (inconsistent) |
|---|---|
| Always "API endpoint" | Mix "API endpoint", "URL", "API route", "path" |
| Always "field" | Mix "field", "box", "element", "control" |
| Always "extract" | Mix "extract", "pull", "get", "retrieve" |

---

## Common patterns

### Template pattern

**For strict requirements (like API responses or data formats):**

```markdown
## Report structure

ALWAYS use this exact template structure:

```markdown
# [Analysis Title]

## Executive summary
[One-paragraph overview of key findings]

## Key findings
- Finding 1 with supporting data
- Finding 2 with supporting data
```
```

**For flexible guidance (when adaptation is useful):**

```markdown
## Report structure

Here is a sensible default format, but use your best judgment based on the analysis:

```markdown
# [Analysis Title]

## Executive summary
[Overview]

## Key findings
[Adapt sections based on what you discover]
```

Adjust sections as needed for the specific analysis type.
```

---

### Examples pattern

Provide input/output pairs just like in regular prompting:

```markdown
## Commit message format

**Example 1:**
Input: Added user authentication with JWT tokens
Output:
```
feat(auth): implement JWT-based authentication

Add login endpoint and token validation middleware
```

**Example 2:**
Input: Fixed bug where dates displayed incorrectly in reports
Output:
```
fix(reports): correct date formatting in timezone conversion

Use UTC timestamps consistently across report generation
```

Follow this style: type(scope): brief description, then detailed explanation.
```

---

### Conditional workflow pattern

```markdown
## Document modification workflow

1. Determine the modification type:

   **Creating new content?** → Follow "Creation workflow" below
   **Editing existing content?** → Follow "Editing workflow" below

2. Creation workflow:
   - Use docx-js library
   - Build document from scratch
   - Export to .docx format

3. Editing workflow:
   - Unpack existing document
   - Modify XML directly
   - Validate after each change
   - Repack when complete
```

> If workflows become large or complicated, consider pushing them into separate files and tell Claude to read the appropriate file based on the task at hand.

---

## Evaluation and iteration

### Build evaluations first

**Create evaluations BEFORE writing extensive documentation.** This ensures your Skill solves real problems rather than documenting imagined ones.

**Evaluation-driven development:**

1. **Identify gaps**: Run Claude on representative tasks without a Skill. Document specific failures or missing context.
2. **Create evaluations**: Build three scenarios that test these gaps.
3. **Establish baseline**: Measure Claude's performance without the Skill.
4. **Write minimal instructions**: Create just enough content to address the gaps and pass evaluations.
5. **Iterate**: Execute evaluations, compare against baseline, and refine.

**Evaluation structure:**

```json
{
  "skills": ["pdf-processing"],
  "query": "Extract all text from this PDF file and save it to output.txt",
  "files": ["test-files/document.pdf"],
  "expected_behavior": [
    "Successfully reads the PDF file using an appropriate PDF processing library",
    "Extracts text content from all pages without missing any pages",
    "Saves the extracted text to a file named output.txt in a clear, readable format"
  ]
}
```

---

### Develop Skills iteratively with Claude

The most effective Skill development process involves Claude itself:

- **Claude A**: the expert instance that helps you design and refine the Skill
- **Claude B**: a fresh instance that tests the Skill in real tasks

**Creating a new Skill:**

1. **Complete a task without a Skill**: Work through a problem with Claude A. Notice what information you repeatedly provide.
2. **Identify the reusable pattern**: After completing the task, identify what context would be useful for similar future tasks.
3. **Ask Claude A to create a Skill**: "Create a Skill that captures this BigQuery analysis pattern we just used."

   > Claude models understand the Skill format natively. Simply ask Claude to create a Skill and it will generate properly structured SKILL.md content.

4. **Review for conciseness**: Ask: "Remove the explanation about what win rate means — Claude already knows that."
5. **Improve information architecture**: Ask Claude A to organize content more effectively. E.g.: "Organize this so the table schema is in a separate reference file."
6. **Test on similar tasks**: Use the Skill with Claude B on related use cases.
7. **Iterate based on observation**: "When Claude used this Skill, it forgot to filter by date for Q4. Should we add a section about date filtering patterns?"

**Iterating on existing Skills:**

1. **Use the Skill in real workflows**: Give Claude B actual tasks, not test scenarios.
2. **Observe Claude B's behavior**: Note where it struggles, succeeds, or makes unexpected choices.
3. **Return to Claude A for improvements**: Share the current SKILL.md and describe what you observed.
4. **Review and apply changes**, then test again with Claude B.
5. **Repeat based on usage**: Continue the observe-refine-test cycle as you encounter new scenarios.

---

### Observe how Claude navigates Skills

Watch for:

- **Unexpected exploration paths**: Does Claude read files in an order you didn't anticipate? Your structure may not be as intuitive as you thought.
- **Missed connections**: Does Claude fail to follow references? Your links may need to be more explicit or prominent.
- **Overreliance on certain sections**: If Claude repeatedly reads the same file, consider whether that content should be in the main SKILL.md.
- **Ignored content**: If Claude never accesses a bundled file, it might be unnecessary or poorly signaled.

The `name` and `description` fields are particularly critical. Claude uses these when deciding whether to trigger the Skill.

---

## Anti-patterns to avoid

### Avoid Windows-style paths

Always use forward slashes in file paths, even on Windows:

- ✓ `scripts/helper.py`, `reference/guide.md`
- ✗ `scripts\helper.py`, `reference\guide.md`

### Avoid offering too many options

**Bad — too many choices:**

```markdown
"You can use pypdf, or pdfplumber, or PyMuPDF, or pdf2image, or..."
```

**Good — provide a default with escape hatch:**

```markdown
Use pdfplumber for text extraction:
```python
import pdfplumber
```

For scanned PDFs requiring OCR, use pdf2image with pytesseract instead.
```

---

## Advanced: Skills with executable code

### Solve, don't punt

When writing scripts for Skills, handle error conditions rather than punting to Claude.

**Good — handle errors explicitly:**

```python
def process_file(path):
    """Process a file, creating it if it doesn't exist."""
    try:
        with open(path) as f:
            return f.read()
    except FileNotFoundError:
        print(f"File {path} not found, creating default")
        with open(path, "w") as f:
            f.write("")
        return ""
    except PermissionError:
        print(f"Cannot access {path}, using default")
        return ""
```

**Bad — punt to Claude:**

```python
def process_file(path):
    # Just fail and let Claude figure it out
    return open(path).read()
```

Configuration parameters should be justified and documented.

**Good — self-documenting:**

```python
# HTTP requests typically complete within 30 seconds
# Longer timeout accounts for slow connections
REQUEST_TIMEOUT = 30

# Three retries balances reliability vs speed
MAX_RETRIES = 3
```

**Bad — magic numbers:**

```python
TIMEOUT = 47  # Why 47?
RETRIES = 5   # Why 5?
```

---

### Provide utility scripts

Even if Claude could write a script, pre-made scripts offer advantages:

- More reliable than generated code
- Save tokens (no need to include code in context)
- Save time (no code generation required)
- Ensure consistency across uses

Make clear in your instructions whether Claude should **execute** the script or **read it as reference**:

```markdown
## Utility scripts

**analyze_form.py**: Extract all form fields from PDF

```bash
python scripts/analyze_form.py input.pdf > fields.json
```

Output format:
```json
{
  "field_name": {"type": "text", "x": 100, "y": 200},
  "signature": {"type": "sig", "x": 150, "y": 500}
}
```

**validate_boxes.py**: Check for overlapping bounding boxes

```bash
python scripts/validate_boxes.py fields.json
# Returns: "OK" or lists conflicts
```
```

---

### Use visual analysis

When inputs can be rendered as images, have Claude analyze them:

```markdown
## Form layout analysis

1. Convert PDF to images:
   ```bash
   python scripts/pdf_to_images.py form.pdf
   ```

2. Analyze each page image to identify form fields
3. Claude can see field locations and types visually
```

---

### Create verifiable intermediate outputs

The **plan-validate-execute** pattern catches errors early by having Claude first create a plan in a structured format, then validate that plan with a script before executing it.

**Why this pattern works:**

- **Catches errors early**: Validation finds problems before changes are applied
- **Machine-verifiable**: Scripts provide objective verification
- **Reversible planning**: Claude can iterate on the plan without touching originals
- **Clear debugging**: Error messages point to specific problems

**When to use**: Batch operations, destructive changes, complex validation rules, high-stakes operations.

**Implementation tip**: Make validation scripts verbose with specific error messages like `"Field 'signature_date' not found. Available fields: customer_name, order_total, signature_date_signed"`.

---

### Package dependencies

- **claude.ai**: Can install packages from npm and PyPI and pull from GitHub repositories
- **Claude API**: Has no network access and no runtime package installation

List required packages in your SKILL.md and verify they're available in the code execution tool documentation.

---

### MCP tool references

Always use fully qualified tool names to avoid "tool not found" errors.

**Format**: `ServerName:tool_name`

```markdown
Use the BigQuery:bigquery_schema tool to retrieve table schemas.
Use the GitHub:create_issue tool to create issues.
```

Without the server prefix, Claude may fail to locate the tool.

---

### Avoid assuming tools are installed

```markdown
**Bad — assumes installation:**
"Use the pdf library to process the file."

**Good — explicit about dependencies:**
"Install required package: `pip install pypdf`

Then use it:
```python
from pypdf import PdfReader
reader = PdfReader("file.pdf")
```"
```

---

## Runtime environment

Skills run in a code execution environment with filesystem access, bash commands, and code execution capabilities.

**How Claude accesses Skills:**

1. **Metadata pre-loaded**: At startup, the name and description from all Skills' YAML frontmatter are loaded into the system prompt.
2. **Files read on-demand**: Claude uses bash Read tools to access SKILL.md and other files from the filesystem when needed.
3. **Scripts executed efficiently**: Utility scripts can be executed via bash without loading their full contents into context.
4. **No context penalty for large files**: Reference files, data, or documentation don't consume context tokens until actually read.

**File path authoring guidelines:**

- **File paths matter**: Use forward slashes (`reference/guide.md`), not backslashes
- **Name files descriptively**: `form_validation_rules.md`, not `doc2.md`
- **Organize for discovery**: `reference/finance.md`, `reference/sales.md` — not `docs/file1.md`, `docs/file2.md`
- **Bundle comprehensive resources**: Include complete API docs, extensive examples, large datasets — no context penalty until accessed
- **Make execution intent clear**: "Run `analyze_form.py` to extract fields" (execute) vs "See `analyze_form.py` for the extraction algorithm" (read as reference)

---

## Checklist for effective Skills

### Core quality

- [ ] Description is specific and includes key terms
- [ ] Description includes both what the Skill does and when to use it
- [ ] SKILL.md body is under 500 lines
- [ ] Additional details are in separate files (if needed)
- [ ] No time-sensitive information (or in "old patterns" section)
- [ ] Consistent terminology throughout
- [ ] Examples are concrete, not abstract
- [ ] File references are one level deep
- [ ] Progressive disclosure used appropriately
- [ ] Workflows have clear steps

### Code and scripts

- [ ] Scripts solve problems rather than punt to Claude
- [ ] Error handling is explicit and helpful
- [ ] No "voodoo constants" (all values justified)
- [ ] Required packages listed in instructions and verified as available
- [ ] Scripts have clear documentation
- [ ] No Windows-style paths (all forward slashes)
- [ ] Validation/verification steps for critical operations
- [ ] Feedback loops included for quality-critical tasks

### Testing

- [ ] At least three evaluations created
- [ ] Tested with Haiku, Sonnet, and Opus
- [ ] Tested with real usage scenarios
- [ ] Team feedback incorporated (if applicable)
