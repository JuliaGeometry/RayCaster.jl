using RayCaster, GeometryBasics, LinearAlgebra
using GLMakie, FileIO

function LowSphere(radius, contact=Point3f(0); ntriangles=10)
    return Tesselation(Sphere(contact .+ Point3f(0, 0, radius), radius), ntriangles)
end

begin
    ntriangles = 10
    s1 = LowSphere(0.5f0, Point3f(-0.5, 0.0, 0); ntriangles)
    s2 = LowSphere(0.3f0, Point3f(1, 0.5, 0); ntriangles)
    s3 = LowSphere(0.3f0, Point3f(-0.5, 1, 0); ntriangles)
    s4 = LowSphere(0.4f0, Point3f(0, 1.0, 0); ntriangles)
    l = 0.5
    floor = Rect3f(-l, -l, -0.01, 2l, 2l, 0.01)
    cat = load(Makie.assetpath("cat.obj"))
    bvh = RayCaster.BVHAccel([s1, s2, s3, s4, cat]);
    world_mesh = GeometryBasics.Mesh(bvh)
    f, ax, pl = Makie.mesh(world_mesh; color=:teal)
    display(f)
    viewdir = normalize(ax.scene.camera.view_direction[])
end

begin
    @time "hitpoints" hitpoints, centroid = RayCaster.get_centroid(bvh, viewdir)
    @time "illum" illum = RayCaster.get_illumination(bvh, viewdir)
    @time "viewf_matrix" viewf_matrix = RayCaster.view_factors(bvh, rays_per_triangle=1000)
    viewfacts = map(i-> Float32(sum(view(viewf_matrix, :, i))), 1:length(bvh.primitives))
    world_mesh = GeometryBasics.Mesh(bvh)
    N = length(world_mesh.faces)
    areas = map(i-> area(world_mesh.position[world_mesh.faces[i]]), 1:N)
    # View factors
    f, ax, pl = mesh(world_mesh, color=:blue)
    per_face_vf = FaceView((viewfacts), [GLTriangleFace(i) for i in 1:N])
    viewfact_mesh = GeometryBasics.mesh(world_mesh, color=per_face_vf)
    pl = Makie.mesh(f[1, 2],
        viewfact_mesh, colormap=[:black, :red], axis=(; show_axis=false),
        shading=false, highclip=:red, lowclip=:black)

    # Centroid
    cax, pl = Makie.mesh(f[2, 1], world_mesh, color=(:blue, 0.5), axis=(; show_axis=false), transparency=true)

    eyepos = cax.scene.camera.eyeposition[]
    depth = map(x-> norm(x .- eyepos), hitpoints)
    meshscatter!(cax, hitpoints, color=depth, colormap=[:gray, :black], markersize=0.01)
    meshscatter!(cax, centroid, color=:red, markersize=0.05)

    # Illum
    per_face = FaceView(100f0 .* (illum ./ areas), [GLTriangleFace(i) for i in 1:N])
    illum_mesh = GeometryBasics.mesh(world_mesh, color=per_face)

    Makie.mesh(f[2, 2], illum_mesh, colormap=[:black, :yellow], shading=false, axis=(; show_axis=false))

    Label(f[0, 1], "Scene ($(length(bvh.primitives)) triangles)", tellwidth=false, fontsize=20)
    Label(f[0, 2], "Viewfactors", tellwidth=false, fontsize=20)
    Label(f[3, 1], "Centroid", tellwidth=false, fontsize=20)
    Label(f[3, 2], "Illumination", tellwidth=false, fontsize=20)

    f
end
