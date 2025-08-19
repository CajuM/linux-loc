#!/usr/bin/env python

import re
import sys

import matplotlib.ticker as plticker
import numpy as np

from pathlib import Path

from matplotlib import pyplot as plt

def kver_to_int(kver):
    kver = kver.split('.')
    kver = [int(c) for c in kver]

    if len(kver) == 2:
        kver += [0]

    ret = 0
    for c in kver:
        ret *= 100
        ret += c

    return ret

def get_loc(root):
    ret = []

    for fname in root.glob(f'loc-*.txt'):
        with open(fname) as f:
            kver = re.findall(r'loc-([\d\.]+).txt$', str(fname))[-1]
            loc = int(f.read())

            ret.append((kver, loc))

    ret.sort(key=lambda c: kver_to_int(c[0]))
    return ret

def get_exp(root):
    ret = []

    for fname in root.glob(f'exp-*-2.log'):
        with open(fname, 'rb') as f:
            f = f.read()
            f = re.findall(rb'pps=(\d+)', f)
            f = [int(c) for c in f]
            f = [c for c in f if c]

            kver = re.findall(r'([\d\.]+)-2\.log$', str(fname))[-1]

            l = len(f)
            if l == 0:
                mean_pps = 0
            else:
                mean_pps = sum(f) / l

            ret.append((kver, mean_pps))

    ret.sort(key=lambda c: kver_to_int(c[0]))
    return ret

def plot_exp(exp, loc):
    x = [c[0] for c in exp]
    y = [c[1] for c in exp]

    x_loc = [c[0] for c in loc]
    y_loc = [c[1] for c in loc]

    loc = plticker.MultipleLocator(base=5.0)

    fig, ax1 = plt.subplots()

    ax1.set_ylabel('pps')
    ax1.xaxis.set_major_locator(loc)
    ax1.plot(x, y)

    ax2 = ax1.twinx()

    ax2.set_ylabel('loc')
    ax2.xaxis.set_major_locator(loc)
    ax2.plot(x_loc, y_loc, color='orange')

    plt.show()

def main(root):
    root = Path(root)

    exp = get_exp(root)
    loc = get_loc(root)

    plot_exp(exp, loc)

    x = np.array([c[0] for c in exp])
    y = np.array([c[1] for c in exp])

    dy = np.abs(y[1:] - y[:-1])
    arg = np.argwhere(dy > 5e5)[:, 0]

    dx = x[arg]
    print(dx)

if __name__ == '__main__':
    main(sys.argv[1])
