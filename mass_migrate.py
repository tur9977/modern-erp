import os
import shutil
import re

old_dir = '/Users/nealmac/projects/double-erp/frontend/src/views/'
new_dir = '/Users/nealmac/.gemini/antigravity-ide/scratch/modern-erp/src/views/'
skip_files = ['Orders.vue', 'Customers.vue', 'InventoryItems.vue', 'Dashboard.vue', 'Placeholder.vue']

# Table mappings for endpoints (simplified heuristic for common patterns)
# E.g. /consignments/ -> erp_consignments
# We will do a generic replacement: this.$api.get('/(table)/') -> supabase.from('erp_$1').select('*')
# Note: this is a heuristic and might require manual fixes for complex queries.

def rewrite_axios_to_supabase(content):
    # Basic replacements
    content = content.replace("this.$api.get('/", "supabase.from('erp_")
    content = content.replace("this.$api.post('/", "supabase.from('erp_")
    content = content.replace("this.$api.put('/", "supabase.from('erp_")
    content = content.replace("this.$api.delete('/", "supabase.from('erp_")
    
    # We also need to inject import { supabase } if not present
    if "import { supabase }" not in content and "<script>" in content:
        content = content.replace("<script>", "<script>\nimport { supabase } from '../supabase'\n")
    return content

for filename in os.listdir(old_dir):
    if filename.endswith('.vue') and filename not in skip_files:
        old_path = os.path.join(old_dir, filename)
        new_path = os.path.join(new_dir, filename)
        
        with open(old_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        new_content = rewrite_axios_to_supabase(content)
        
        with open(new_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
            
print("Mass migration of Vue files complete.")
