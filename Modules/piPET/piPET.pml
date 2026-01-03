# Raspberry pi PDB Render Display
# Gif Export

# Set Path
cd ~/Desktop/piPET/

# Initialize PyMol Viewport
#480p
viewport 680, 480

# Set View
set_view (\
    -0.533364952,    0.590317845,   -0.605838835,\
     0.322305769,    0.804019570,    0.499672472,\
     0.782074451,    0.071241364,   -0.619096875,\
    -0.000013241,   -0.000022493, -177.916732788,\
     2.090981960,   -8.510021210,    5.528719425,\
   111.565315247,  244.273971558,  -20.000000000 )

# Color Choices
# TODO split by warm/cool colors for contrast
col_choice = ["aquamarine", "blue", "brightorange",\
"carbon", "chartreuse", "chocolate", "cyan", \
"darksalmon", "dash", "deepblue", "deepolive", \
"deeppurple", "deepsalmon", "deepteal", "firebrick", \
"forest", "gray", "green", "greencyan", \
"grey", "hotpink", "lightblue", "lightmagenta", \
"lightorange", "lightpink", "lightteal", "lime", \
"limegreen", "limon", "magenta", "marine", \
"olive", "orange", "palecyan", "palegreen", \
"paleyellow", "pink", "purple", "purpleblue", \
"red", "ruby", "salmon", "sand", \
"skyblue", "slate", "smudge", "splitpea", \
"sulfur", "teal", "tv_blue", "tv_green", \
"tv_orange", "tv_red", "tv_yellow", "violet", \
"violetpurple", "warmpink", "wheat", "white", \
"yellow", "yelloworange"]

warms = ["red", "tv_red", "raspberry", "darksalmon",\
"salmon", "deepsalmon", "warmpink", "firebrick",\
"ruby", "brown", "yellow", "tv_yellow",\
"paleyellow","yelloworange", "limon", "wheat",\
"sand", "orange", "tv_orange", "brightorange",\
"lightorange", "yelloworange", "olive", "deepolive",\
"lightpink", "dirtyviolet", "violet"]

cools = ["magenta", "lightmagenta", "hotpink", "pink",\
"violetpurple", "purple", "deeppurple", "cyan",\
"palecyan", "aquamarine", "greencyan", "teal",\
"deepteal", "lightteal", "green", "tv_green",\
"chartreuse", "splitpea", "smudge", "palegreen",\
"limegreen", "lime", "limon", "forest"]


# Global
set mesh_quality, 2
set cavity_cull, 100
set mesh_cutoff, 0

# Visual Mesh Settings

## Dot Matrix
set mesh_type, 1

## Cartoon Styled
# set mesh_type, 0
# set mesh_width, 20

## Wire Styled
#set mesh_type, 0
#set mesh_width, 0.5

# Render options
set ray_opaque_background, 1
bg_color black

# Python Script - Render
python
from os import listdir, mkdir
import time
import random

# Directory to PDBs to Render
pdbdir  = "pdbset"
pdblist = listdir(pdbdir)

# Iterate through each PDB
for pdbfile in pdblist:
    print("PDB: " + pdbfile.rsplit('.', maxsplit=1)[0])

    cmd.load( pdbdir + "/" + pdbfile)
    os.mkdir("render/" + pdbfile)
    cmd.hide("all")

    # Create 2 copies of object for mesh
    cmd.set_name( pdbfile.rsplit('.', maxsplit=1)[0] , "R")
    cmd.copy("C", "R")
    
    ## Set Random mesh color
    #cols = random.sample(col_choice, 2)
    #col0 = cols[0]
    #col1 = cols[1]

    # Set Random Warm/Cool mesh
    col0 = random.sample(warms, 1)[0]
    col1 = random.sample(cools, 1)[0]

    cmd.color(col0, "R")
    cmd.color(col1, "C")

    # Offset two colors
    cmd.translate([0.25,0.25,0], "R")

    # Pre-load settings Update
    # Set polygon complexity
    ## 2  == from scratch
    ## 10 == from low-poly
    poly = 2
    cmd.set("mesh_grid_max", poly)
    cmd.show("mesh", "R")
    cmd.show("mesh", "C")

    # Five Rotations (360 Frames)
    # 72 steps / rotation
    for i in range(0, 72*5):

        # Every 5 frames, increase poly count
        if (i%5) == 0:
            poly = poly + 1

        cmd.set("mesh_grid_max", poly)
        cmd.rotate("y", 5) # 72 frames / rotation

        # Verbose
        print("  Frame: ", i, " | Poly: ", poly)

        # Draw
        cmd.refresh()
        #time.sleep(0.1)

        # Save PNG of render
        cmd.png("render/" + pdbfile + "/frame" + str(i).zfill(4) + ".png" , 680, 480)
        # ffmpeg -framerate 24 -i test/frame_%04d.png test.gif

python end

# #cd render
# for PDB in $(ls)
# do
#     # Convert stills to GIF
#     ffmpeg -framerate 24 -i $PDB/frame%04d.png $PDB.gif
# done
#
# #cd render
# mkdir -p opt
# for GIF in $(ls)
# do
#     # Convert stills to GIF
#  gifsicle \
#    --colors=6 \
#    -O2 \
#    $GIF -o opt/$GIF 
#  done

