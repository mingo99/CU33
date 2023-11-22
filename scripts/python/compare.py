import argparse
import re

import numpy as np


def get_ofms():
    ofms = []
    for i in range(8):
        file_name = f"../../data/act/ofm_tile_lines_{i:0d}.txt"
        with open(file_name) as f:
            data = re.sub(r"\n", "", f.read())
            ofm = data.split(",")
            ofms.append(ofm)

    ofms = np.array(ofms)
    print(ofms)


# with open("../../data/exp/ofm_dec_c32_h98_w98.txt") as f:
#     data = re.sub(r"\n", "", f.read())
#     ofm_exp = data.split(",")
#     print(f"Length: { len(ofm_exp) }")
#     print(ofm_exp[98])


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("ifmsize", default=20, type=int, help="input feature map size")
    parser.add_argument("chi", default=2, type=int, help="input channel number")
    parser.add_argument("cho", default=2, type=int, help="output channel number")
    parser.add_argument("ksize", default=3, type=int, help="kernel size")
    parser.add_argument("stride", default=1, type=int, help="conv stride")
    return parser.parse_args()
