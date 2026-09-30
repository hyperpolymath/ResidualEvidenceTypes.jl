# SPDX-License-Identifier: MPL-2.0
# Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

# The generic finite checker. Each definition names its counterpart in
# residual-evidence-types/src/ResidualEvidence/Core.agda.

"""
    Case(worlds, observe, retained; evidence = w -> true)

A finite case: the worlds under consideration, the observation `observe(w)`
each world would produce, the observation actually `retained`, and the
`evidence` assumed about the world.

The candidates are the worlds, in the order given, for which
`observe(w) == retained` and `evidence(w)` holds. They are computed once, at
construction. (Agda: `Candidate observe r E`, a world paired with an
observation equality and an evidence proof.)

The Agda `Case` record also carries a proof that some candidate exists. Here
that proof is [`witness`](@ref), and a case without one is still
constructible: [`decide`](@ref) and [`identify`](@ref) report it as
inconsistent rather than letting it entail every claim.
"""
struct Case{W,O,R,E}
    worlds::Vector{W}
    observe::O
    retained::R
    evidence::E
    candidates::Vector{W}
end

function Case(worlds, observe, retained; evidence = _ -> true)
    ws = collect(worlds)
    cs = filter(w -> observe(w) == retained && evidence(w), ws)
    return Case(ws, observe, retained, evidence, cs)
end

"""
    candidates(c::Case)

The worlds that produce the retained observation and satisfy the evidence.
"""
candidates(c::Case) = c.candidates

"""
    isconsistent(c::Case)

`true` when at least one candidate exists.
"""
isconsistent(c::Case) = !isempty(c.candidates)

"""
    witness(c::Case)

The first candidate, or `nothing` when the case is inconsistent. It plays the
part of the consistency proof carried by the Agda `Case` record.
"""
witness(c::Case) = isempty(c.candidates) ? nothing : first(c.candidates)

"""
    refine(c::Case, extra)

The same case with `extra` added to its evidence. Its candidates are exactly
those of `c` that satisfy `extra`. (Agda: `refine-candidate`.)

A claim that [`decide`](@ref) entails for `c` stays entailed for the
refinement, unless the refinement is inconsistent. (Agda: `refine-claim`.)
"""
refine(c::Case, extra) =
    Case(c.worlds, c.observe, c.retained, w -> c.evidence(w) && extra(w),
         filter(extra, c.candidates))

"""
    Verdict

The status of a claim over a case's candidates.

- `ENTAILED`: every candidate satisfies it. (Agda: `Holds c P`.)
- `REFUTED`: no candidate satisfies it.
- `UNRESOLVED`: some candidates do and some do not.
- `INCONSISTENT`: there are no candidates. Nothing follows.
"""
@enum Verdict ENTAILED REFUTED UNRESOLVED INCONSISTENT

"""
    Decision

The result of [`decide`](@ref): a `status`, the first candidate that satisfies
the claim (`supporting`) and the first that does not (`counterexample`). Each is
`nothing` when no such candidate exists.
"""
struct Decision{W}
    status::Verdict
    supporting::Union{W,Nothing}
    counterexample::Union{W,Nothing}
end

"""
    decide(c::Case, claim)

Evaluate the predicate `claim` over every candidate of `c`.

An `UNRESOLVED` verdict carries both witnesses. The counterexample is the
reason the claim is not established. The supporting candidate is the reason
it cannot be ruled out either.
"""
function decide(c::Case{W}, claim) where {W}
    isempty(c.candidates) && return Decision{W}(INCONSISTENT, nothing, nothing)
    i = findfirst(claim, c.candidates)
    j = findfirst(!claim, c.candidates)
    supporting = i === nothing ? nothing : c.candidates[i]
    counterexample = j === nothing ? nothing : c.candidates[j]
    status = counterexample === nothing ? ENTAILED :
             supporting === nothing ? REFUTED : UNRESOLVED
    return Decision{W}(status, supporting, counterexample)
end

"""
    IdStatus

Whether a query takes a single value across the candidates.

- `IDENTIFIED`: one value. (Agda: `Identified c query`.)
- `UNIDENTIFIED`: two or more values. Any two candidates that disagree refute
  identification. (Agda: `different-candidates-refute-identification`.)
- `NO_CANDIDATE`: the case is inconsistent.
"""
@enum IdStatus IDENTIFIED UNIDENTIFIED NO_CANDIDATE

"""
    Identification

The result of [`identify`](@ref): a `status` and the distinct `values` the
query takes over the candidates, in ascending order.
"""
struct Identification{V}
    status::IdStatus
    values::Vector{V}
end

"""
    identify(c::Case, query)

The values `query` takes over the candidates of `c`, deduplicated and sorted,
and whether there is exactly one. The query's values must be ordered by
`isless`.
"""
function identify(c::Case, query)
    vs = sort!(unique(map(query, c.candidates)))
    status = isempty(c.candidates) ? NO_CANDIDATE :
             length(vs) == 1 ? IDENTIFIED : UNIDENTIFIED
    return Identification(status, vs)
end
