library(MODIS)
library(raster)

##### Download data #####

# EarthdataLogin(usr = "usernamehere", pwd = "passwordhere")
# you need to create an account with EarthData to access products and use the above to set up a hidden file with the details
template_raster <- raster(choose.files()) 
# selects a template raster for the download
# mine uses afripop data from here (https://www.worldpop.org/doi/10.5258/SOTON/WP00004), but this could be anything
# The data downloaded will have the same resolution and extent as the template

#### WARNING, this takes a lot of time and a good internet connection...
runGdal(product = "MCD12C1", # gets MODIS land cover data https://lpdaac.usgs.gov/products/mcd12c1v006/
  begin = "2019-01-01", # gets latest map from date range (it is a time series)
  extent = template_raster) # sets the extent, resolution and projection of template raster)


##### Load and process the data #####

africalandcover <- raster("C:/Users/chris/AppData/Local/Temp/RtmpyGhBy4/MODIS_ARC/PROCESSED/MCD12C1.006_20201130174243/MCD12C1.A2019001.Majority_Land_Cover_Type_1.tif")

### WARNING - this is slow and requires some more processing time
africalowres <- sampleRegular(africalandcover, 
  size = 5000000, asRaster = T) # samples cells from higher resolution Raster to get lower res raster
# this makes the file around 40mb

library(plotKML) 
data(worldgrids_pal) # loads package with the colour palette for IGBP classification system
africalowres <- ratify(africalowres)
rat <- levels(africalowres)[[1]] # creates a raster attribute table using the classification system
igbp <- as.data.frame(as.list(worldgrids_pal)[7]) # extracts igbp classification info
rat$col <- igbp$IGBP[c(1:15,17)]
rat$lc <- rownames(igbp)[c(1:15,17)]
rat$ID <- c(0:14,16) # removes the snow and ice as there isn't enough in Africa to register!
library(dplyr)
rat <- rat %>% select(ID, lc, col) # reorders raster attribute table
levels(africalowres) <- rat

#### plot the raster

library(rasterVis)
levelplot(africalowres, 
  col.regions = rat$col, 
  main = "Land Cover in Africa (Source: MODIS MCD12C1)")

#### write the low resolution raster ####

writeRaster(africalowres, "africa_lc_lowres.grd") # writes as grd to preserve rat

#### and plots again for those who don't want to do the above
### you can find the files here https://github.com/chrislittleboy/publicdata

levelplot(raster("africa_lc_lowres.gri"),
  col.regions = unlist(levels(raster("africa_lc_lowres.gri")))[c(33:48)])
tiff("lc_africa.png", units = "mm", width = 210, height = 297, res = 100)
print(levelplot(raster("africa_lc_lowres.gri"),
  col.regions = unlist(levels(raster("africa_lc_lowres.gri")))[c(33:48)]))
dev.off()
