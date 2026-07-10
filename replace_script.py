import re

with open('/Users/nealmac/.gemini/antigravity-ide/scratch/modern-erp/src/views/Dashboard.vue', 'r') as f:
    content = f.read()

with open('/Users/nealmac/.gemini/antigravity-ide/scratch/modern-erp/Dashboard_script.js', 'r') as f:
    new_script = f.read()

start_idx = content.find('<script setup>')
end_idx = content.find('</script>', start_idx) + len('</script>')

if start_idx != -1 and end_idx != -1:
    new_content = content[:start_idx] + new_script + content[end_idx:]
    with open('/Users/nealmac/.gemini/antigravity-ide/scratch/modern-erp/src/views/Dashboard.vue', 'w') as f:
        f.write(new_content)
    print("Replaced successfully")
else:
    print("Could not find <script setup> tags")
