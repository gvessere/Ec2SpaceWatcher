#!/bin/bash
echo "unfreezing file system $1 - we are done provisioning more space"
fsfreeze --unfreeze $1


