using Geogram
using Geogram.FileIO
using Comodo
using Comodo.GLMakie
using Comodo.GeometryBasics

## Load example mesh 
fileName_mesh = joinpath(geomgramjl_dir(),"assets","obj","motherChild_10k.obj")
M = load(fileName_mesh)
F = [TriangleFace{Int64}(f) for f in faces(M)]
V = [Point{3,Float64}(v) for v in coordinates(M)] # Get coordinates 

## Remeshing 

# Get initial point spacing 
pointSpacingInitial = pointspacingmean(F, V)

# Get initial number of points 
n = length(V)

# Remeshing the surface with target point spacing 
pointSpacing = pointSpacingInitial*2.0 # E.g. twice as coarse as input in terms of point spacing 

# Approximate the desired number of points from desired point spacing and current mesh 
ns = spacing2numvertices(F, V, pointSpacing) 

# Remesh using new desired number of points 
Fs, Vs = ggremesh(F, V; nb_pts=ns)

## Visualisation
GLMakie.closeall() # Close existing figures

fig = Figure(size=(1600,1200))

ax1 = AxisGeom(fig[1, 1], title = "Original, $n points")
hp1 = meshplot!(ax1, F, V, color=:white, strokewidth=0.0)

ax2 = AxisGeom(fig[1, 2], title = "Remeshed, $ns points, pointSpacing=$pointSpacing")
hp2 = meshplot!(ax2, Fs, Vs, color=:white)

stepRange1 = range(pointSpacingInitial/2.0, 4.0*pointSpacingInitial, 25)
hSlider1 = Slider(fig[2, :], range = stepRange1, startvalue = pointSpacing, linewidth=30)

on(hSlider1.value) do pointSpacing
   ns = spacing2numvertices(F, V, pointSpacing) 
    Fs, Vs = ggremesh(F, V; nb_pts=ns)

    hp2[1] = GeometryBasics.Mesh(Vs, Fs)
    ax2.title = "Remeshed, $ns points, pointSpacing=$pointSpacing"
end

screen = display(GLMakie.Screen(), fig)