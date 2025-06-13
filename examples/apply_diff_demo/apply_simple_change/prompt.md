# Apply Simple Change

Now use the apply_diff function to modify the `hello.txt` file. Let's change the greeting from "Hello World!" to "Hello, Apply Diff Demo!".

Use the apply_diff function with:
- `file_path`: "hello.txt"
- `old_content`: "Hello World!"
- `new_content`: "Hello, Apply Diff Demo!"
- `description`: "Update greeting to be more specific to the demo"

This will show the user a colored diff of the proposed change and ask for their confirmation before applying it.

After the change is applied (or declined), read the file again to show the final result.