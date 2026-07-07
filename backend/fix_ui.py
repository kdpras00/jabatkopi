import re

path = 'resources/views/pages/pegawai/dashboard.blade.php'
with open(path, 'r') as f:
    content = f.read()

replacements = {
    # Statuses
    'bg-amber-500/15 text-amber-500 border border-amber-500/30': 'bg-amber-500 text-white',
    'bg-indigo-500/15 text-indigo-400 border border-indigo-500/30': 'bg-indigo-500 text-white',
    'bg-blue-500/15 text-blue-400 border border-blue-500/30': 'bg-blue-500 text-white',
    'bg-coffee-success/15 text-coffee-success border border-coffee-success/30': 'bg-green-500 text-white',
    'bg-neutral-800 text-coffee-muted border border-neutral-700': 'bg-neutral-500 text-white',
    'bg-coffee-danger/15 text-coffee-danger border border-coffee-danger/30': 'bg-red-500 text-white',
    'bg-red-500/15 text-red-500 border border-red-500/30': 'bg-red-500 text-white',
    'bg-red-500/15 text-red-400 border border-red-500/30': 'bg-red-500 text-white',
    
    # Buttons
    'bg-indigo-500/15 border border-indigo-500/30 text-indigo-400 rounded font-semibold hover:bg-indigo-500/30': 'bg-indigo-500 text-white rounded font-semibold hover:bg-indigo-600 shadow-none border-none',
    'bg-coffee-danger/15 border border-coffee-danger/30 text-coffee-danger rounded font-semibold hover:bg-coffee-danger/30': 'bg-red-500 text-white rounded font-semibold hover:bg-red-600 shadow-none border-none',
    'bg-blue-500/15 border border-blue-500/30 text-blue-400 rounded font-semibold hover:bg-blue-500/30': 'bg-blue-500 text-white rounded font-semibold hover:bg-blue-600 shadow-none border-none',
    'bg-coffee-success/15 border border-coffee-success/30 text-coffee-success rounded font-semibold hover:bg-coffee-success/30': 'bg-green-500 text-white rounded font-semibold hover:bg-green-600 shadow-none border-none',
    'bg-neutral-700 border border-neutral-600 text-coffee-text rounded font-semibold hover:bg-neutral-650': 'bg-neutral-600 text-white rounded font-semibold hover:bg-neutral-700 shadow-none border-none',
    
    # Bebaskan buttons
    'bg-coffee-danger/10 border border-coffee-danger/20 text-coffee-danger hover:bg-coffee-danger/20': 'bg-red-500 text-white hover:bg-red-600 shadow-none border-none',
    'text-coffee-danger hover:text-coffee-danger/80': 'bg-red-500 text-white px-2 py-1 rounded hover:bg-red-600 shadow-none border-none text-xs font-semibold',
    
    # Adjust Bebaskan icon to be white
    'text-[10px] px-2 py-0.5 bg-red-500': 'text-[10px] px-2 py-1 bg-red-500',
    'text-[10px] px-1.5 py-0.5 bg-red-500': 'text-[10px] px-2 py-1 bg-red-500',
    
    # Extra buttons
    'bg-blue-500/15 border border-blue-500/30 text-blue-500 rounded font-semibold hover:bg-blue-500/30': 'bg-blue-500 text-white rounded font-semibold hover:bg-blue-600 shadow-none border-none',
}

for old, new in replacements.items():
    content = content.replace(old, new)

with open(path, 'w') as f:
    f.write(content)

