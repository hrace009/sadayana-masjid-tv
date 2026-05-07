"""Update plan/feature-slideshow-pengumuman-1.md completion status."""
import re

plan_path = 'plan/feature-slideshow-pengumuman-1.md'

with open(plan_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Update last_updated
old_date = 'last_updated: "2026-05-06"'
new_date = 'last_updated: "2026-05-07"'
if old_date in content:
    content = content.replace(old_date, new_date)
    print('last_updated: updated to 2026-05-07')
else:
    print('last_updated: already up to date or not found')

# Update TASK-044 and TASK-045 (completed during Phase 5 implementation)
tasks = [('TASK-044', '2026-05-06'), ('TASK-045', '2026-05-06')]
for task, date in tasks:
    pattern = r'(\| ' + task + r' \|[^\|]+\|)\s*\|\s*\|'
    checkmark = '\u2705'
    replacement = r'\1 ' + checkmark + r'         | ' + date + ' |'
    new_content = re.sub(pattern, replacement, content)
    if new_content != content:
        print(f'{task}: updated to {date}')
        content = new_content
    else:
        print(f'{task}: pattern not matched')
        # Debug: find the line
        for i, line in enumerate(content.split('\n')):
            if task in line:
                print(f'  Line {i+1}: {repr(line[:120])}')

with open(plan_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Done.')
