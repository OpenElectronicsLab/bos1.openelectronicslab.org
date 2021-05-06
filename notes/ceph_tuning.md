# Initial benchmark run before tuning:

    rook-ceph-tool# rados -p ceph-block-pool bench 10 write
    hints = 1
    Maintaining 16 concurrent writes of 4194304 bytes to objects of size 4194304 for up to 10 seconds or 0 objects
    Object prefix: benchmark_data_rook-ceph-tools-6f58686b5d-c2_28395
      sec Cur ops   started  finished  avg MB/s  cur MB/s last lat(s)  avg lat(s)
        0       0         0         0         0         0           -           0
        1      16        21         5   19.9716        20     0.91525    0.715733
        2      16        29        13   25.9772        32      1.8106      1.0061
        3      16        38        22   29.3131        36    0.729075     1.27299
        4      16        50        34   33.9791        48    0.837676     1.35585
        5      16        59        43   34.3792        36     3.82171     1.46022
        6      16        69        53   35.2986        40     1.04448      1.4879
        7      16        79        63   35.9684        40    0.603379     1.48448
        8      16        89        73   36.4608        40    0.613373     1.49986
        9      16        96        80   35.5207        28    0.588156     1.49561
       10      15       104        89    35.568        36     3.89784     1.50995
       11       6       104        98   35.6051        36     3.62931     1.59929
    Total time run:         11.5023
    Total writes made:      104
    Write size:             4194304
    Object size:            4194304
    Bandwidth (MB/sec):     36.1668
    Stddev Bandwidth:       7.25635
    Max bandwidth (MB/sec): 48
    Min bandwidth (MB/sec): 20
    Average IOPS:           9
    Stddev IOPS:            1.81409
    Max IOPS:               12
    Min IOPS:               5
    Average Latency(s):     1.64822
    Stddev Latency(s):      1.09224
    Max latency(s):         4.05506
    Min latency(s):         0.367808
    Cleaning up (deleting benchmark objects)
    Removed 104 objects
    Clean up completed and total clean up time :0.268528

    /var/lib/backups$ time borg init -e none test.borg
    (26.8, 23.9, 25.2) seconds

    /var/lib/backups$ time borg init -e none test.borg
    (0.674, 0.665, 0.664) seconds

# After adding ssds for the metadata:

    rados -p ceph-block-pool bench 10 write
    hints = 1
    Maintaining 16 concurrent writes of 4194304 bytes to objects of size 4194304 for up to 10 seconds or 0 objects
    Object prefix: benchmark_data_rook-ceph-tools-6f58686b5d-xg_10967
      sec Cur ops   started  finished  avg MB/s  cur MB/s last lat(s)  avg lat(s)
        0       0         0         0         0         0           -           0
        1      16        19         3   11.9958        12    0.988863    0.915911
        2      16        27        11   21.9933        32    0.874621      1.3336
        3      16        39        23    30.657        48     2.01856     1.61048
        4      16        50        34   33.9897        44     1.92308     1.53521
        5      16        57        41   32.7909        28     1.20596     1.51108
        6      16        65        49   32.6581        32    0.532992     1.48469
        7      16        78        62   35.4189        52     2.62443     1.59867
        8      16        84        68    33.991        24     0.65115     1.59451
        9      16        94        78   34.6564        40     0.72334      1.5842
       10      16       108        92   36.7864        56     1.45278     1.63762
       11       3       108       105   38.1679        52     1.47786     1.57319
    Total time run:         11.2316
    Total writes made:      108
    Write size:             4194304
    Object size:            4194304
    Bandwidth (MB/sec):     38.4628
    Stddev Bandwidth:       13.7827
    Max bandwidth (MB/sec): 56
    Min bandwidth (MB/sec): 12
    Average IOPS:           9
    Stddev IOPS:            3.44568
    Max IOPS:               14
    Min IOPS:               3
    Average Latency(s):     1.57166
    Stddev Latency(s):      0.708334
    Max latency(s):         3.09894
    Min latency(s):         0.348477
    Cleaning up (deleting benchmark objects)
    Removed 108 objects
    Clean up completed and total clean up time :0.0726087

