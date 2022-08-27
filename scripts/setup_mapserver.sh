#!/bin/sh

# Downloads NAIP imagery and creates a VRT file in the appropriate folder for the
# camptocamp/mapserver Docker container.

# Check that the map raster Google Drive link was provided
if [ -z "$GDOWN_ID" ]; then \
  tput setaf 1; \
  echo -e "\$GDOWN_ID is empty! Provide it with --env GDOWN_ID=\"url\"."; \
  tput sgr0; \
  exit 1; \
fi

cd /etc/mapserver

# Download NAIP imagery
ZIP_FILENAME="usda-fsa-naip-san-mateo-ca-2020.zip"  # does not have to match uploaded file name
apt-get update && apt-get -y install unzip python3-pip
pip3 install gdown
if ! [ -f "$ZIP_FILENAME" ]; then \
  echo -e "Downloading NAIP imagery."; \
  gdown $GDOWN_URL -O $ZIP_FILENAME; \
  unzip $ZIP_FILENAME; \
fi

# Create VRT file from NAIP GeoTIFFs
# VRT file name should match with what is configured in Mapfile
VRT_FILENAME="naip.vrt"
if ! [ -f "$VRT_FILENAME" ]; then \
  echo -e "Creating VRT file."; \
  gdalbuildvrt $VRT_FILENAME *.tif; \
fi

# Setup complete, start MapServer
/usr/local/bin/start-server