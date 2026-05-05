# RPi 4B gem5 validation

Cross-compiled aarch64 controller binaries + input datasets for validating
gem5 (ARM Cortex-A72) timing predictions against a real Raspberry Pi 4B.

Source: `DSE_Quadruped/quadruped_dse/computer_hardware/controls_cpp/build_arm/`.
Binaries are statically linked aarch64 ELFs; no runtime deps on the RPi side.

## Layout

```
bin/         17 aarch64 controller binaries (stripped)
datasets/    10 dataset directories (states.bin + metadata.json + ...)
models/      MuJoCo model assets (only obstacle.json is used at runtime)
config.yaml  controller config template
setup.sh     installs an absolute-path symlink for MODEL_DIR
run_all.sh   runs every (binary × matching dataset) combination
```

## Usage on the Pi

```bash
git clone <repo-url>
cd rpi_validation
./setup.sh        # one-time: links models/ to the path baked into the binaries
./run_all.sh      # runs all controllers on all datasets, writes results/<tag>.bin + .log
```

`MODEL_DIR` is hardcoded at compile time to
`/home/abg309/PhD/RCL/DSE_Quadruped/quadruped_dse/mechanical_properties/models`.
Only `MPC_controller` and `ConstVel_controller` reference it (for
`obstacle.json`); failure to load is non-fatal — the binary warns and runs
with empty obstacle data. `setup.sh` symlinks that path so the warning
goes away.

## Single-run usage

```bash
./bin/<binary> ./datasets/<dataset> ./config.yaml output=./results/<tag>.bin
```

The `output=` arg is optional; default is `<dataset>/gem5_results.bin`.

## Output format

Each `.bin` file is the binary log written by `write_results()` in
`gem5_common.hpp`:

```
"GEM5"    4-byte magic
uint32    version (=2)
uint64    dataset_name length + bytes
uint64    controller_name length + bytes
uint64    num_steps
uint32    num_legs
  per leg: uint64 name_len + bytes, uint32 joints_per_leg
per step:
  int64   elapsed_ns
  int32   qp_iterations  (-1 if N/A)
  per leg: joints_per_leg × float64 torques
```

Compare `elapsed_ns` against the gem5 simulated cycles (`m5_rpns()`) for the
same binary + dataset on `arm_A72.py` to validate the simulator.

## Binary → dataset mapping (from `gem5_runner.py`)

| Binary                                | Datasets                                |
|---|---|
| `NMPC_controller_{N7,N12}`            | `NMPC_origami`, `NMPC_aliengo`          |
| `NMPCGaitFreq_controller_{N7,N12}`    | `NMPCGaitFreq_origami`, `NMPCGaitFreq_aliengo` |
| `Default8_controller`                 | `Default8_origami`                      |
| `Default12_controller`                | `Default12_aliengo`                     |
| `ConstVel_controller`                 | `ConstVel_origami`, `ConstVel_aliengo`  |
| `MPC_controller_{MPC6,MPC10}`         | `MPC_origami`, `MPC_aliengo`            |

`run_all.sh` covers exactly these combinations. The `_N7`/`_N12` suffixed
binaries for `Default8/12`, `ConstVel`, and `MPC_controller` (16 total)
are byproducts of NMPC horizon sweeps and are duplicates of their
unsuffixed/MPC-tagged counterparts; ignore unless you want to diff.