# Network tuning

## initial iperf results

    kms15admin@kubeworker2:~$ iperf3 -c kubecontroller0.private.vpn.boletus0.bos1.openelectronicslab.org
    Connecting to host kubecontroller0.private.vpn.boletus0.bos1.openelectronicslab.org, port 5201
    [  5] local 172.16.6.4 port 43774 connected to 172.16.4.3 port 5201
    [ ID] Interval           Transfer     Bitrate         Retr  Cwnd
    [  5]   0.00-1.00   sec   159 MBytes  1.33 Gbits/sec   48    504 KBytes
    [  5]   1.00-2.00   sec   160 MBytes  1.34 Gbits/sec   60    434 KBytes
    [  5]   2.00-3.00   sec   161 MBytes  1.35 Gbits/sec    5    465 KBytes
    [  5]   3.00-4.00   sec   162 MBytes  1.36 Gbits/sec   41    407 KBytes
    [  5]   4.00-5.00   sec   164 MBytes  1.37 Gbits/sec    2    522 KBytes
    [  5]   5.00-6.00   sec   161 MBytes  1.35 Gbits/sec   15    537 KBytes
    [  5]   6.00-7.00   sec   164 MBytes  1.37 Gbits/sec   15    466 KBytes
    [  5]   7.00-8.00   sec   161 MBytes  1.35 Gbits/sec    7    485 KBytes
    [  5]   8.00-9.00   sec   164 MBytes  1.37 Gbits/sec   29    418 KBytes
    [  5]   9.00-10.00  sec   158 MBytes  1.32 Gbits/sec   15    410 KBytes
    - - - - - - - - - - - - - - - - - - - - - - - - -
    [ ID] Interval           Transfer     Bitrate         Retr
    [  5]   0.00-10.00  sec  1.58 GBytes  1.35 Gbits/sec  237             sender
    [  5]   0.00-10.04  sec  1.57 GBytes  1.35 Gbits/sec                  receiver

    kms15admin@kubeworker0:~$ iperf3 -c kubecontroller0.private.vpn.boletus0.bos1.openelectronicslab.org
    Connecting to host kubecontroller0.private.vpn.boletus0.bos1.openelectronicslab.org, port 5201
    [  5] local 172.16.4.4 port 46406 connected to 172.16.4.3 port 5201
    [ ID] Interval           Transfer     Bitrate         Retr  Cwnd
    [  5]   0.00-1.00   sec  1.14 GBytes  9.80 Gbits/sec    0   3.05 MBytes
    [  5]   1.00-2.00   sec  1.16 GBytes  9.93 Gbits/sec    0   3.05 MBytes
    [  5]   2.00-3.00   sec  1.14 GBytes  9.83 Gbits/sec    0   3.05 MBytes
    [  5]   3.00-4.00   sec  1.17 GBytes  10.0 Gbits/sec    0   3.05 MBytes
    [  5]   4.00-5.00   sec  1.16 GBytes  9.96 Gbits/sec    0   3.05 MBytes
    [  5]   5.00-6.00   sec  1.17 GBytes  10.0 Gbits/sec    0   3.05 MBytes
    [  5]   6.00-7.00   sec  1.17 GBytes  10.0 Gbits/sec    0   3.05 MBytes
    [  5]   7.00-8.00   sec  1.17 GBytes  10.1 Gbits/sec    0   3.05 MBytes
    [  5]   8.00-9.00   sec  1.17 GBytes  10.1 Gbits/sec    0   3.05 MBytes
    [  5]   9.00-10.00  sec  1.16 GBytes  9.97 Gbits/sec    0   3.05 MBytes
    - - - - - - - - - - - - - - - - - - - - - - - - -
    [ ID] Interval           Transfer     Bitrate         Retr
    [  5]   0.00-10.00  sec  11.6 GBytes  9.97 Gbits/sec    0             sender
    [  5]   0.00-10.04  sec  11.6 GBytes  9.93 Gbits/sec                  receiver

    kms15admin@boletus0:~$ iperf3 -c boletus3.backhaul.bos1.openelectronicslab.org
    Connecting to host boletus3.backhaul.bos1.openelectronicslab.org, port 5201
    [  5] local 172.16.1.10 port 51998 connected to 172.16.1.13 port 5201
    [ ID] Interval           Transfer     Bitrate         Retr  Cwnd
    [  5]   0.00-1.00   sec   576 MBytes  4.83 Gbits/sec  982    484 KBytes
    [  5]   1.00-2.00   sec   571 MBytes  4.79 Gbits/sec  1297    414 KBytes
    [  5]   2.00-3.00   sec   572 MBytes  4.79 Gbits/sec  1393    288 KBytes
    [  5]   3.00-4.00   sec   572 MBytes  4.81 Gbits/sec  1565    438 KBytes
    [  5]   4.00-5.00   sec   580 MBytes  4.87 Gbits/sec  1366    440 KBytes
    [  5]   5.00-6.00   sec   573 MBytes  4.81 Gbits/sec  1161    436 KBytes
    [  5]   6.00-7.00   sec   583 MBytes  4.89 Gbits/sec  1359    422 KBytes
    [  5]   7.00-8.00   sec   574 MBytes  4.81 Gbits/sec  1269    128 KBytes
    [  5]   8.00-9.00   sec   566 MBytes  4.75 Gbits/sec  1924    438 KBytes
    [  5]   9.00-10.00  sec   572 MBytes  4.80 Gbits/sec  1388    438 KBytes
    - - - - - - - - - - - - - - - - - - - - - - - - -
    [ ID] Interval           Transfer     Bitrate         Retr
    [  5]   0.00-10.00  sec  5.61 GBytes  4.82 Gbits/sec  13704             sender
    [  5]   0.00-10.04  sec  5.60 GBytes  4.79 Gbits/sec                  receiver

    kms15admin@boletus0:~$ iperf3 -c boletus3.wg-backhaul.bos1.openelectronicslab.org
    Connecting to host boletus3.wg-backhaul.bos1.openelectronicslab.org, port 5201
    [  5] local 172.16.2.10 port 51010 connected to 172.16.2.13 port 5201
    [ ID] Interval           Transfer     Bitrate         Retr  Cwnd
    [  5]   0.00-1.00   sec   153 MBytes  1.29 Gbits/sec   23    419 KBytes
    [  5]   1.00-2.00   sec   151 MBytes  1.27 Gbits/sec    3    414 KBytes
    [  5]   2.00-3.00   sec   150 MBytes  1.25 Gbits/sec   12    446 KBytes
    [  5]   3.00-4.00   sec   153 MBytes  1.28 Gbits/sec    4    470 KBytes
    [  5]   4.00-5.00   sec   146 MBytes  1.22 Gbits/sec    0    497 KBytes
    [  5]   5.00-6.00   sec   154 MBytes  1.30 Gbits/sec   18    457 KBytes
    [  5]   6.00-7.00   sec   149 MBytes  1.25 Gbits/sec   12    461 KBytes
    [  5]   7.00-8.00   sec   155 MBytes  1.30 Gbits/sec    4    466 KBytes
    [  5]   8.00-9.00   sec   154 MBytes  1.29 Gbits/sec   13    423 KBytes
    [  5]   9.00-10.00  sec   149 MBytes  1.25 Gbits/sec    7    433 KBytes
    - - - - - - - - - - - - - - - - - - - - - - - - -
    [ ID] Interval           Transfer     Bitrate         Retr
    [  5]   0.00-10.00  sec  1.48 GBytes  1.27 Gbits/sec   96             sender
    [  5]   0.00-10.04  sec  1.48 GBytes  1.26 Gbits/sec                  receiver

