import re

import numpy as np

ofms = []
for i in range(8):
    file_name = f"../../data/act/ofm_tile_lines_{i:0d}.txt"
    with open(file_name) as f:
        data = re.sub(r"\n", "", f.read())
        ofm = data.split(",")
        ofms.append(ofm)
        print(ofm[0])


with open("../../data/exp/ofm_dec_c32_h98_w98.txt") as f:
    data = re.sub(r"\n", "", f.read())
    ofm_exp = data.split(",")
    print(f"Length: { len(ofm_exp) }")
    print(ofm_exp[98])
