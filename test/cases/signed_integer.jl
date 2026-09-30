# SPDX-License-Identifier: MPL-2.0
# Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#
# The signed-integer-v1 model: the explorer's presets, and two properties that
# must hold of every row.

@testset "signed-integer-v1" begin
    @testset "presets (the explorer's five buttons)" begin
        # ambiguous: r = 2, |n| <= 6. u = 0, n = 2 explains the residual.
        c = signed_integer_case(residual = 2, noise_bound = 6)
        d = decide(c, w -> w.latent != 0)
        @test d.status == UNRESOLVED
        @test d.counterexample == SignedWorld(0, 2)
        @test d.supporting == SignedWorld(-4, 6)
        @test identify(c, w -> w.latent).values == collect(-4:6)

        # present: r = 2, |n| <= 1. u is nonzero, but not identified.
        c = signed_integer_case(residual = 2, noise_bound = 1)
        @test candidates(c) == [SignedWorld(1, 1), SignedWorld(2, 0), SignedWorld(3, -1)]
        @test decide(c, w -> w.latent != 0).status == ENTAILED
        @test identify(c, w -> w.latent).status == UNIDENTIFIED
        @test identify(c, w -> w.latent).values == [1, 2, 3]

        # exact: no noise, so the residual is u.
        c = signed_integer_case(residual = 2, noise_bound = 0)
        @test identify(c, w -> w.latent).status == IDENTIFIED
        @test identify(c, w -> w.latent).values == [2]

        # cancel: a zero residual does not show that u is zero.
        c = signed_integer_case(residual = 0, noise_bound = 6)
        @test decide(c, w -> w.latent != 0).status == UNRESOLVED
        @test decide(c, w -> w.latent == 0).status == UNRESOLVED

        # conflict: assuming u = 0 with |n| <= 1 cannot produce r = 2.
        c = signed_integer_case(residual = 2, noise_bound = 1, assume_zero = true)
        @test isempty(candidates(c))
        @test decide(c, w -> w.latent != 0).status == INCONSISTENT
        @test decide(c, w -> w.latent == 0).status == INCONSISTENT
    end

    @testset "retaining only the sign loses the value" begin
        c = signed_integer_case(residual = 2, noise_bound = 0, view = SIGN)
        @test identify(c, w -> w.latent).values == collect(1:6)
        c = signed_integer_case(residual = 2, noise_bound = 0, view = MAGNITUDE)
        @test identify(c, w -> w.latent).values == [-2, 2]
    end

    @testset "arguments outside the model are refused" begin
        @test_throws ArgumentError signed_integer_case(residual = 7)
        @test_throws ArgumentError signed_integer_case(residual = -7)
        @test_throws ArgumentError signed_integer_case(noise_bound = -1)
        @test_throws ArgumentError signed_integer_case(noise_bound = 7)
    end

    table = explorer_table()
    at(r, b, v, z) = only(filter(x -> (x.residual, x.noise_bound, x.view, x.assume_zero) == (r, b, v, z), table))

    @testset "a tighter noise bound never overturns a settled verdict" begin
        # Lowering the bound adds evidence. What was entailed or refuted stays
        # so, or the case becomes inconsistent (Agda: refine-claim).
        settled = true
        for r in -LIMIT:LIMIT, v in instances(View), z in (false, true), b in 1:LIMIT
            hi, lo = at(r, b, v, z), at(r, b - 1, v, z)
            settled &= lo.count <= hi.count
            settled &= lo.values ⊆ hi.values
            settled &= hi.presence ∉ (ENTAILED, REFUTED) || lo.presence ∈ (hi.presence, INCONSISTENT)
        end
        @test settled
    end

    @testset "retaining more of the residual never adds candidates" begin
        fewer = true
        for r in -LIMIT:LIMIT, b in 0:LIMIT, z in (false, true)
            e = at(r, b, EXACT, z)
            fewer &= e.count <= at(r, b, SIGN, z).count
            fewer &= e.count <= at(r, b, MAGNITUDE, z).count
        end
        @test fewer
    end
end
