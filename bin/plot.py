#!/usr/bin/env python

import os
import sys

import pandas as pd

from matplotlib import pyplot as plt

def main():
    top = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))

    data_perf = pd.read_csv(f'{top}/out/data-linux-bps.tsv', sep='\t')
    data_loc = pd.read_csv(f'{top}/out/data-linux-loc.tsv', sep='\t')

    data = data_perf.merge(data_loc)

    plt.figure(figsize=[14, 7])
    plt.xlabel('Linux Version')
    plt.ylabel('Lines of Code')
    plt.plot(data['linux'], data['loc'], color='blue', label='lines')
    plt.legend()

    plt.twinx()
    plt.ylabel('Goodput')
    plt.plot(data['linux'], data['bps'], color='red', label='b/s')
    plt.legend(loc=1)

    plt.savefig(f'{top}/out/plot.png')
    plt.show()

if __name__ == '__main__':
    main()
