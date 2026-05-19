import os
import re

def remove_cpp_comments(content):
    # Remove multi-line comments /* */
    content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
    # Remove single-line comments //
    lines = content.split('\n')
    lines = [re.sub(r'//.*$', '', line) for line in lines]
    content = '\n'.join(lines)
    # Remove extra blank lines
    content = re.sub(r'\n\n\n+', '\n\n', content)
    return content

def remove_python_comments(content):
    lines = content.split('\n')
    new_lines = []
    for line in lines:
        # Remove # comments
        line = re.sub(r'#.*$', '', line)
        new_lines.append(line)
    content = '\n'.join(new_lines)
    # Remove extra blank lines
    content = re.sub(r'\n\n\n+', '\n\n', content)
    return content

# Get all files in directory
excluded = {'.git', 'remove_comments.ps1', 'comment_remover.py', 'input.txt'}
files = [f for f in os.listdir('.') if os.path.isfile(f) and f not in excluded]

print(f"Processing {len(files)} files...\n")

for filename in files:
    try:
        with open(filename, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        original_content = content
        
        # Detect file type and remove comments
        if filename.endswith('.py') or filename.endswith('.pyw'):
            content = remove_python_comments(content)
        else:  # Assume C++
            content = remove_cpp_comments(content)
        
        # Write back only if changed
        if content != original_content:
            with open(filename, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Processed: {filename}")
        else:
            print(f"No changes: {filename}")
    except Exception as e:
        print(f"Error with {filename}: {e}")

print("\nDone!")
