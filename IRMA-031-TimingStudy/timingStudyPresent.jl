### A Pluto.jl notebook ###
# v0.12.17

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ d5cb4316-4028-11eb-340e-19e4116c4105
begin
	using Pkg, PlutoUI, JLD2, DataFrames, CategoricalArrays, Plots, StatsPlots
	gr()
end

# ╔═╡ bfbb00b8-40e4-11eb-150f-d33ca0c49ed4
md"""
**Instructions:** 

Wait for the notebook to load (when all of the wavy lines in the left margin disappear and all the plots appear; takes ~2 minutes).

You can also turn on "Presenter view" by pressing "Present" in the title slide below (presenter view adds vertical whitespace to separate the slides). Use the arrow buttons on the lower right of the window to advance through the slides or go back. Press the "Present" button again to exit presenter view. 

You can see hidden code by mousing over a cell and clicking on the "slash-eye" that appears at left. Click again to re-hide. 

This notebook is live when viewed in *Heroku*. UI elements (e.g. buttons, sliders, and selection menus) are active. You can add your own cells (click on "+" in left margin). Changing a cell will automatically execute dependent cells. Note that these free Heroku nodes are very underpowered. 

This is a [Pluto.jl](https://github.com/fonsp/Pluto.jl) notebook. Source is on [GitHub](https://github.com/lyon-fnal/AdamPlutoNotebooks).
"""

# ╔═╡ f247e40a-4027-11eb-3746-d5b070890cd7
md"""
# Muon g-2

![](https://news.fnal.gov/wp-content/uploads/2019/03/muon-g-2-17-0188-20.hr_-1024x684.jpg)
"""

# ╔═╡ 31ff23d8-4028-11eb-1e34-c94e8566eada
md"""
# Calorimeters

![](https://ars.els-cdn.com/content/image/1-s2.0-S0168900219310824-gr1.jpg)
![](https://ars.els-cdn.com/content/image/1-s2.0-S0168900215014060-gr1.jpg)
"""

# ╔═╡ ede61202-4029-11eb-2e2e-296b034a1fcf
md"""
# Jobs
Ran jobs with $n$ nodes and $m$ tasks (ranks) per node on native Cori Haswell (debug queue). 

Data were spread evenly among ranks and read in.

Some jobs with 10 nodes used collective i/o (MPIO) for reads. All others used non-collective i/o.

Timings are obtained with comparing `MPI_Wtime` before and after function call. 

Coded in [Julia](https://julialang.org) using [MPI.jl](https://github.com/JuliaParallel/MPI.jl) and [HDF5.jl](https://github.com/JuliaIO/HDF5.jl) (this notebook is run by [Pluto.jl](https://github.com/fonsp/Pluto.jl)).
"""

# ╔═╡ b8600e56-402d-11eb-1511-a95313717404
md"""
# Collective vs non-Collective I/O
"""

# ╔═╡ 63bb6fa2-4033-11eb-172a-77930ed3d813
md"""
## Energy Dataset
"""

# ╔═╡ 7cc52222-4033-11eb-23b0-053daf8a7d57
md"""
## Time Dataset
"""

# ╔═╡ a35c7976-4033-11eb-32db-fb4fc7342a8f
md"""
## Calorimeter index dataset
"""

# ╔═╡ cb257066-4033-11eb-15f6-e198a2f1a9e7
md"""
## Total read time
"""

# ╔═╡ a1217a66-427d-11eb-19b9-2f6139a82b2f
md"""
# Notes added after meetng...

Why am I seeing such variation in read times among ranks? An explanation could be the fact that HDF5 always reads at the level of chunks which then need to be decompressed. The chunk size of 1 MB is uncompressed. Some chunks will compress better than others and thus the i/o time will vary. Making the chunks larger is not really a good solution as then the decompression time will increase (though thinking more about that - I don't follow that argument - Decompressing 200K small chunks shouldn't be that different than decompressing 20K larger chunks ... it's still the same amount of data). 

Things to try

- I'm not getting much compression for the float values. Try not compressing/chunking them at all. That will make the i/o time more even and there will be no decompression time.

- Try to get `darshan` to work. And let the ANL authors know - they haven't tried it with Julia. 
"""

# ╔═╡ c0376d86-4028-11eb-25cc-298c16e79635
md"""
# Code
"""

# ╔═╡ baffc404-402c-11eb-0b18-27f984b63ee1
# Wide screen
html"""<style>
main {
	max-width: 1100px;
}</style>
"""

# ╔═╡ 34a2c458-4034-11eb-3ec3-434058547662
br = HTML("<br>")

