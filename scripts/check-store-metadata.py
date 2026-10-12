#!/usr/bin/env python3
fields={'name':('PulseCanvas Studio',30),'subtitle':('Music visuals made on your Mac',30),'keywords':('visualizer,music,video,audio,reactive,animation,beats,studio,4k,mp4,projectm,creative',100)}
for name,(value,limit) in fields.items():
    assert len(value)<=limit,(name,len(value),limit)
    print(f'{name}: {len(value)}/{limit}')
