# SPDX-License-Identifier: MPL-2.0
# Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#
# Row-for-row agreement with the table residual-evidence-types generates from
# its explorer page, test/fixtures/ExplorerTable.agda.
#
# Fixture source: hyperpolymath/residual-evidence-types, branch
# feat/phase3-harness, commit 4ee1d6f0e65b592a09501f5ed6a25f1ad49e9c10,
# file tests/correspondence/ExplorerTable.agda. Copied unedited; the sha256
# below pins it. To update: copy the file again, then update the hash and the
# commit named here in the same change.

using SHA

const FIXTURE = joinpath(@__DIR__, "..", "fixtures", "ExplorerTable.agda")
const FIXTURE_SHA256 = "2baa79f2dd0ac98d0e92c92919e0f2aad07a9cb69c6f44712d2fc1b0dd452b86"

# Agda.Builtin.Int spells n >= 0 as `pos n` and n < 0 as `negsuc (-n - 1)`.
agda_int(tag, n) = tag == "pos" ? parse(Int, n) : -parse(Int, n) - 1

const VIEWS = Dict("exact" => EXACT, "sign" => SIGN, "magnitude" => MAGNITUDE)
const VERDICTS = Dict("entailed" => ENTAILED, "refuted" => REFUTED,
                      "unresolved" => UNRESOLVED, "inconsistent" => INCONSISTENT)
const IDS = Dict("identified" => IDENTIFIED, "unidentified" => UNIDENTIFIED,
                 "no-candidate" => NO_CANDIDATE)
const ROW = r"^(?:    |  ∷ )row \((pos|negsuc) (\d+)\) (\d+) (\w+) (true|false) (\d+) (\w+) ([\w-]+) (.*)$"

function parse_fixture(path)
    rows = Row[]
    for line in eachline(path)
        m = match(ROW, line)
        m === nothing && continue
        values = [agda_int(x[1], x[2]) for x in eachmatch(r"(pos|negsuc) (\d+)", m[9])]
        push!(rows, Row(agda_int(m[1], m[2]), parse(Int, m[3]), VIEWS[m[4]], m[5] == "true",
                        parse(Int, m[6]), VERDICTS[m[7]], IDS[m[8]], values))
    end
    return rows
end

@testset "correspondence with the Agda explorer table" begin
    @test bytes2hex(open(sha256, FIXTURE)) == FIXTURE_SHA256
    @test occursin("model 'signed-integer-v1'", read(FIXTURE, String))
    @test MODEL == "signed-integer-v1"

    expected = parse_fixture(FIXTURE)
    actual = explorer_table()
    @test length(expected) == 546
    @test length(actual) == 546
    mismatches = [(i, e, a) for (i, (e, a)) in enumerate(zip(expected, actual)) if e != a]
    isempty(mismatches) || @info "first mismatch" mismatches[1]
    @test isempty(mismatches)
end
