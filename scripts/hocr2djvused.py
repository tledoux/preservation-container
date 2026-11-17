#!/usr/bin/python3
# -*- coding: utf-8 -*-
import os
import re
import sys
from io import StringIO

from lxml import etree

SPECIAL_CHARACTERS = {
    7: 'a',  # BELL
    8: 'b',  # BS
    9: 't',  # HT
    10: 'n',  # LF
    11: 'v',  # VT
    12: 'f',  # FF
    13: 'r',  # CR
    34: '"',  # DOUBLEQUOTE
    134: '\\',  # BACKSLASH
}


def encode_str(text):
    buf = StringIO()
    buf.write('"')
    for b in bytearray(text, 'utf-8'):
        sp = SPECIAL_CHARACTERS.get(b)
        if sp:
            buf.write('\\' + sp)
        elif 32 <= b <= 126:
            buf.write(chr(b))
        else:
            buf.write('\\' + oct(b)[2:])
    buf.write('"')
    return buf.getvalue()


class BBox:
    BBOX_RE = re.compile(r'bbox (\d+) (\d+) (\d+) (\d+)')

    def __init__(self, node):
        match = self.BBOX_RE.search(node.get('title'))
        self.x0 = int(match.group(1))
        self.y0 = int(match.group(2))
        self.x1 = int(match.group(3))
        self.y1 = int(match.group(4))


class Processor:
    CLASS_MAP = {
        'ocr_page': 'page',
        'ocr_carea': 'column',
        'ocr_par': 'para',
        'ocr_line': 'line',
        'ocr_textfloat': 'line',
        'ocr_header': 'line',
        'ocrx_word': 'word',
        'ocr_caption': 'line',
    }

    def __init__(self, input, output=None):
        self.y = None
        self.output = output and open(output, 'w', encoding='ascii') or sys.stdout

        try:
            # select page 1
            self.output.write('select 1\n')
            # remove existing text layer
            self.output.write('remove-txt\n')
            with open(input, encoding='utf-8') as f:
                tree = etree.parse(f)
                root = tree.getroot()
                nsmap = {'x': root.nsmap[None]}
                # verify that there is a word found in the ocr
                if root.xpath('boolean(//x:span[@class="ocrx_word"])', namespaces=nsmap):
                    self.output.write('set-txt\n')
                    self.process(root.xpath('x:body/x:div[@class="ocr_page"]', namespaces=nsmap)[0])
                    self.output.write('\n.\n')
        finally:
            if output:
                self.output.close()

    def process(self, node, level=0):
        type = self.CLASS_MAP[node.get('class')]
        bb = BBox(node)
        if type == 'page':
            self.y = bb.y1
        else:
            bb.y0 = self.y - bb.y0
            bb.y1 = self.y - bb.y1
        if level > 0:
            self.output.write('\n' + ' ' * level)
        self.output.write(f'({type} {bb.x0} {bb.y0} {bb.x1} {bb.y1}')
        if type == 'word':
            self.output.write(' ')
            self.output.write(encode_str(node.text))
        for child in node.getchildren():
            self.process(child, level + 1)
        self.output.write(')')


if __name__ == '__main__':
    Processor(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)