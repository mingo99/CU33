import argparse
import os
import re

import numpy as np
from utils import bin2hex


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

        oft = ofm_size % tile_len
        print(f"oft: {oft}")
        if oft != 0:
            tile_last = line.pop()
            tile_last_with_chan = np.array(
                [tile_last[i : i + oft] for i in range(0, len(tile_last), oft)]
            )

        for tile in line:
            tile_with_chan = np.array(
                [tile[i : i + tile_len] for i in range(0, len(tile), tile_len)]
            )
            line_with_channel.append(tile_with_chan)

        if oft != 0:
            line_with_channel.append(tile_last_with_chan)

        line_with_channel = np.concatenate(line_with_channel, axis=1)
        lines_with_channel.append(line_with_channel)
        # print(line_with_channel)

    lines_with_channel = np.array(lines_with_channel)
    print(lines_with_channel.shape)
    lines_with_channel = lines_with_channel.transpose(1, 0, 2)

    return lines_with_channel


def get_act_ofm(tile_height, ofm_size, cho, tile_width, stride):
    ofm = np.zeros((cho, ofm_size, ofm_size))

    tile_height = tile_height // stride

    if ofm_size // tile_height == 0:  # ofm_size < tile_row
        valid_line_num = ofm_size % tile_height
    else:
        valid_line_num = tile_height
    print(valid_line_num)

    print("Extracting actual ofm file: ")
    for i in range(valid_line_num):
        file = f"../../data/act/ofm_tile_lines_{i*stride:0d}.txt"
        print(f"file: {file}")
        ofm_lines = read_ofm_line(file, ofm_size, cho, tile_width)
        ofm[:, i::valid_line_num, :] = ofm_lines

    print("Extracting done.\n")

    return ofm.astype(int)


def get_exp_ofm(exp_file, cho, ofm_size):
    print(f"Extracting expect ofm file:\nfile: {exp_file}")
    with open(exp_file) as f:
        data = re.sub(r"\n", "", f.read())
        ofm_lines = data.split(",")
        ofm_lines.pop()

    ofm = np.array(ofm_lines).reshape((cho, ofm_size, ofm_size)).astype(int)
    print("Extracting done.\n")

    return ofm


def write_ofm(ofm, outdir, radix: str = "bin"):
    """
    Param:
        radix[str]:output radix, surpport `dec`, `bin`, `hex`
    """
    assert radix in [
        "dec",
        "bin",
        "hex",
    ], f"{radix} is not srpported, expected 'dec', 'bin', 'hex'"
    ofm_shape = ofm.shape
    filename = os.path.join(
        outdir,
        f"ofm_{radix}_c{ofm_shape[0]}_h{ofm_shape[1]}_w{ofm_shape[2]}.txt",
    )
    with open(filename, "w", encoding="utf-8") as f:
        for oc in range(ofm_shape[0]):
            for row in range(ofm_shape[1]):
                for col in range(ofm_shape[2]):
                    k = ofm[oc, row, col]
                    s = str(k) + "," if radix == "dec" else np.binary_repr(k, 25) + " "
                    if radix == "hex":
                        s = bin2hex(s) + " "
                    f.write(s)
                    if (col + 1) % 16 == 0:
                        f.write("\n")
                f.write("\n")
            f.write("\n")


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("tile_height", default=8, type=int, help="tile height")
    parser.add_argument("tile_width", default=16, type=int, help="tile width")
    parser.add_argument("cho", default=2, type=int, help="output channel number")
    parser.add_argument("ifmsize", default=20, type=int, help="input feature map size")
    parser.add_argument("ksize", default=3, type=int, help="kernel size")
    parser.add_argument("stride", default=1, type=int, help="conv stride")
    return parser.parse_args()


if __name__ == "__main__":
    args = get_args()
    ofm_size = (args.ifmsize - args.ksize) // args.stride + 1
    tile_len = args.tile_width // args.stride

    act_ofm = get_act_ofm(args.tile_height, ofm_size, args.cho, tile_len, args.stride)

    ofm_exp_file = (
        f"../../data/exp/ofm_dec_c{args.cho:0d}_h{ofm_size:0d}_w{ofm_size:0d}.txt"
    )
    exp_ofm = get_exp_ofm(ofm_exp_file, args.cho, ofm_size)

    print(f"Expect ofm array shape: {exp_ofm.shape}")
    print(f"Actual ofm array shape: {act_ofm.shape}\n")
    # print(f"Expect ofm array:\n{exp_ofm}")
    # print(f"Actual ofm array:\n{act_ofm}")
    write_ofm(act_ofm, "../../data/act", radix="dec")

    res_comp = np.array_equal(act_ofm, exp_ofm)
    if res_comp:
        print("\033[32mVerification Passed!!!\033[0m")
    else:
        print("\033[31mVerification failed!!!\033[0m")
        index = np.where(act_ofm != exp_ofm)[0][0]
        print(f"Actual: {act_ofm[index]}")
        print(f"Expect: {exp_ofm[index]}")
