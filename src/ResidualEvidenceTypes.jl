# SPDX-License-Identifier: MPL-2.0
# Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

"""
    ResidualEvidenceTypes

What an observation establishes about the worlds that could have produced it.

A [`Case`](@ref) holds a finite set of worlds, the observation each world
would produce, the observation actually retained, and the evidence assumed.
Its candidates are the worlds that produce the retained observation and satisfy
the evidence. [`decide`](@ref) says whether a claim holds for every candidate,
for none, or for some but not all, and returns a witness each way.
[`identify`](@ref) says whether a query takes one value across the candidates.
An empty candidate set is reported as inconsistent, never as vacuous truth.

These are the executable counterparts of `Candidate`, `Case`, `Holds` and
`Identified` in the Agda development
[residual-evidence-types](https://github.com/hyperpolymath/residual-evidence-types).
The finite `signed-integer-v1` model reproduces that repository's explorer
table, row for row.
"""
module ResidualEvidenceTypes

export Case, candidates, isconsistent, witness, refine,
       Verdict, ENTAILED, REFUTED, UNRESOLVED, INCONSISTENT, Decision, decide,
       IdStatus, IDENTIFIED, UNIDENTIFIED, NO_CANDIDATE, Identification, identify,
       View, EXACT, SIGN, MAGNITUDE, SignedWorld, signed_integer_case,
       Row, row, explorer_table, MODEL, LIMIT

include("core.jl")
include("signed_integer.jl")

end # module
