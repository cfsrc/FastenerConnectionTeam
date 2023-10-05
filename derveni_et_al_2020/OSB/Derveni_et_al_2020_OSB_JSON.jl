
using CSV, DataFrames, Dates, StructTypes, DelimitedFiles, CairoMakie 


#read filenames from directory 

# path = "/Users/crismoen/Library/CloudStorage/GoogleDrive-cdm@runtosolve.com/Shared drives/RunToSolve/Professional/AISI/projects/fastener_test_database/Peterman_et_al_2014/data_to_read_into_JSON"
# filenames = readdir(path; join=false)


df = CSV.read("/Users/crismoen/Library/CloudStorage/GoogleDrive-cris.moen@runtosolve.com/Shared drives/RunToSolve/Professional/AISI/projects/fastener_test_database/fani/Fani_OSB_specimen_list.csv", DataFrame)




  struct Source
    authors::Array{String}
    date::Date
    title::String
    bibtex::String
    units::Array{String}
    nominal_data::Vector{String}
    notes::String
  end
  
  struct Fastener
    type::Vector{String}
    details::Vector{Dict}
  end
  
  struct Ply
    type::Vector{String}
    thickness::Array{Float64}
    elastic_modulus::Array{Any}
    yield_stress::Array{Any}
    ultimate_stress::Array{Any}
  end

  struct Test
    name::String
    loading::String
    force::Array{Float64}
    displacement::Array{Float64}
  end

  struct Specimen
    source::Array{Source}
    fastener::Fastener
    ply::Ply
    test::Test
  end






authors = ["Peterman, K.D.", "Nakata, N.", "Schafer, B.W."]
date = Date(2014,10)
title = "Hysteretic characterization of cold-formed steel stud-to-sheathing connections"
bibtex = "@article{peterman2014hysteretic,
title={Hysteretic characterization of cold-formed steel stud-to-sheathing connections},
author={Peterman, KD and Nakata, N and Schafer, BW},
journal={Journal of Constructional Steel Research},
volume={101},
pages={254--264},
year={2014},
publisher={Elsevier}
}"
units = ["inches", "lbf"]
nominal_data = ["steel ply thickness", "sheathing ply thickness"]
notes = "Zeroed data as average of first 10 load and disp readings.  Multiplied load and disp voltages by factors provided by Kara."

source = Source(authors, date, title, bibtex, units, nominal_data, notes)


all_sources = [source]


num_specimens = 30

fasteners = Vector{Fastener}(undef, num_specimens)


for i in eachindex(fasteners)

    details = fill(Dict([("size", df.fastener_size[i]), ("product name", df.fastener_name[i]), ("major thread diameter", df.fastener_diameter[i])]), df.number_of_fasteners[i])

    fasteners[i] = Fastener(fill("screw", df.number_of_fasteners[i]), details)

end

plies = Vector{Ply}(undef, num_specimens)

for i in eachindex(plies)

    plies[i]  = Ply([df.sheathing_type[i], "steel"], [df.sheathing_thickness[i], df.steel_thickness[i]], ["unknown", df.E[i]], ["unknown", df.steel_ply_fy[i]], ["unknown", df.steel_ply_fu[i]])

end

test = Vector{Test}(undef, num_specimens)


data = readdlm("/Users/crismoen/Library/CloudStorage/GoogleDrive-cris.moen@runtosolve.com/Shared drives/RunToSolve/Professional/AISI/projects/fastener_test_database/fani/OSB/TEST1_1.is_tens_Exports/m54o12-R1.txt", ',', Float64)

force = data[:, 3]
displacement = data[:, 2]

name = df.filename[1][1:end-4]
loading = df.loading_type[1] 
test = Test(name, loading, force, displacement)

first_specimen = Specimen(all_sources, fasteners[1], plies[1], test)

all_specimens = Vector{Specimen}(undef, num_specimens)
using Statistics 

for i in eachindex(test)

    data = readdlm(joinpath("/Users/crismoen/Library/CloudStorage/GoogleDrive-cdm@runtosolve.com/Shared drives/RunToSolve/Professional/AISI/projects/fastener_test_database/Peterman_et_al_2014/data_to_read_into_JSON", df.filename[i]))

    #from FSpost_process_compare.m written by Kara
    Lscale = 5.87;      #lbf/lbf
    Lgain = 851.46;     #v/v 
    Dscale = 0.04075;   #in/in
    Dgain = 7.3602;     #v/v

    name = df.filename[i][1:end-4]
    loading = df.loading_type[i] 
    force = (data[:, 3] .- mean(data[1:10, 3])).* Lscale .* Lgain 
    displacement = -(data[:, 2] .- mean(data[1:10, 2])) .* Dscale .* Dgain 

    test[i] = Test(name, loading, force, displacement)

    all_specimens[i] = Specimen(all_sources, fasteners[i], plies[i], test[i])

end




using JSON3

json_path = "/Users/crismoen/Library/CloudStorage/GoogleDrive-cris.moen@runtosolve.com/Shared drives/RunToSolve/Professional/AISI/projects/fastener_test_database/fani/JSON_files/OSB"

open(joinpath(json_path, "first_specimen.json"), "w") do io
    JSON3.pretty(io, first_specimen)
end

# json_path = "/Users/crismoen/Dropbox/Prof_Moen/json_files"

# for i in eachindex(all_specimens)



for i in eachindex(all_specimens)

    open(joinpath(json_path, "Peterman_et_al_2014_" * string(df.filename[i][1:end-4])*".json"), "w") do io
        JSON3.pretty(io, all_specimens[i])
    end

end





index = 3
using CairoMakie 
f = Figure()
ax = Axis(f[1, 1])
lines!(ax, test[index].displacement, test[index].force)
f


for i in eachindex(test)
  lines!(ax, test[i].displacement, test[i].force)
end
f

#CFS-NEHRI