using Geogram
using Comodo
using Comodo.GLMakie
using Comodo.GeometryBasics
using FileIO

testCase = 2

if testCase == 1 
    fileName_mesh = joinpath(geomgramjl_dir(),"assets","obj","femur.obj")
    M = load(fileName_mesh)
    F = [TriangleFace{Int64}(f) for f in faces(M)]
    V = [Point{3,Float64}(v) for v in coordinates(M)] # Get coordinates 
elseif testCase == 2 
    fileName_mesh = joinpath(geomgramjl_dir(),"assets","obj","motherChild_10k.obj")
    M = load(fileName_mesh)
    F = [TriangleFace{Int64}(f) for f in faces(M)]
    V = [Point{3,Float64}(v) for v in coordinates(M)] # Get coordinates 
end

n = length(V) # Original number of points

# Remeshing the surface 
n1 = 8000 
n2 = 4000
n3 = 1000
F1,V1 = ggremesh(F,V; nb_pts=n1)
F2,V2 = ggremesh(F,V; nb_pts=n2, remesh_anisotropy=0.0, remesh_gradation = 1.0, pre_max_hole_area=100, pre_max_hole_edges=0, post_max_hole_area=100, post_max_hole_edges=0, quiet=0, suppress = true)
F3,V3 = ggremesh(F,V; nb_pts=n3)

## VISUALISATION

strokeWidth1 = 0.5

fig = Figure(size=(1600,1200))

ax1 = AxisGeom(fig[1, 1], title = "Original, $n points")
hp1 = meshplot!(ax1, F, V, color=:white)

ax2 = AxisGeom(fig[1, 2], title = "Remeshed, $n1 points")
hp2 = meshplot!(ax2, F1, V1, color=:white)

ax3 = AxisGeom(fig[2, 1], title = "Remeshed, $n2 points, anisotropic")
hp3 = meshplot!(ax3, F2, V2, color=:white)

ax4 = AxisGeom(fig[2, 2], title = "Remeshed, $n3 points")
hp4 = meshplot!(ax4, F3, V3, color=:white)

fig