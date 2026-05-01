clear all

cd "$input/shapefile_pk"
spshape2dta pak_admbnda_adm2_wfp_20220909, replace

spshape2dta pak_admbndl_admALL_wfp_itos_20220909, replace

use pak_admbnda_adm2_wfp_20220909.dta ,clear
spmap using pak_admbnda_adm2_wfp_20220909_shp.dta, id(_ID)