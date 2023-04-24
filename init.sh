#!bin/bash

pip install -r requirements.txt
pip install git+https://github.com/NVlabs/nvdiffrast/
# maybe more packages. need to update requirements.txt

# Clone Depth estimation repository
git clone https://github.com/ir1d/BoostingMonocularDepth.git

# Download model weights.
# If wget doesn't work, get the file manually and put it in right place.
wget https://sfu.ca/~yagiz/CVPR21/latest_net_G.pth
wget https://cloudstor.aarnet.edu.au/plus/s/lTIJF4vrvHCAI31/download

mv latest_net_G.pth BoostingMonocularDepth/pix2pix/checkpoints/mergemodel/
mv download /content/BoostingMonocularDepth/res101.pth

# !!! Do "huggingface-cli login" !!!