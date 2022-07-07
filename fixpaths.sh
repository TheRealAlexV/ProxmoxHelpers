#!/bin/bash
for i in `find . -type f -name "*" -not -name "fixpaths.sh"`;do
	echo "Patching $i";
	sed -i 's|tteck/Proxmox|TheRealAlexV/ProxmoxHelpers|g' $i;
done
