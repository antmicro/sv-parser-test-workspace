create_project -in_memory -part xc7a35ticsg324-1L xx

read_edif top_artya7.edf
read_xdc ./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_top_artya7_0.1/data/pins_artya7.xdc
link_design -top top_artya7 -part xc7a35ticsg324-1L

place_design
route_design

write_bitstream -force top.bit
