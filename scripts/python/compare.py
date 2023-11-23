import argparse
import re

import numpy as np


def read_ofm_line(file, ofm_size, cho, tile):
    with open(file) as f:
        data = re.sub(r"\n", "", f.read())
        ofm = data.split(",")
        ofm.pop()
    line_chunk_size = ofm_size * cho
    lines_no_channel = [
        ofm[i : i + line_chunk_size] for i in range(0, len(ofm), line_chunk_size)
    ]

    lines_with_channel = []
    tile_chunk_size = tile * cho
    for line_nc in lines_no_channel:
        line = [
            line_nc[i : i + tile_chunk_size]
            for i in range(0, len(line_nc), tile_chunk_size)
        ]
        print(line)
    print(ofm_size % tile)

    return lines_no_channel


def get_act_ofm(ofm_size, cho, tile):
    ofm_lines = []
    for i in range(8):
        file = f"../../data/act/ofm_tile_lines_{i:0d}.txt"
        ofm = read_ofm_line(file, ofm_size, cho, tile)
        # print(ofm)
        break
        # ofm_lines.append(ofm)
        # print(len(ofm))


# with open("../../data/exp/ofm_dec_c32_h98_w98.txt") as f:
#     data = re.sub(r"\n", "", f.read())
#     ofm_exp = data.split(",")
#     print(f"Length: { len(ofm_exp) }")
#     print(ofm_exp[98])


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("tile", default=16, type=int, help="length of tile")
    parser.add_argument("cho", default=2, type=int, help="output channel number")
    parser.add_argument("ifmsize", default=20, type=int, help="input feature map size")
    parser.add_argument("ksize", default=3, type=int, help="kernel size")
    parser.add_argument("stride", default=1, type=int, help="conv stride")
    return parser.parse_args()


if __name__ == "__main__":
    get_act_ofm(18, 2, 16)
