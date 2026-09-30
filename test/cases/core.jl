# SPDX-License-Identifier: MPL-2.0
# Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#
# The generic checker on a hand-sized case, independent of the finite model.

@testset "core" begin
    # Worlds are (a, b) with a, b in 0:2; we observe only a + b.
    worlds = [(a, b) for a in 0:2 for b in 0:2]
    c = Case(worlds, w -> w[1] + w[2], 2)

    @test candidates(c) == [(0, 2), (1, 1), (2, 0)]
    @test isconsistent(c)
    @test witness(c) == (0, 2)

    @testset "decide returns a witness each way" begin
        d = decide(c, w -> w[1] > 0)
        @test d.status == UNRESOLVED
        @test d.supporting == (1, 1)
        @test d.counterexample == (0, 2)

        @test decide(c, w -> w[1] + w[2] == 2).status == ENTAILED
        @test decide(c, w -> w[1] + w[2] == 2).counterexample === nothing
        @test decide(c, w -> w[1] > 2).status == REFUTED
        @test decide(c, w -> w[1] > 2).supporting === nothing
    end

    @testset "identify" begin
        i = identify(c, w -> w[1])
        @test i.status == UNIDENTIFIED
        @test i.values == [0, 1, 2]
        s = identify(c, w -> w[1] + w[2])
        @test s.status == IDENTIFIED
        @test s.values == [2]
    end

    @testset "refinement keeps entailed claims and can resolve open ones" begin
        r = refine(c, w -> w[2] <= 1)
        @test candidates(r) == [(1, 1), (2, 0)]
        @test candidates(r) == filter(w -> w[2] <= 1, candidates(c))
        @test decide(r, w -> w[1] > 0).status == ENTAILED
        @test identify(r, w -> w[1]).status == UNIDENTIFIED
        @test decide(r, w -> w[1] + w[2] == 2).status == ENTAILED
    end

    @testset "an empty candidate set entails nothing" begin
        e = refine(c, _ -> false)
        @test !isconsistent(e)
        @test witness(e) === nothing
        @test decide(e, _ -> true).status == INCONSISTENT
        @test decide(e, _ -> false).status == INCONSISTENT
        @test identify(e, w -> w[1]).status == NO_CANDIDATE
        @test isempty(identify(e, w -> w[1]).values)
        @test isempty(candidates(Case(worlds, w -> w[1] + w[2], 9)))
    end
end
