#!/bin/sh

# Downloads NAIP imagery, OSM Buildings data, and creates a VRT file in the appropriate folder for the
# camptocamp/mapserver Docker container.

# Check that the NAIP map raster Google Drive link was provided
if [ -z "$NAIP_GDOWN_ID" ]; then \
  tput setaf 1; \
  echo -e "\$NAIP_GDOWN_ID is empty! Provide it with --env NAIP_GDOWN_ID=\"url\"."; \
  tput sgr0; \
  exit 1; \
fi

cd /etc/mapserver

# Install tools to download and unzip maps from Google Drive
apt-get update && apt-get -y install unzip python3-pip
pip3 install gdown

# Download NAIP raster imagery
NAIP_ZIP_FILENAME="usda-fsa-naip-san-mateo-ca-2020.zip"  # does not have to match uploaded file name
if ! [ -f "$NAIP_ZIP_FILENAME" ]; then \
  echo -e "Downloading NAIP imagery..."; \
  gdown $NAIP_GDOWN_ID -O $NAIP_ZIP_FILENAME; \
  unzip $NAIP_ZIP_FILENAME; \
fi

# Download OSM Buildings vector data if download ID given
OSM_ZIP_FILENAME="osm-buildings-ksql-airport.zip"  # does not have to match uploaded file name
if ! [ -z "$OSM_GDOWN_ID" ] && ! [ -f "$OSM_ZIP_FILENAME" ]; \
  then \
    echo -e "Downloading OSM Buildings data..."; \
    gdown $OSM_GDOWN_ID -O $OSM_ZIP_FILENAME; \
    unzip $OSM_ZIP_FILENAME; \
  else \
    echo -e "No download ID for OSM Buildings data provided or data already downloaded, skipping download."; \
fi

# Create VRT file from NAIP GeoTIFFs
# VRT file name should match with what is configured in Mapfile
VRT_FILENAME="naip.vrt"
if ! [ -f "$VRT_FILENAME" ]; then \
  echo -e "Creating VRT file."; \
  gdalbuildvrt $VRT_FILENAME *.tif; \
fi

# Rasterize OSM Buildings vectors into a VRT file
OSM_ZIP_FILENAME="osm-buildings-ksql-airport.zip"  # does not have to match uploaded file name
if ! [ -z "$OSM_GDOWN_ID" ]; \
  then \
    echo -e "Rasterizing OSM Buildings data..."; \
    gdal_rasterize -a height -ts $(gdalinfo $VRT_FILENAME |grep "Size is" |cut -d\  -f3-4 |sed "s/,//") \
      osm-buildings-ksql-airport.geojson \
      osm-buildings-ksql-airport.tif
  else \
    echo -e "No download ID for OSM Buildings data provided, skipping rasterization."; \
fi


# Setup complete, start MapServer with default mapfile
MS_MAPFILE=/etc/mapserver/mapserver.map
export MS_MAPFILE
/usr/local/bin/start-server