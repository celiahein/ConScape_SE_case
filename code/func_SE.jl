using ConScape, Pkg, Plots, GMT, Statistics, DataFrames, CSV, Serialization
#import Pkg; Pkg.add("ArchGDAL")
using ArchGDAL; const AG = ArchGDAL

#println(pwd())
#cd("C:/Users/celia/Documents/PostDoc/SE_case/")

inputdata = ArchGDAL.read("./data/Rasters.1000.tif")
my_proj = ArchGDAL.getproj(inputdata)
gt_input = ArchGDAL.getgeotransform(inputdata)

hab_qual = ArchGDAL.read(inputdata, 1)
aff = hab_qual
mov_prob= aff

my_coarseness = 2
θ = theta = parse(Float64, ARGS[1])
alpha = parse(Float64, ARGS[2])
adjacency_matrix = ConScape.graph_matrix_from_raster(aff)

g = ConScape.Grid(size(hab_qual)...,
    affinities=adjacency_matrix,
    source_qualities=hab_qual,
    target_qualities = ConScape.sparse(hab_qual),
    costs=ConScape.mapnz(x -> (2-x)^10, adjacency_matrix))

@time coarse_target_qualities = ConScape.coarse_graining(g, my_coarseness)

g_coarse = ConScape.Grid(size(mov_prob)...,
    affinities=adjacency_matrix,
    source_qualities=hab_qual,
    target_qualities=coarse_target_qualities,
    costs=ConScape.mapnz(x -> (2-x)^10,adjacency_matrix))

@time h = ConScape.GridRSP(g_coarse, θ = theta)

#open("./data/hgrid_theta0.1_res25_coarse25.dat", "w") do io
#    serialize(io, h)
#end

@time func = ConScape.connected_habitat(h, connectivity_function=
    ConScape.expected_cost, distance_transformation=x -> exp(-x/alpha))

df = DataFrame(theta = theta, alpha= alpha, resolution_input= gt_input[2], coarseness_aggregation = my_coarseness, percent_unconnected = 100*(1-sqrt(sum(filter(x -> !isnan(x), func)))/
sum(filter(x -> !isnan(x), g_coarse.source_qualities))), percent_connected = 100*(sqrt(sum(filter(x -> !isnan(x), func)))/
sum(filter(x -> !isnan(x), g_coarse.source_qualities))))
    
CSV.write("./output/metrics_func_res$(gt_input[2])_coarse$(my_coarseness).csv", df)

#write out raster
func_out = func

ArchGDAL.create(
    "./output/func_theta$(theta)_alpha$(alpha)_res$(gt_input[2])_coarse$(my_coarseness).tif",
    driver = AG.getdriver("GTiff"),
    width=size(func)[1],
    height=size(func)[2],
    nbands=1,
    dtype=Float64,
    options = ["OVERWRITE=YES"]  # Allow overwriting existing file
) do dataset
    AG.write!(dataset, func_out, 1)

    AG.setgeotransform!(dataset, gt_input)
    AG.setproj!(dataset, my_proj)
end




