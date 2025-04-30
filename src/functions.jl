# Call required packages

using GeometryBasics # For point and mesh format
using FileIO # For loading/saving OBJ files
using Suppressor # For suppressing run output 

export geomgramjl_dir, ggremesh

"""
    geomgramjl_dir()

# Description 

This function simply returns the string for the geogram.jl path. This is helpful for instance to load items, such as meshes, from the `assets`` folder. 
"""
function geomgramjl_dir()    
    pkgdir(@__MODULE__)
end

"""
    ggremesh(F,V; nb_pts=nothing, remesh_anisotropy=0, remesh_gradation=0.0, pre_max_hole_area=100, pre_max_hole_edges=0, post_max_hole_area=100, post_max_hole_edges=0, quiet=0, suppress = true, cleanup = true)

Triangular remeshing using geogram

# Description
This function uses the vorpalite executable from Geogram to remesh the input 
triangulation defined by the faces F and the vertices V. 

The following vorpalite input parameters may be provided (defaults shown below): 

nb_pts=size(V,1); # number of points
anisotropy=0; # Use anisotropy (~=0) to capture geometry or favour isotropic triangles (=0)
pre_max_hole_area=100; # Max hole area for pre-processing step
pre_max_hole_edges=0; # Max number of hole edges for pre-processing step
post_max_hole_area=100; # Max hole area for post-processing step
post_max_hole_edges=0; # Max number of hole edges for post-processing step
quiet = 0 # Minimal or full log output in the terminal 

In addition the option to suppress all terminal output is provided e.g. when the
following parameter is used: 
suppress = true 

More information: 

Geogram GitHub repository: https://github.com/BrunoLevy/geogram

Lévy B., Bonneel N. (2013) Variational Anisotropic Surface Meshing with
Voronoi Parallel Linear Enumeration. In: Jiao X., Weill JC. (eds)
Proceedings of the 21st International Meshing Roundtable. Springer,
Berlin, Heidelberg. https://doi.org/10.1007/978-3-642-33573-0_21 

See also: 
http://alice.loria.fr/publications/papers/2012/Vorpaline_IMR/vorpaline.pdf
https://www.ljll.math.upmc.fr/hecht/ftp/ff++days/2013/BrunoLevy.pdf

_/ ==[pre]====[Preprocessing phase]== ________________________________________________
|                                                                                       |
| o-[CmdLine     ] using pre:max_hole_area=10(10%)                                      |
|                  using pre:min_comp_area=3(3%)                                        |
|  pre:repair                 (=true) : Repair input mesh                               |
|  pre:intersect             (=false) : Remove intersections in input mesh              |
|  pre:remove_internal_shells (=true) : Remove internal shells after intersection       |
|  pre:max_hole_area           (=10%) : Fill holes smaller than (in % total area)       |
|  pre:max_hole_edges         (=2000) : Fill holes with a smaller nb. of edges          |
|  pre:min_comp_area            (=3%) : Remove small components (in % total area)       |
|  pre:vcluster_bins             (=0) : Number of bins for vertex clustering            |
   ___________________________________
 _/ ==[remesh]====[Remeshing phase]== _________________________________________________
|                                                                                       |
|  remesh:nb_pts (=30000) : Number of vertices                                          |
|  remesh:anisotropy (=1) : Anisotropy factor                                           |
|  remesh:gradation  (=0) : Mesh gradation exponent                                     |
   ______________________________________
 _/ ==[post]====[Postprocessing phase]== ______________________________________________
|                                                                                       |
|  post:repair          (=false) : Repair output mesh                                   |
|  post:max_hole_area      (=0%) : Fill holes smaller than (in % total area)            |
|  post:max_hole_edges   (=2000) : Fill holes with a smaller nb. of edges than          |
|  post:min_comp_area      (=3%) : Remove small components (in % total area)            |
|  post:max_deg3_dist    (=0.1%) : Degree3 vertices threshold (in % bounding box diagon |
|                                  al)                                                  |
|  post:isect           (=false) : Tentatively remove self-intersections                |
|  post:compute_normals (=false) : Compute normals                                      |

"""


function ggremesh(F::Vector{NgonFace{N,TF}},V::Vector{Point{3,TV}}; nb_pts=nothing, remesh_anisotropy=0, remesh_gradation=0.0, pre_max_hole_area=100, pre_max_hole_edges=0, post_max_hole_area=100, post_max_hole_edges=0, quiet=0, suppress = true, cleanup = true) where N where TF<:Integer where TV<:Real

    # Process input parameters 
    if isnothing(nb_pts)
        nb_pts = length(V)
    end

    # Get executable path for vorpalite 
    if Sys.islinux()
        vorpalite_path = joinpath(geomgramjl_dir(),"ext","geogram","lin64","bin","vorpalite")
    elseif Sys.iswindows()
        vorpalite_path = joinpath(geomgramjl_dir(),"ext","geogram","win64","bin","vorpalite.exe")
    elseif Sys.isapple()
        vorpalite_path = joinpath(geomgramjl_dir(),"ext","geogram","mac64","bin","vorpalite")
    else
        
    end

    # Check for temp directory and create if missing
    tempDir = joinpath(geomgramjl_dir(),"assets","temp")
    if !isdir(tempDir)
        mkdir(tempDir)
    end

    # Create input mesh file
    M = GeometryBasics.Mesh(V,F) # Geometry basics mesh 
    inputMesh =  joinpath(tempDir,"temp.obj") # OBJ file name for input 
    save(inputMesh,M) # Write to OBJ

    # Remesh using geogram's vorpalite 
    outputMesh =  joinpath(tempDir,"temp_out.obj") # OBJ file name for input     
    runCommand = `"$vorpalite_path" "$inputMesh"  "$outputMesh" quiet=$quiet nb_pts=$nb_pts remesh:anisotropy=$remesh_anisotropy remesh:gradation=$remesh_gradation
    pre:max_hole_area=$pre_max_hole_area pre:max_hole_edges=$pre_max_hole_edges post:max_hole_area=$post_max_hole_area post:max_hole_edges=$post_max_hole_edges`
   
    if suppress == true 
        @suppress run(runCommand)
    elseif suppress == false
        run(runCommand)
    end

    # Get new mesh 
    M = load(outputMesh) # Import OBJ file 
    F = [TriangleFace{TF}(f) for f in faces(M)] # Get plain faces
    V = [Point{3,TV}(v) for v in coordinates(M)] # Get coordinates 

    # Remove temp directory if requested
    if cleanup == true
        rm(tempDir,recursive=true)
    end

    return F,V
end

