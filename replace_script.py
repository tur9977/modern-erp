import re

with open('/Users/nealmac/.gemini/antigravity-ide/scratch/modern-erp/src/views/Customers.vue', 'r') as f:
    content = f.read()

with open('/Users/nealmac/.gemini/antigravity-ide/scratch/modern-erp/Customers_script.js', 'r') as f:
    new_script = f.read()

# Replace everything from <script> to </script>
start_idx = content.find('<script>')
end_idx = content.find('</script>') + len('</script>')

if start_idx != -1 and end_idx != -1:
    new_content = content[:start_idx] + new_script + content[end_idx:]
    with open('/Users/nealmac/.gemini/antigravity-ide/scratch/modern-erp/src/views/Customers.vue', 'w') as f:
        f.write(new_content)
    print("Replaced successfully")
else:
    print("Could not find <script> tags")
