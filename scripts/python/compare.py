import argparse
import re

import numpy as np


def read_ofm_line(file, ofm_size, cho, tile_len):
    with open(file) as f:
        data = re.sub(r"\n", "", f.read())
        ofm = data.split(",")
        ofm.pop()
    line_chunk_size = ofm_size * cho
    lines_no_channel = [
        ofm[i : i + line_chunk_size] for i in range(0, len(ofm), line_chunk_size)
    ]

    lines_with_channel = []
    tile_chunk_size = tile_len * cho
    for line_nc in lines_no_channel:
        line = [
            line_nc[i : i + tile_chunk_size]
            for i in range(0, len(line_nc), tile_chunk_size)
        ]

        tile_last_with_chan = None
        line_with_channel = []   
        
        oft = ofm_size%tile_len
        if oft != 0:
            tile_last = line.pop()
            tile_last_with_chan =  np.array([tile_last[i:i+oft] for i in range(0,len(tile_last),oft)])

        for tile in line:
            tile_with_chan = np.array([tile[i:i+tile_len] for i in range(0,len(tile),tile_len)])
            line_with_channel.append(tile_with_chan)

        if oft != 0:
            line_with_channel.append(tile_last_with_chan)

        line_with_channel = np.concatenate(line_with_channel,axis=1)
        lines_with_channel.append(line_with_channel)

    lines_with_channel = np.array(lines_with_channel)
    lines_with_channel = lines_with_channel.transpose(1,0,2)

    return lines_with_channel


def get_act_ofm(ofm_size, cho, tile):
    ofm = np.zeros((cho,ofm_size,ofm_size))
    for i in range(8):
        file = f"../../data/act/ofm_tile_lines_{i:0d}.txt"
        ofm_lines = read_ofm_line(file, ofm_size, cho, tile)
        ofm[:,i::8, :] = ofm_lines

    return ofm


def get_exp_ofm():
    with open("../../data/exp/ofm_dec_c2_h18_w18.txt") as f:
        data = re.sub(r"\n", "", f.read())
        ofm_lines = data.split(",").pop()
        print(ofm_lines)
    # ofm = np.array(ofm_lines).reshape((2,18,18))
    ofm = np.array(ofm_lines)
    print(ofm)


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
    get_exp_ofm()
