# Color Choices
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

python
import random

# Set Random mesh colors
cols = random.sample(col_choice, 2)
col0 = cols[0]
col1 = cols[1]

cmd.color(col0, "R")
cmd.color(col1, "C")
python end