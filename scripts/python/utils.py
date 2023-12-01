from collections import abc
from itertools import repeat
from typing import Tuple, Union

import torch


def _ntuple(n, name="parse"):
    """Create tuple for x"""

    def parse(x):
        if isinstance(x, abc.Iterable):
            return tuple(x)
        return tuple(repeat(x, n))

    parse.__name__ = name
    return parse


_pair = _ntuple(2, "_pair")

Size2t = Union[int, Tuple[int, int]]


def setup_seed(seed):
    """Set random seed"""
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)


def bin2hex(data_bin: str) -> str:
    """Bin to hex"""
    bit_h4 = data_bin[:4]
    bit_l4 = data_bin[4:]
    hex_h: int = 0
    hex_l: int = 0
    for i, b in enumerate(bit_h4):
        if b == "1":
            hex_h += 2 ** (3 - i)

    for i, b in enumerate(bit_l4):
        if b == "1":
            hex_l += 2 ** (3 - i)

    return hex(hex_h)[2:] + hex(hex_l)[2:]
