Simple UDP packet generator for sending and receiving small bits of data. Created with the Snabb framework.

**Requirements** 
1. Snabb binary file. 
2. NIC compatible with Snabb

(1) One can easily create this requirement by following the "How do I get started?" section from Snabb's GitHub: https://github.com/snabbco/snabb/tree/24c9a672f3a508fbc9f51eb5a9b6f238e92ee98b.  
(2) The list of compatible NICs is provided by this link: https://github.com/snabbco/snabb/blob/master/src/lib/hardware/pci.lua, line 61.

**Setup**
1. Clone this repository
2. Clone the snabb repository: https://github.com/snabbco/snabb/tree/24c9a672f3a508fbc9f51eb5a9b6f238e92ee98b
3. cp -r SnabbUDP/ snabb/src/program/
4. cd snabb
5. make -j
6. cd src
7. ./snabb SnabbUDP --help 


All personal user space tests were ran on a pair of c220g2 nodes (Intel X520 10Gb NIC) on CloudLab, using profile ConTools/Snabb: https://www.cloudlab.us/p/3ea481ea-db43-11e9-b1eb-e4434b2381fc.
