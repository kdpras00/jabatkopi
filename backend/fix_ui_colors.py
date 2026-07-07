import re

path = 'resources/views/pages/pegawai/dashboard.blade.php'
with open(path, 'r') as f:
    content = f.read()

replacements = {
    'bg-red-500 text-white': 'bg-coffee-danger text-black',
    'bg-red-600': 'bg-coffee-danger/80',
    'bg-green-500 text-white': 'bg-coffee-success text-black',
    'bg-green-600': 'bg-coffee-success/80',
    'bg-indigo-500 text-white': 'bg-[#6366f1] text-white',
    'bg-indigo-600': 'bg-[#4f46e5]',
    'bg-blue-500 text-white': 'bg-[#3b82f6] text-white',
    'bg-blue-600': 'bg-[#2563eb]',
    'bg-amber-500 text-white': 'bg-[#f59e0b] text-black',
}

for old, new in replacements.items():
    content = content.replace(old, new)

with open(path, 'w') as f:
    f.write(content)

