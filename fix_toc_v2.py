#!/usr/bin/env python3
"""
Properly fix the TOC in the Word document.
Remove manual TOC entries and keep only the TOC field.
"""

from docx import Document
from docx.oxml.ns import qn
from lxml import etree

doc = Document('DDS_Signal_Generator_结题报告_Zynq.docx')

# Strategy: Find the paragraph with "目录" that contains the TOC field,
# then remove all paragraphs between it and "项目背景与需求"

body = doc.element.body
all_paragraphs = list(body.iter(qn('w:p')))

toc_field_para = None
body_start_para = None
toc_text = None

# Find paragraphs
for i, p_elem in enumerate(all_paragraphs):
    # Get text content
    texts = []
    for t in p_elem.iter(qn('w:t')):
        if t.text:
            texts.append(t.text)
    full_text = ''.join(texts).strip()

    # Check if this has a TOC field
    has_toc = False
    for instr in p_elem.iter(qn('w:instrText')):
        if instr.text and 'TOC' in instr.text:
            has_toc = True
            break

    if has_toc:
        toc_field_para = p_elem
        print(f"Found TOC field at paragraph index {i}: '{full_text[:50]}'")

    if full_text == '项目背景与需求':
        body_start_para = p_elem
        print(f"Found '项目背景与需求' at paragraph index {i}")
        break

if toc_field_para is None:
    print("ERROR: TOC field paragraph not found!")
    exit(1)

if body_start_para is None:
    print("ERROR: '项目背景与需求' paragraph not found!")
    exit(1)

# Now remove all paragraphs between TOC field paragraph and body_start_para
# We need to work with the parent (body element) and remove siblings
paras_to_remove = []
current = toc_field_para.getnext()
while current is not None and current != body_start_para:
    if current.tag == qn('w:p'):
        paras_to_remove.append(current)
    current = current.getnext()

print(f"Found {len(paras_to_remove)} paragraphs to remove between TOC and body")

for p in paras_to_remove:
    parent = p.getparent()
    parent.remove(p)

print("Removed manual TOC paragraphs")

# Save
doc.save('DDS_Signal_Generator_结题报告_Zynq.docx')
print("Document saved successfully!")
print("\nTo generate the clickable TOC:")
print("1. Open the document in Microsoft Word")
print("2. Right-click on the TOC area")
print("3. Select 'Update Field' -> 'Update entire table'")
print("4. The TOC will now have clickable links (Ctrl+Click to follow)")
