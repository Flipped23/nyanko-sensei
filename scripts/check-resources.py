#!/usr/bin/env python3
"""Validate manifest counts, PNG dimensions/alpha, and required runtime states."""
import json,struct,zlib
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'Resources'
specs=json.loads((root/'animations.json').read_text())
assert len(specs)==24, 'Expected 24 animation groups'
count=0
for state,spec in specs.items():
    assert spec['count']>0 and spec['duration']>0, state
    for i in range(spec['count']):
        path=root/state/f'{i}.png';data=path.read_bytes()
        assert data[:8]==b'\x89PNG\r\n\x1a\n', path
        width,height,depth,color=struct.unpack('>IIBB',data[16:26])
        assert (width,height,depth,color)==(384,416,8,6),(path,width,height,depth,color)
        offset=8
        while offset<len(data):
            length=struct.unpack('>I',data[offset:offset+4])[0]
            body=data[offset+4:offset+8+length]
            crc=struct.unpack('>I',data[offset+8+length:offset+12+length])[0]
            assert zlib.crc32(body)&0xffffffff==crc, path
            offset+=12+length
        count+=1
assert specs['lookA']['count']==specs['lookB']['count']==8
assert count==108,count
print(f'OK: {len(specs)} groups, {count} RGBA PNG frames, 16 gaze directions')
