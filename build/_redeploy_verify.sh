#!/bin/sh
sh /tmp/_deploy_cell3.sh 2>&1 | head -4
rm -f /tmp/kpc-cell-detail.json
echo "---- verify ----"
sh /tmp/_verify_cell.sh 2>&1 | head -14