## after echo "connected" | sudo tee /sys/class/net/ibp2s0/mode


    kms15admin@boletus0:~$ iperf3 -c boletus3.backhaul.bos1.openelectronicslab.org
    Connecting to host boletus3.backhaul.bos1.openelectronicslab.org, port 5201
    [  5] local 172.16.1.10 port 55522 connected to 172.16.1.13 port 5201
    [ ID] Interval           Transfer     Bitrate         Retr  Cwnd
    [  5]   0.00-1.00   sec  1.49 GBytes  12.8 Gbits/sec    0   3.12 MBytes
    [  5]   1.00-2.00   sec  1.41 GBytes  12.1 Gbits/sec    0   3.12 MBytes
    [  5]   2.00-3.00   sec  1.45 GBytes  12.5 Gbits/sec    0   3.12 MBytes
    [  5]   3.00-4.00   sec  1.53 GBytes  13.1 Gbits/sec    0   3.12 MBytes
    [  5]   4.00-5.00   sec  1.40 GBytes  12.1 Gbits/sec    0   3.12 MBytes
    [  5]   5.00-6.00   sec  1.39 GBytes  11.9 Gbits/sec    1   3.12 MBytes
    [  5]   6.00-7.00   sec  1.41 GBytes  12.1 Gbits/sec    0   3.12 MBytes
    [  5]   7.00-8.00   sec  1.41 GBytes  12.1 Gbits/sec    0   3.12 MBytes
    [  5]   8.00-9.00   sec  1.40 GBytes  12.0 Gbits/sec    0   3.12 MBytes
    [  5]   9.00-10.00  sec  1.40 GBytes  12.0 Gbits/sec    0   3.12 MBytes
    - - - - - - - - - - - - - - - - - - - - - - - - -
    [ ID] Interval           Transfer     Bitrate         Retr
    [  5]   0.00-10.00  sec  14.3 GBytes  12.3 Gbits/sec    1             sender
    [  5]   0.00-10.04  sec  14.3 GBytes  12.2 Gbits/sec                  receiver

