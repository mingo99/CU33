"""
Generate data of testbench
"""
import argparse
import os

import numpy as np
import torch
from torch import nn
from utils import Size2t, _pair, bin2hex, setup_seed


class ConvData:
    """
    Used to manage data for 2D convolution.
    """

    def __init__(
        self,
        in_size: Size2t,
        in_channels: int,
        out_channels: int,
        kernel_size: int,
        stride: int = 1,
        padding: int = 0,
        groups: int = 1,
        bias=False,
        random=True,
        pea_size: Size2t = (3, 8),
        tile_width: int = 16,
    ) -> None:
        """Initial class"""
        ## Conv parameters
        if groups > 1:
            self.inchannels = 1
        else:
            self.inchannels = in_channels
        self.in_channels = in_channels
        self.out_channels = out_channels
        self.kernel_size = kernel_size
        self.stride = stride
        self.padding = padding
        self.groups = groups
        self.random = random

        self.in_size = _pair(in_size)
        self.out_size = self.get_outsize()

        self.conv2d = nn.Conv2d(
            in_channels=self.in_channels,
            out_channels=self.out_channels,
            kernel_size=self.kernel_size,
            stride=self.stride,
            padding=self.padding,
            groups=self.groups,
            bias=bias,
        )
        self.relu = nn.ReLU()

        ## Generate ifm, weight, ofm
        self.gen_infeaturemap()
        self.gen_weight()
        self.gen_outfeaturemap()
        self.tonumpy()

        self.pea_size = _pair(pea_size)
        self.tile_width = tile_width
        tile_col_offset = self.out_size[1] % (self.tile_width // self.stride)
        tile_row_offset = self.out_size[1] % (self.pea_size[1] // self.stride)
        self.tile_col_num = (
            (self.out_size[1] // (self.tile_width // self.stride))
            if tile_col_offset == 0
            else (self.out_size[1] // (self.tile_width // self.stride) + 1)
        )
        self.tile_row_num = (
            (self.out_size[0] // (self.pea_size[1] // self.stride))
            if tile_row_offset == 0
            else (self.out_size[0] // (self.pea_size[1] // self.stride) + 1)
        )

    def get_outsize(self):
        """Get size of outfeaturemap"""
        height = (
            self.in_size[0] + 2 * self.padding - self.kernel_size
        ) // self.stride + 1
        width = (
            self.in_size[1] + 2 * self.padding - self.kernel_size
        ) // self.stride + 1
        return (height, width)

    def gen_infeaturemap(self):
        """Generate infeaturemap randomly"""
        if self.random:
            ifm = (
                torch.rand(1, self.in_channels, self.in_size[0], self.in_size[1]) * 255
                - 128
            )
            ifm = torch.round(ifm)
        else:
            ifm = torch.ones(1, self.in_channels, self.in_size[0], self.in_size[1])
        self.ifm = ifm

    def gen_weight(self):
        """Generate weight randomly"""
        if self.random:
            weight = (
                torch.rand(
                    self.out_channels,
                    self.inchannels,
                    self.kernel_size,
                    self.kernel_size,
                )
                * 255
                - 128
            )
            weight = torch.round(weight)
        else:
            weight = torch.ones(
                self.out_channels,
                self.inchannels,
                self.kernel_size,
                self.kernel_size,
            )
        self.weight = weight

    def gen_outfeaturemap(self):
        """Calculate outfeature"""
        self.conv2d.weight = nn.Parameter(self.weight)
        ofm = self.conv2d(self.ifm)
        #  ofm = self.relu(ofm)
        ofm = ofm.type(torch.int32)
        self.ofm = ofm

    def tonumpy(self):
        """Convert tensor to array"""
        self.ifm_np = self.ifm.data.numpy().astype(int)
        self.weight_np = self.weight.data.numpy().astype(int)
        self.ofm_np = self.ofm.data.numpy().astype(int)

    def write_ifm(self, outdir, radix: str = "bin"):
        """
        Param:
            outdir[str]:output directory\n
            radix[str]:output radix, surpport `dec`, `bin`, `hex`
        """
        assert radix in [
            "dec",
            "bin",
            "hex",
        ], f"{radix} is not srpported, expected 'dec', 'bin', 'hex'"
        filename = os.path.join(
            outdir,
            f"ifm_{radix}_c{self.in_channels}_h{self.in_size[0]}_w{self.in_size[1]}.txt",
        )

        with open(filename, "w", encoding="utf-8") as f:
            print(self.pea_size)
            for nr in range(self.tile_row_num):
                for nt in range(self.tile_col_num):
                    for _ in range(self.out_channels):
                        for ic in range(self.in_channels):
                            for j in range(self.tile_width + self.kernel_size - 1):
                                col = nt * self.tile_width + j
                                if col >= self.in_size[1]:
                                    break

                                for i in range(sum(self.pea_size) - 1):
                                    row = nr * self.pea_size[1] + i
                                    # print(row, ic, nr)
                                    k = (
                                        self.ifm_np[0, ic, row, col]
                                        if (
                                            (row < self.in_size[0])
                                            and (col < self.in_size[1])
                                        )
                                        else 0
                                    )
                                    s = (
                                        str(k) + " "
                                        if radix == "dec"
                                        else np.binary_repr(k, 8) + " "
                                    )
                                    if radix == "hex":
                                        s = bin2hex(s) + " "
                                    f.write(s)
                                f.write("\n")
                        f.write("\n")
                        if self.groups > 1:
                            break
                    f.write("\n")
                f.write("\n")
            f.write("\n")

    def write_weight(self, outdir, radix: str = "bin"):
        """
        Param:
            radix[str]:output radix, surpport `dec`, `bin`, `hex`
        """
        assert radix in [
            "dec",
            "bin",
            "hex",
        ], f"{radix} is not srpported, expected 'dec', 'bin', 'hex'"
        filename = os.path.join(
            outdir,
            f"weight_{radix}_co{self.out_channels}_ci{self.in_channels}_k{self.kernel_size}_k{self.kernel_size}.txt",
        )
        with open(filename, "w", encoding="utf-8") as f:
            for _ in range(self.tile_row_num):
                for _ in range(self.tile_col_num):
                    for oc in range(self.out_channels):
                        for ic in range(self.inchannels):
                            for k in range(self.kernel_size):
                                for p in self.weight_np[oc, ic, :, k]:
                                    s = (
                                        str(p) + " "
                                        if radix == "dec"
                                        else np.binary_repr(p, 8) + " "
                                    )
                                    if radix == "hex":
                                        s = bin2hex(s) + " "
                                    f.write(s)
                                f.write("\n")
                            f.write("\n")
                        f.write("\n")
                    f.write("\n")
                f.write("\n")

    def write_ofm(self, outdir, radix: str = "bin"):
        """
        Param:
            radix[str]:output radix, surpport `dec`, `bin`, `hex`
        """
        assert radix in [
            "dec",
            "bin",
            "hex",
        ], f"{radix} is not srpported, expected 'dec', 'bin', 'hex'"
        filename = os.path.join(
            outdir,
            f"ofm_{radix}_c{self.out_channels}_h{self.out_size[0]}_w{self.out_size[1]}.txt",
        )
        with open(filename, "w", encoding="utf-8") as f:
            for oc in range(self.out_channels):
                for row in range(self.out_size[0]):
                    for col in range(self.out_size[1]):
                        k = self.ofm_np[0, oc, row, col]
                        s = (
                            str(k) + ","
                            if radix == "dec"
                            else np.binary_repr(k, 25) + " "
                        )
                        if radix == "hex":
                            s = bin2hex(s) + " "
                        f.write(s)
                        if (col + 1) % 16 == 0:
                            f.write("\n")
                    f.write("\n")
                f.write("\n")

    def write_ifm_raw(self, outdir, radix: str = "bin"):
        """
        Param:
            outdir[str]:output directory\n
            radix[str]:output radix, surpport `dec`, `bin`, `hex`
        """
        assert radix in [
            "dec",
            "bin",
            "hex",
        ], f"{radix} is not srpported, expected 'dec', 'bin', 'hex'"
        filename = os.path.join(
            outdir,
            f"ifm_raw_{radix}_c{self.in_channels}_h{self.in_size[0]}_w{self.in_size[1]}.txt",
        )
        with open(filename, "w", encoding="utf-8") as f:
            for c in range(self.in_channels):
                for row in range(self.in_size[0]):
                    for col in range(self.in_size[1]):
                        # print(row, c, nr)
                        k = (
                            self.ifm_np[0, c, row, col]
                            if ((row < self.in_size[0]) and (col < self.in_size[1]))
                            else 0
                        )
                        s = (
                            str(k) + " "
                            if radix == "dec"
                            else np.binary_repr(k, 8) + " "
                        )
                        if radix == "hex":
                            s = bin2hex(s) + " "
                        f.write(s)
                    f.write("\n")
                f.write("\n")
            f.write("\n")

    def write_weight_raw(self, outdir, radix: str = "bin"):
        """
        Param:
            radix[str]:output radix, surpport `dec`, `bin`, `hex`
        """
        assert radix in [
            "dec",
            "bin",
            "hex",
        ], f"{radix} is not srpported, expected 'dec', 'bin', 'hex'"
        filename = os.path.join(
            outdir,
            f"weight_raw_{radix}_co{self.out_channels}_ci{self.in_channels}_k{self.kernel_size}_k{self.kernel_size}.txt",
        )
        with open(filename, "w", encoding="utf-8") as f:
            for oc in range(self.out_channels):
                for ic in range(self.inchannels):
                    for k in range(self.kernel_size):
                        for p in self.weight_np[oc, ic, k, :]:
                            s = (
                                str(p) + " "
                                if radix == "dec"
                                else np.binary_repr(p, 8) + " "
                            )
                            if radix == "hex":
                                s = bin2hex(s) + " "
                            f.write(s)
                        f.write("\n")
                    f.write("\n")
                f.write("\n")


def get_args():
    """Get args"""
    parser = argparse.ArgumentParser()
    parser.add_argument("tile_height", default=8, type=int, help="tile height")
    parser.add_argument("tile_width", default=16, type=int, help="tile width")
    parser.add_argument("ifmsize", default=20, type=int, help="input feature map size")
    parser.add_argument("chi", default=2, type=int, help="input channel number")
    parser.add_argument("cho", default=2, type=int, help="output channel number")
    parser.add_argument("ksize", default=3, type=int, help="kernel size")
    parser.add_argument("stride", default=1, type=int, help="conv stride")
    parser.add_argument("group", default=1, type=int, help="conv stride")
    return parser.parse_args()


if __name__ == "__main__":
    args = get_args()
    ifm_size = args.ifmsize
    chi = args.chi
    cho = args.cho
    ksize = args.ksize
    stride = args.stride
    if args.group == 1:
        groups = args.cho
    else:
        groups = 1
    print(
        f"Generate data:\nCHI: {chi} \nCHO: {cho}\nIFM size: {ifm_size}\nKernel size: {ksize}\nStride: {stride}\nGroup: {groups}"
    )
    setup_seed(1122334)
    test_data = ConvData(
        in_size=ifm_size,
        in_channels=chi,
        out_channels=cho,
        kernel_size=ksize,
        stride=stride,
        groups=groups,
        pea_size=(ksize, args.tile_height),
        tile_width=args.tile_width,
    )

    OUTDIR = "../../data/exp"
    if not os.path.isdir(OUTDIR):
        os.makedirs(OUTDIR)

    print("Writing...")
    test_data.write_ifm(OUTDIR, "hex")
    test_data.write_ifm_raw(OUTDIR, "dec")
    test_data.write_ifm_raw(OUTDIR, "hex")
    test_data.write_weight(OUTDIR, "hex")
    test_data.write_weight_raw(OUTDIR, "dec")
    test_data.write_weight_raw(OUTDIR, "hex")
    test_data.write_ofm(OUTDIR, "dec")