# ╔═╡ bfa30ebe-4019-11eb-052b-254a135892bb
md"""
# Muon g-2 data and HDF5 I/O

Adam Lyon (FNAL)
2020-12-17
$(html"<button onclick=present()>Present</button>")

$br

Goal: Run g-2 histogram generating code at NERSC for drastic speed improvement.

- Convert *needed* g-2 data to HDF5 on FermiGrid
- Move files to HPC (NERSC)
- Concatenate into large "era" files
- Process into Histograms for analysis and fitting

"""

# ╔═╡ aab15f6e-4021-11eb-0255-8bf8071e81a1
md"""
# Data Characteristics

Storing 10 columns of data: $(HTML("<br/>"))
`run, subrun, event, bunchNum, caloIndex, islandIndex, time, energy, x, y`

For `irmaData_2C_merged.h5` each column has 22,921,764,790 (23B) rows. All data stored with deflate(6) and shuffle. Chunksize is 1MB (262,144 chunks in the file). Floats are single precision. The file is stored on Cori's Lustre scratch volume with the [`stripe large`](https://docs.nersc.gov/performance/io/lustre/) setting (72 OSTs). 
 
$br

|    Column   | Type  | Compression factor |
|:-----------:|-------|-------------|
| run         | int   | 1000        |
| subrun      | int   | 1002        |
| event       | int   | 829         |
| bunchNum    | int   | 866         |
| caloIndex   | int   | 167         |
| islandIndex | int   | 4.5         |
| time        | float | 1.4         |
| energy      | float | 1.23        |
| x           | float | 1.23        |
| y           | float | 1.3         |


"""

# ╔═╡ ed679ac8-4033-11eb-1b00-85de7e7182e5
md"""
# My conclusions

$br

**Ideal configuration seems to be 20 nodes and 6 ranks per node.**

$br 

Things to try
- Increasing chunk size (262,144 are a lot of chunks; maybe aim for around 10,000?)
- Removing shuffle from the floats
- Changing compression
- Removing compression?
- I/O profiling (is `Darshan` worthwhile?)
"""

# ╔═╡ 77adadb8-415d-11eb-0d7a-e343bc3104a9
pwd()

# ╔═╡ 79deea86-415d-11eb-2306-c7001421c314
with_terminal() do
	versioninfo(verbose=true)
	Pkg.status()
end

# ╔═╡ 337b7892-40c3-11eb-020d-6de4898ac30a
# Load the data
@load "./timingStudyPresent.jld2"

# ╔═╡ ca561bd0-402a-11eb-1c33-7590b68c7437
# Make plots for a group
function plotsForRun(df)
    cols = 5:ncol(df)  # Don't plot numNodes and rank columns
    p = []
    for i in cols
        yaxis = i==5 ? "# rows read" : "seconds"
        push!(p, scatter(df.rank, df[!, i], legend=nothing, 
				 title=names(df)[i], xaxis="Rank", yaxis=yaxis,
                 xticks=0:32:20*32, titlefontsize=11, xguidefontsize=8, 
				 markersize=2))
    end
    p
end

# ╔═╡ ec2592a4-402a-11eb-2a94-6d7744e89b4f
# Make the list for the selection box
const selList = [ string(k) => "$(v.jobType) $(v.nNodes)x$(v.nTasks)"
	                                      for (k,v) in enumerate(keys(gdf))]

# ╔═╡ 69368eba-402b-11eb-1572-bd26be244522
md"""
# Timings

Choose run to view: $(@bind e Select(selList)). `mpio` means read used collective i/o. `nxm` means `n` nodes and `m` ranks per node.
"""

# ╔═╡ 0472a37e-402b-11eb-16aa-d1f54de3535c
# Some helper functions
begin
	keyInt(e) = parse(Int, e)
	
	function makeTitle(e)
		theKey = keys(gdf)[keyInt(e)]
		theKeyTitle = "$(theKey.nNodes) x $(theKey.nTasks) with $(string(theKey.jobType))"
	end
	
	cticks(ctg::CategoricalArray) = (1:length(levels(ctg)), levels(ctg))
end

# ╔═╡ f11c05ca-402c-11eb-0d7c-11bda08eb943
plot(plotsForRun(gdf[keyInt(e)])..., size=(1000,900), layout=(5,3))

