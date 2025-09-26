#!/bin/bash

EXTRA_ARGS=()

declare -i SIGNAL_DISABLE_GPU="${SIGNAL_DISABLE_GPU:-0}"
declare -i SIGNAL_DISABLE_GPU_SANDBOX="${SIGNAL_DISABLE_GPU_SANDBOX:-0}"

# add wayland specific command line arguments
if [[ ${XDG_SESSION_TYPE:-} == "wayland" ]]; then
    EXTRA_ARGS+=("--enable-wayland-ime" "--wayland-text-input-version=3")

    # work around electron's broken wayland detection
    # TODO: remove when signal uses an electron release that includes the fix
    # https://github.com/electron/electron/pull/48301
    EXTRA_ARGS+=("--ozone-platform=wayland")
fi

if [[ "${SIGNAL_DISABLE_GPU}" -eq 1 ]]; then
    EXTRA_ARGS+=(
        "--disable-gpu"
    )
fi

if [[ "${SIGNAL_DISABLE_GPU_SANDBOX}" -eq 1 ]]; then
    EXTRA_ARGS+=(
        "--disable-gpu-sandbox"
    )
fi

echo "Debug: Will run signal with the following arguments:" "${EXTRA_ARGS[@]}"
echo "Debug: Additionally, user gave: $*"

export TMPDIR="${XDG_RUNTIME_DIR}/app/${FLATPAK_ID}"
exec zypak-wrapper "/app/Signal/signal-desktop" "${EXTRA_ARGS[@]}" "$@"
