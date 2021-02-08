module TestCHighs

using HiGHS
using Test

function small_test_model()
    cc = [1.0, -2.0]
    cl = [0.0, 0.0]
    cu = [10.0, 10.0]
    ru = [2.0, 1.0]
    rl = [0.0, 0.0]
    astart = [0, 2, 4]
    aindex = [0, 1, 0, 1]
    avalue = [1.0, 2.0, 1.0, 3.0]
    return (cc, cl, cu, rl, ru, astart, aindex, avalue)
end

function test_Direct_C_call() 
    (colcost, collower, colupper, rowlower, rowupper, astart, aindex, avalue) = small_test_model()
    n_col = convert(Cint, size(colcost, 1))
    n_row = convert(Cint, size(rowlower, 1))
    n_nz = convert(Cint, size(aindex, 1))

    colcost = convert(Array{Cdouble}, colcost)
    collower = convert(Array{Cdouble}, collower)
    colupper = convert(Array{Cdouble}, colupper)

    rowlower = convert(Array{Cdouble}, rowlower)
    rowupper = convert(Array{Cdouble}, rowupper)
    matstart = convert(Array{Cint}, astart)
    matindex = convert(Array{Cint}, aindex)
    matvalue = convert(Array{Cdouble}, avalue)

    # solution = HighsSolution(Array{Cdouble, 1}(undef, n_col), Array{Cdouble, 1}(undef, n_col), Array{Cdouble, 1}(undef, n_row),  Array{Cdouble, 1}(undef, n_row))
    # basis = HighsBasis(Array{Cint, 1}(undef, n_col), Array{Cint, 1}(undef, n_row))
    colvalue, coldual = (Array{Cdouble, 1}(undef, n_col), Array{Cdouble, 1}(undef, n_col))
    rowvalue, rowdual = (Array{Cdouble, 1}(undef, n_row),  Array{Cdouble, 1}(undef, n_row))
    colbasisstatus, rowbasisstatus = (Array{Cint, 1}(undef, n_col), Array{Cint, 1}(undef, n_row))

    modelstatus = Ref{Cint}(42)
    status = HiGHS.Highs_call(n_col, n_row, n_nz, colcost, collower, colupper, rowlower, rowupper, matstart, matindex, matvalue, colvalue, coldual, rowvalue, rowdual, colbasisstatus, rowbasisstatus, modelstatus)
    @test status == 0
    @test modelstatus[] == 9 # optimal
end

function test_create()
        ptr = Highs_create()
        @test ptr != C_NULL

        objective = Highs_getObjectiveValue(ptr)
        @test objective == 0.0

        # model status, the second parameter is 
        # bool scaled_model       
        modelstatus = Highs_getModelStatus(ptr, false)
        @test modelstatus[] == 0 # uninitialized LP

        Highs_destroy(ptr)
end

# The ipx code will be updated in the next HiGHS_jll.
# In this release it should be missing, the code below checks that.
# todo:galabovaa edit test after update of HiGHS_jll
function test_ipx()
        ptr = Highs_create()
        @test ptr != C_NULL

        Highs_setHighsStringOptionValue(ptr, "solver", "ipm")

        Highs_run(ptr)

        modelstatus = Highs_getModelStatus(ptr, false)
        @test modelstatus[] != 9 # not optimal 

        Highs_destroy(ptr)
end

function runtests()
    for name in names(@__MODULE__; all = true)
        if startswith(string(name), "test_")
            @testset "$(name)" begin
                getfield(@__MODULE__, name)()
            end
        end
    end
end

end 

TestCHighs.runtests()