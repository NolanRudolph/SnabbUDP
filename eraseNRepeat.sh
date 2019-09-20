rm -rf ~/snabb/src/SnabbUDP
rm -rf ~/snabb/src/obj/program/SnabbUDP
rm ~/snabb/src/snabb
cp -r ~/SnabbUDP ~/snabb/src/program
make -j -C ~/snabb
