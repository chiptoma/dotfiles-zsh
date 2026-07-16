#!/usr/bin/env zsh
# ==============================================================================
# STARTUP PROFILER
# Opt-in, per-stage startup timing. Zero cost when disabled.
# ------------------------------------------------------------------------------
# Modes (Z_PROFILE_STARTUP):
#   unset   - off; the mark functions are no-op stubs
#   true    - EPOCHREALTIME marks around each startup stage; view: z_profile
#   zprof   - zsh/zprof function-level profile, printed at .zshrc tail
# ==============================================================================

# Idempotent guard
(( ${+_Z_PROFILE_LOADED} )) && return 0
typeset -g _Z_PROFILE_LOADED=1

typeset -g _Z_PROFILING=0

if [[ "${Z_PROFILE_STARTUP:-}" == "true" ]]; then
    zmodload zsh/datetime
    typeset -g _Z_PROFILING=1
    typeset -gA _Z_PROFILE_MS=()
    typeset -ga _Z_PROFILE_ORDER=()
    typeset -gF _Z_PROFILE_MARK=0

    _z_prof_start() {
        _Z_PROFILE_MARK=$EPOCHREALTIME
    }

    _z_prof_end() {
        local label="$1"
        local -F delta_ms=$(( (EPOCHREALTIME - _Z_PROFILE_MARK) * 1000 ))
        _Z_PROFILE_MS[$label]="${$(( delta_ms )):0:6}"
        _Z_PROFILE_ORDER+=("$label")
    }
elif [[ "${Z_PROFILE_STARTUP:-}" == "zprof" ]]; then
    zmodload zsh/zprof
fi

# No-op stubs keep call sites free when profiling is off
(( $+functions[_z_prof_start] )) || _z_prof_start() { : }
(( $+functions[_z_prof_end] ))   || _z_prof_end()   { : }
