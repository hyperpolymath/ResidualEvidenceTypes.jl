# SPDX-License-Identifier: MPL-2.0
# Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

# The finite model `signed-integer-v1`: a residual r = u + n, with u the
# unresolved contribution and n the noise, both integers in -LIMIT..LIMIT.
# It is the model of residual-evidence-types' explorer page, and Row is the
# vocabulary of src/ResidualEvidence/Finite/Row.agda in that repository.

"""
    MODEL

The name of the finite model, as the explorer and the generated Agda table
record it.
"""
const MODEL = "signed-integer-v1"

"""
    LIMIT

The bound on every integer in the model: residuals and both contributions lie
in `-LIMIT:LIMIT`, and a noise bound lies in `0:LIMIT`.
"""
const LIMIT = 6

"""
    View

How much of the residual is retained: all of it (`EXACT`), only its sign
(`SIGN`), or only its absolute value (`MAGNITUDE`).
"""
@enum View EXACT SIGN MAGNITUDE

_retain(v::View, x::Int) = v == EXACT ? x : v == SIGN ? sign(x) : abs(x)

"""
    SignedWorld(latent, noise)

One world of the model: the unresolved contribution `latent` (u) and the
`noise` contribution (n). It produces the residual `latent + noise`.
"""
struct SignedWorld
    latent::Int
    noise::Int
end

"""
    signed_integer_case(; residual = 2, noise_bound = LIMIT, view = EXACT, assume_zero = false)

The [`Case`](@ref) for an observed `residual` under the additive model
r = u + n.

The worlds are every `(latent, noise)` pair in `-LIMIT:LIMIT`, latent outer.
The retained observation is `residual` seen through `view`. The evidence is
`abs(noise) <= noise_bound`, and, with `assume_zero`, `latent == 0`.

A noise bound restricts the model. It is not evidence that real noise obeys
it.
"""
function signed_integer_case(; residual::Integer = 2, noise_bound::Integer = LIMIT,
                             view::View = EXACT, assume_zero::Bool = false)
    abs(residual) <= LIMIT ||
        throw(ArgumentError("residual must be an integer from -$LIMIT to $LIMIT, got $residual"))
    0 <= noise_bound <= LIMIT ||
        throw(ArgumentError("noise bound must be an integer from 0 to $LIMIT, got $noise_bound"))
    worlds = [SignedWorld(u, n) for u in -LIMIT:LIMIT for n in -LIMIT:LIMIT]
    return Case(worlds, w -> _retain(view, w.latent + w.noise), _retain(view, Int(residual));
                evidence = w -> abs(w.noise) <= noise_bound && (!assume_zero || w.latent == 0))
end

"""
    Row

One configuration of the model and what follows from it: the candidate
`count`, the verdict on the presence claim `latent != 0`, the identification
status of `latent`, and the latent values that remain.

The fields and their order are those of `Row` in
`ResidualEvidence/Finite/Row.agda`.
"""
struct Row
    residual::Int
    noise_bound::Int
    view::View
    assume_zero::Bool
    count::Int
    presence::Verdict
    identity::IdStatus
    values::Vector{Int}
end

Base.:(==)(a::Row, b::Row) =
    all(getfield(a, f) == getfield(b, f) for f in fieldnames(Row))
Base.hash(r::Row, h::UInt) = foldr(hash, (getfield(r, f) for f in fieldnames(Row)); init = h)

"""
    row(; residual, noise_bound, view = EXACT, assume_zero = false)

The [`Row`](@ref) for one configuration.
"""
function row(; residual::Integer, noise_bound::Integer, view::View = EXACT,
             assume_zero::Bool = false)
    c = signed_integer_case(; residual, noise_bound, view, assume_zero)
    presence = decide(c, w -> w.latent != 0)
    identity = identify(c, w -> w.latent)
    return Row(residual, noise_bound, view, assume_zero, length(candidates(c)),
               presence.status, identity.status, Vector{Int}(identity.values))
end

"""
    explorer_table()

Every configuration of the model, 546 rows, in the order the Agda table uses:
residual ascending (outermost), then noise bound, then view (`EXACT`, `SIGN`,
`MAGNITUDE`), then `assume_zero` (`false` before `true`).
"""
explorer_table() =
    [row(; residual, noise_bound, view, assume_zero)
     for residual in -LIMIT:LIMIT
     for noise_bound in 0:LIMIT
     for view in instances(View)
     for assume_zero in (false, true)]
