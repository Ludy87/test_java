# Stirling-PDF Language Addition Standard

<p align="center">
  <img src="https://raw.githubusercontent.com/Stirling-Tools/Stirling-PDF/main/docs/stirling.png" width="80">
  <br>
  <h1 align="center">Stirling-PDF</h1>
</p>

## How to Add New Languages to Stirling-PDF

To contribute a new language to Stirling-PDF, follow these steps precisely to maintain consistency and avoid errors.

### Step 1: Fork and Create a Branch

1. **Fork** the Stirling-PDF repository to your GitHub account.
2. **Create a new branch** from the `main` branch in your fork.

### Step 2: Update the Language Dropdown in the Navbar

To make the new language available in the Stirling-PDF interface, add it to the language dropdown:

1. **Edit the Navbar Language Dropdown**
   - File to Edit: [languages.html](https://github.com/Stirling-Tools/Stirling-PDF/blob/main/src/main/resources/templates/fragments/languages.html).
2. **Add a New Language Entry**:
   - Include an SVG flag for your language in the dropdown.

   Example (for adding Polish):

   ```html
   <a class="dropdown-item lang_dropdown-item" href="" data-bs-language-code="pl_PL">
       <img src="images/flags/pl.svg" alt="icon" width="20" height="15"> Polski
   </a>
   ```

3. **Add the Flag SVG File**:
   - Place the SVG in the [flags directory](https://github.com/Stirling-Tools/Stirling-PDF/tree/main/src/main/resources/static/images/flags).
   - Flags can be sourced from [Flag Icons](https://flagicons.lipis.dev/).
   - If no specific flag exists for your language, choose a representative flag (e.g., use Saudi Arabia’s flag for Arabic).

### Step 3: Add the Language Property File

1. **Copy the English Property File**:
   - Source File: [messages_en_GB.properties](https://github.com/Stirling-Tools/Stirling-PDF/blob/main/src/main/resources/messages_en_GB.properties).
2. **Rename the File**:
   - Rename it to `messages_{your_language_code}.properties` (e.g., `messages_pl_PL.properties` for Polish).
3. **Translate** all the entries within the new file.

### Step 4: Add New Translation Tags

> [!IMPORTANT]
> Always add new translation tags to the `messages_en_GB.properties` file **first** to ensure reference consistency for all languages.

1. **Add Tags to the English Property File** (`messages_en_GB.properties`).
2. **Translate Tags in Other Language Files**:
   - After adding to the English file, include the translation in your specific language file (e.g., `messages_pl_PL.properties`).
3. **Strict Adherence to Formatting**:
   - **Incorrect formatting** will result in the translation tool failing the validation test, marking it as erroneous.
   - Ensuring consistent formatting is crucial for proper compilation and runtime functionality.

### Step 5: Handling Untranslatable Strings

Some strings may not require translation (e.g., protocol names, specific terms):

1. **Add to Ignore List**:
   - File: `ignore_translation.toml` in the `scripts` directory.
2. **Example Entry**:
   ```toml
   [pl_PL]
   ignore = [
       "language.direction",  # Existing entries
       "error"                # Add new entries here
   ]
   ```
   This ensures these strings are excluded from translation progress calculations.

### Step 6: Create a Pull Request

1. Once all changes are complete, **create a Pull Request (PR)** into the `main` branch.
2. If you do not have a Java IDE, one of the maintainers can verify the changes for functionality but **not the accuracy** of the translations.

### Summary Checklist

- [ ] **Fork** the repository and **create a branch** from `main`.
- [ ] **Add a new language entry** to the language dropdown in `languages.html`.
- [ ] **Add the SVG flag** to the flags directory.
- [ ] **Create and translate** a language property file (starting from `messages_en_GB.properties`).
- [ ] **Update the `ignore_translation.toml` file** for untranslatable strings.
- [ ] **Ensure proper formatting** of all new entries.
- [ ] **Submit a Pull Request** for review.

### Notes on Formatting and Tools

- **Formatting Errors**: Incorrect formatting will cause the translation validation tool to fail, resulting in the PR being marked as invalid. Follow the property file structure strictly.
- **Placement**: Ensure all entries are correctly placed in the language file, maintaining the logical structure for translation progress tracking.