## after increasing the MTU to 65520 for infiniband, bridges, and vms:

    kms15admin@boletus0:~$ iperf3 -c boletus3.backhaul.bos1.openelectronicslab.org
    Connecting to host boletus3.backhaul.bos1.openelectronicslab.org, port 5201
    [  5] local 172.16.1.10 port 55878 connected to 172.16.1.13 port 5201
    [ ID] Interval           Transfer     Bitrate         Retr  Cwnd
    [  5]   0.00-1.00   sec  1.40 GBytes  12.0 Gbits/sec    0   2.31 MBytes
    [  5]   1.00-2.00   sec  1.39 GBytes  12.0 Gbits/sec    0   2.31 MBytes
    [  5]   2.00-3.00   sec  1.40 GBytes  12.0 Gbits/sec    0   2.43 MBytes
    [  5]   3.00-4.00   sec  1.40 GBytes  12.0 Gbits/sec    0   2.43 MBytes
    [  5]   4.00-5.00   sec  1.40 GBytes  12.0 Gbits/sec    0   3.75 MBytes
    [  5]   5.00-6.00   sec  1.41 GBytes  12.1 Gbits/sec    0   3.75 MBytes
    [  5]   6.00-7.00   sec  1.39 GBytes  11.9 Gbits/sec    0   3.75 MBytes
    [  5]   7.00-8.00   sec  1.37 GBytes  11.8 Gbits/sec    0   3.75 MBytes
    [  5]   8.00-9.00   sec  1.33 GBytes  11.5 Gbits/sec    0   3.75 MBytes
    [  5]   9.00-10.00  sec  1.32 GBytes  11.4 Gbits/sec    0   3.75 MBytes
    - - - - - - - - - - - - - - - - - - - - - - - - -
    [ ID] Interval           Transfer     Bitrate         Retr
    [  5]   0.00-10.00  sec  13.8 GBytes  11.9 Gbits/sec    0             sender
    [  5]   0.00-10.04  sec  13.8 GBytes  11.8 Gbits/sec                  receiver

    kms15admin@kubeworker2:~$ iperf3 -c kubecontroller0.private.vpn.boletus0.bos1.openelectronicslab.org
    Connecting to host kubecontroller0.private.vpn.boletus0.bos1.openelectronicslab.org, port 5201
    [  5] local 172.16.6.4 port 42684 connected to 172.16.4.3 port 5201
    [ ID] Interval           Transfer     Bitrate         Retr  Cwnd
    [  5]   0.00-1.00   sec  1008 MBytes  8.45 Gbits/sec    0   3.12 MBytes
    [  5]   1.00-2.00   sec  1024 MBytes  8.59 Gbits/sec    0   3.12 MBytes
    [  5]   2.00-3.00   sec   991 MBytes  8.32 Gbits/sec    0   3.12 MBytes
    [  5]   3.00-4.00   sec   978 MBytes  8.20 Gbits/sec    0   3.12 MBytes
    [  5]   4.00-5.00   sec  1.01 GBytes  8.65 Gbits/sec    0   3.12 MBytes
    [  5]   5.00-6.00   sec  1015 MBytes  8.51 Gbits/sec    0   3.12 MBytes
    [  5]   6.00-7.00   sec  1014 MBytes  8.50 Gbits/sec    0   3.12 MBytes
    [  5]   7.00-8.00   sec  1.00 GBytes  8.60 Gbits/sec    0   3.12 MBytes
    [  5]   8.00-9.00   sec  1021 MBytes  8.57 Gbits/sec    0   3.12 MBytes
    [  5]   9.00-10.00  sec  1011 MBytes  8.48 Gbits/sec    0   3.12 MBytes
    - - - - - - - - - - - - - - - - - - - - - - - - -
    [ ID] Interval           Transfer     Bitrate         Retr
    [  5]   0.00-10.00  sec  9.88 GBytes  8.49 Gbits/sec    0             sender
    [  5]   0.00-10.04  sec  9.88 GBytes  8.45 Gbits/sec                  receiver

    [root@rook-ceph-tools-6f58686b5d-b7mgj /]# rados -p ceph-block-pool bench 10 write
    hints = 1
    Maintaining 16 concurrent writes of 4194304 bytes to objects of size 4194304 for up to 10 seconds or 0 objects
    Object prefix: benchmark_data_rook-ceph-tools-6f58686b5d-b7_638
      sec Cur ops   started  finished  avg MB/s  cur MB/s last lat(s)  avg lat(s)
        0       0         0         0         0         0           -           0
        1      16        37        21   83.9525        84    0.508472    0.554249
        2      16        71        55   109.774       136     0.48895    0.536643
        3      16       102        86   114.494       124    0.487855    0.517883
        4      16       133       117   116.857       124    0.383766    0.512991
        5      16       164       148   118.276       124    0.517819    0.512917
        6      16       194       178   118.555       120     0.32463    0.507519
        7      16       226       210    119.89       128    0.468938    0.515137
        8      16       257       241     120.4       124    0.487293    0.517432
        9      16       287       271   120.352       120    0.654282    0.519893
       10      16       316       300   119.913       116    0.538679    0.518868
    Total time run:         10.4021
    Total writes made:      316
    Write size:             4194304
    Object size:            4194304
    Bandwidth (MB/sec):     121.514
    Stddev Bandwidth:       13.7275
    Max bandwidth (MB/sec): 136
    Min bandwidth (MB/sec): 84
    Average IOPS:           30
    Stddev IOPS:            3.43188
    Max IOPS:               34
    Min IOPS:               21
    Average Latency(s):     0.518151
    Stddev Latency(s):      0.157709
    Max latency(s):         1.12884
    Min latency(s):         0.161669
    Cleaning up (deleting benchmark objects)
    Removed 316 objects
    Clean up completed and total clean up time :0.196541

    /var/lib/backups$ time borg init -e none test.borg
    (27.1, 26.7, 28.0) seconds
