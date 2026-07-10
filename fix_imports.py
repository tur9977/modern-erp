import os
import re

dir_path = '/Users/nealmac/.gemini/antigravity-ide/scratch/modern-erp/src/views/'

for filename in os.listdir(dir_path):
    if filename.endswith('.vue'):
        filepath = os.path.join(dir_path, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Remove import apiClient from '../api/axios'
        new_content = re.sub(r"import\s+apiClient\s+from\s+['\"].*?axios['\"];?\n?", "", content)
        
        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
                
print("Removed old axios imports.")
