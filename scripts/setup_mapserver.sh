#!/bin/sh

# Downloads NAIP imagery, OSM Buildings data, and creates a VRT file in the appropriate folder for the
# camptocamp/mapserver Docker container.

# Check that the NAIP map raster Google Drive link was provided
if [ -z "$NAIP_GDOWN_ID" ]; then \
  tput setaf 1; \
  echo "\$NAIP_GDOWN_ID is empty! Provide it with --env NAIP_GDOWN_ID=\"url\"."; \
  tput sgr0; \
  exit 1; \
fi

cd /etc/mapserver

# Install tools to download and unzip maps from Google Drive
apt-get update && apt-get -y install unzip python3-pip wget
pip3 install gdown

# Download NAIP raster imagery
NAIP_ZIP_FILENAME="usda-fsa-naip-san-mateo-ca-2020.zip"  # does not have to match uploaded file name
if ! [ -f "$NAIP_ZIP_FILENAME" ]; then \
  echo "Downloading NAIP imagery..."; \
  gdown $NAIP_GDOWN_ID -O $NAIP_ZIP_FILENAME; \
  unzip $NAIP_ZIP_FILENAME; \
fi

# Download OSM Buildings vector data if download ID given
OSM_ZIP_FILENAME="osm-buildings-ksql-airport.zip"  # does not have to match uploaded file name
if ! [ -z "$OSM_GDOWN_ID" ] && ! [ -f "$OSM_ZIP_FILENAME" ]; \
  then \
    echo "Downloading OSM Buildings data..."; \
    gdown $OSM_GDOWN_ID -O $OSM_ZIP_FILENAME; \
    unzip $OSM_ZIP_FILENAME; \
  else \
    echo "No download ID for OSM Buildings data provided or data already downloaded, skipping download."; \
fi

# Create VRT file from NAIP GeoTIFFs
# VRT file name should match with what is configured in Mapfile
VRT_FILENAME="naip.vrt"
if ! [ -f "$VRT_FILENAME" ]; then \
  echo "Creating VRT file."; \
  gdalbuildvrt $VRT_FILENAME *.tif; \
fi

# Rasterize OSM Buildings vectors into a VRT file
OSM_ZIP_FILENAME="osm-buildings-ksql-airport.zip"  # does not have to match uploaded file name
OSM_TIF_FILENAME="osm-buildings-ksql-airport.tif"
if ! [ -z "$OSM_GDOWN_ID" ] && ! [ -f "$OSM_TIF_FILENAME" ]; \
  then \
    echo "Rasterizing OSM Buildings data..."; \
    gdal_rasterize -a height -ts $(gdalinfo $VRT_FILENAME |grep "Size is" |cut -d\  -f3-4 |sed "s/,//") \
      osm-buildings-ksql-airport.geojson \
      $OSM_TIF_FILENAME
  else \
    echo "No download ID for OSM Buildings data provided or raster already exists, skipping rasterization."; \
fi

# Download USGS DEM: https://www.sciencebase.gov/catalog/item/62f5de86d34eacf53973ab2a
# Attribution: "Map services and data available from U.S. Geological Survey, National Geospatial Program."
DEM_FILENAME="USGS_13_n38w123_20220810.tif"
if ! [ -f "$DEM_FILENAME" ]; \
  then \
    echo "Downloading digital elevation model (DEM)..."; \
    wget "https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/13/TIFF/historical/n38w123/USGS_13_n38w123_20220810.tif"
  else \
    echo "Digital elevation model (DEM) already downloaded."; \
fi

# Setup complete, start MapServer with default mapfile
MS_MAPFILE=/etc/mapserver/mapserver.map
export MS_MAPFILE
/usr/local/bin/start-server