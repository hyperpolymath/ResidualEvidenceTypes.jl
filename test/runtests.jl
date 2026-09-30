# SPDX-License-Identifier: MPL-2.0
# Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#
# ResidualEvidenceTypes — test entry point.
#
#   1. Aqua package-shape gate, first: a package that does not load cleanly,
#      or whose exports are ambiguous, fails before any behaviour test runs.
#   2. Behaviour: every test/cases/*.jl, in name order.

using Test
using ResidualEvidenceTypes

@testset "ResidualEvidenceTypes — Aqua package shape" begin
    using Aqua
    Aqua.test_all(ResidualEvidenceTypes)
end

@testset "ResidualEvidenceTypes — behaviour" begin
    # No `continue`/`break` inside a `for` inside @testset: filter with a guard.
    cases = joinpath(@__DIR__, "cases")
    for path in sort(readdir(cases, join = true))
        endswith(path, ".jl") && include(path)
    end
end