# ╔═╡ c56aaafc-402d-11eb-1065-59426edb6437
let
	p1 = @df filter(r->r.jobType == "noCollective" && r.nNodes == "10", df) boxplot(levelcode.(:nTasks), :readTotal, 
		                            title="Read time No Collective (10 nodes)", fillalpha=0.2,
                                    xticks=cticks(:nTasks), xaxis="Number of ranks/node (nonlinear scale)", 
									yaxis="read time (s)", legend=nothing)
	
	p2 = @df filter(r->r.jobType == "mpio" && r.nNodes == "10", df) boxplot(levelcode.(:nTasks), :readTotal,
		                            title="Read time MPIO (10 nodes)", fillalpha=0.2,
									xticks=cticks(:nTasks),
                                    xaxis="Number of ranks/node (nonlinear scale)", yaxis="read time (s)", 
									legend=nothing, color=:orange)
	
	plot(p1, p2, layout=(2,1), ylim=(60, 170) , size=(800,800))
end

# ╔═╡ a4ba655a-4031-11eb-155e-0dd5fec38861
# Plot median and maximum of column
function plotMedianAndMax(c)
	
	if c == "total"
		colName = "readTotal"
	else
		colName = "read"*c*"DataSet"
	end
	
	cMedianTime  = Symbol(colName*"_median")
	cMaximumTime = Symbol(colName*"_maximum")
	
	p1 = @df dfc plot(levelcode.(:nTasks), dfc[!, cMedianTime], title="Median $c read time (s)", 
									line=2, group=(:nNodes, :jobType), marker=(:dot), xticks=cticks(:nTasks),
                                    xaxis="Number of ranks/node (nonlinear scale)", yaxis="Median read time (s)",size=(800,600))
	
	p2 = @df dfc plot(levelcode.(:nTasks), dfc[!, cMaximumTime], title="Maximum $c read time (s)", 
									line=2, group=(:nNodes, :jobType), marker=(:dot), xticks=cticks(:nTasks),
									xaxis="Number of ranks/node (nonlinear scale)", yaxis="Maximum read time (s)",size=(800,600))
	
	plot(p1, p2, layout=(2,1), legend=:outerright, size=(1000,800))
end

# ╔═╡ 6a03b3e2-4033-11eb-176a-db0026f25c57
plotMedianAndMax("Energy")

# ╔═╡ 96cd29a8-4033-11eb-234b-adf2fcff7906
plotMedianAndMax("Time")

# ╔═╡ ac71cd04-4033-11eb-26eb-9f4284e5dd5c
plotMedianAndMax("Calo")

# ╔═╡ d23baa98-4033-11eb-1d7a-c1ed199db7a6
plotMedianAndMax("total")

# ╔═╡ Cell order:
# ╟─bfbb00b8-40e4-11eb-150f-d33ca0c49ed4
# ╟─bfa30ebe-4019-11eb-052b-254a135892bb
# ╟─f247e40a-4027-11eb-3746-d5b070890cd7
# ╟─31ff23d8-4028-11eb-1e34-c94e8566eada
# ╟─aab15f6e-4021-11eb-0255-8bf8071e81a1
# ╟─ede61202-4029-11eb-2e2e-296b034a1fcf
# ╟─69368eba-402b-11eb-1572-bd26be244522
# ╟─f11c05ca-402c-11eb-0d7c-11bda08eb943
# ╟─b8600e56-402d-11eb-1511-a95313717404
# ╟─c56aaafc-402d-11eb-1065-59426edb6437
# ╟─63bb6fa2-4033-11eb-172a-77930ed3d813
# ╟─6a03b3e2-4033-11eb-176a-db0026f25c57
# ╟─7cc52222-4033-11eb-23b0-053daf8a7d57
# ╟─96cd29a8-4033-11eb-234b-adf2fcff7906
# ╟─a35c7976-4033-11eb-32db-fb4fc7342a8f
# ╟─ac71cd04-4033-11eb-26eb-9f4284e5dd5c
# ╟─cb257066-4033-11eb-15f6-e198a2f1a9e7
# ╟─d23baa98-4033-11eb-1d7a-c1ed199db7a6
# ╟─ed679ac8-4033-11eb-1b00-85de7e7182e5
# ╟─a1217a66-427d-11eb-19b9-2f6139a82b2f
# ╟─c0376d86-4028-11eb-25cc-298c16e79635
# ╠═baffc404-402c-11eb-0b18-27f984b63ee1
# ╠═34a2c458-4034-11eb-3ec3-434058547662
# ╠═d5cb4316-4028-11eb-340e-19e4116c4105
# ╠═77adadb8-415d-11eb-0d7a-e343bc3104a9
# ╠═79deea86-415d-11eb-2306-c7001421c314
# ╠═337b7892-40c3-11eb-020d-6de4898ac30a
# ╠═ca561bd0-402a-11eb-1c33-7590b68c7437
# ╠═ec2592a4-402a-11eb-2a94-6d7744e89b4f
# ╠═0472a37e-402b-11eb-16aa-d1f54de3535c
# ╠═a4ba655a-4031-11eb-155e-0dd5fec38861
