Simple UDP packet generator for sending and receiving small bits of data. Created with the Snabb framework.

**Requirements** 
1. Snabb binary file. 
2. NIC compatible with Snabb

(1) One can easily create this requirement by following the "How do I get started?" section from Snabb's GitHub: https://github.com/snabbco/snabb.git.  
(2) The list of compatible NICs is provided by this link: https://github.com/snabbco/snabb/blob/master/src/lib/hardware/pci.lua, line 61.

**Setup**
1. Clone this repository: https://github.com/NolanRudolph/SnabbUDP.git
2. Clone the snabb repository: https://github.com/snabbco/snabb.git
3. cd SnabbUDP
4. bash automake.sh
5. A binary executable named "snabb" can be found in ~/snabb/src. cd into ~/snabb/src, and call ./snabb SnabbUDP to acquire instructions on how to run my program

All personal user space tests were ran on a pair of c220g2 nodes (Intel X520 10Gb NIC) on CloudLab, using profile ConTools/Snabb: https://www.cloudlab.us/p/3ea481ea-db43-11e9-b1eb-e4434b2381fc.
