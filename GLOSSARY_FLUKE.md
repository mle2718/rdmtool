# flukeRDM: Glossary of Recurring Terms

Companion to the in-code documentation. This covers the programming and
package-specific vocabulary that recurs across the flukeRDM comments and
headers — the things an intermediate R or Stata programmer might not have met
in *this* combination, plus the terms this codebase uses in its own particular
way. It deliberately does not explain basic language mechanics.

Domain terms (harvest, discards, waves, modes) are included only where the code
treats them as structural, because they shape how the data is keyed.

---

## Pipeline structure

**Wrapper script** — A script whose job is to run other scripts in order,
usually turning steps on and off with flags, rather than processing data
itself. flukeRDM has three: `Code/pre_sim/model_wrapper.do` (Stata),
`Code/sim/R code wrapper.R`, and `Run_Model.R`. Unlike GroundfishRDM, they are
not chained — each must be started by hand, in the right order.

**Toggle** — A `0`/`1` local macro in `model_wrapper.do` that gates whether a
step runs. Three of flukeRDM's toggles gate nothing at all; see
`FLAGGED_ISSUES_FLUKE.md`.

**Meta-toggle** — A toggle that gates several scripts as one unit rather than
one script. `catch_per_trip_project` is the only one; it controls four scripts
that cannot be run individually without editing the wrapper.

**Prototype mode** — The `proto` local in `model_wrapper.do`. When on (the
committed default) it overwrites `$ndraws` with 3, producing a fast test run
rather than a production run.

**Entry point** — A script a person starts directly, as opposed to one that
gets called. flukeRDM has three, which is why running the pipeline requires
knowing the order.

## Stata idioms

**Global macro** — A named value defined with `global`, referenced as `$name`,
visible to every script that runs afterwards in the same Stata session.
flukeRDM uses these for directory paths (`$misc_data_cd`), sample definitions
(`$calibration_year`), and settings (`$ndraws`, `$seed`). Because they persist
for the whole session, a global set by one script silently affects every later
one.

**Local macro** — Defined with `local`, referenced as `` `name' ``, and
discarded at the end of the script or block. The wrapper's toggles are locals,
which is why they cannot be inspected after a run finishes.

**The accumulate idiom** — The pattern
`global mylist "$mylist "newitem" "`, which re-expands a global and appends to
it, building a space-separated list of individually quoted items. Used in
`MRIP_lists.do` to build file lists and in `estimate_angler_preferences.do` to
collect tempfile paths. The quoting matters because the paths can contain
spaces.

**`tempfile`** — A scratch dataset that exists only for the current Stata
session and is deleted automatically. Used heavily here to hold intermediate
results, since Stata holds only one dataset in memory at a time.

**`preserve` / `restore`** — Save the in-memory dataset, do something
destructive to it, then get it back. The usual way to compute something on a
subset without losing the main dataset.

**`capture`** — Runs a command and swallows any error. Convenient for
"create this directory if it doesn't exist", but it hides genuine failures —
which is exactly how the `mkdir` bug in `model_wrapper.do` went unnoticed.

**`postfile`** — Writes results one row at a time to a file as a loop runs.
Used in `survey_trip_costs.do` where each row needs its own survey estimation
and so cannot be produced by `collapse`.

**Variable abbreviation** — With `set varabbrev on` (set repo-wide in the
wrapper), a variable can be referred to by any unambiguous prefix, so `common`
can mean `common_dom`. Stata still prefers an exact match when one exists.

**User-written command** — A command installed from SSC rather than shipped
with Stata. flukeRDM depends on `xsvmat`, `gammafit`, `grc1leg`, `rscript`,
`renvarlab`, `dsconcat`, `here` and `distinct`. Scripts fail with "unrecognized
command" if these are missing.

**`svyset` / `svy:`** — Declares the survey sampling design, after which
estimation commands account for weights, strata and clustering. MRIP and the
expenditure survey are both complex surveys, so a plain `mean` would give the
wrong standard errors.

**`browse`** — Opens Stata's interactive data editor. It halts a
non-interactive session, which is why the scripts containing it are marked as
run-by-hand.

## R idioms

**`data.table`** — A high-performance alternative to `data.frame`. Its
bracket syntax `dt[i, j, by]` is a small language of its own, and it modifies
objects **by reference**: `setDT(x)` changes `x` for every reference to it,
not just the local one. That is why one test script's file-level `setDT()` call
is flagged — sourcing it mutates the caller's data.

**`:=`** — data.table's assign-by-reference operator. `dt[, newcol := value]`
adds a column without copying the table.

**Non-standard evaluation (NSE)** — Where a function receives an unevaluated
expression rather than a value, letting you write `dt[state == "MA"]` with
`state` as a bare column name. Convenient interactively; the reason
`get("colname")` and `..varname` appear when a column must be chosen
programmatically.

**`fst` / `feather`** — Fast binary columnar file formats. flukeRDM converts
Stata `.dta` and `.csv` inputs to these purely for speed, because the
simulation re-reads the same files inside nested loops. Both formats appear
because the project migrated from feather to fst mid-development; some scripts
still read the older format.

**`furrr` / `future`** — Parallel execution. `future::plan()` chooses how many
worker processes to use and `furrr::future_map_dfr()` runs a function across
them, stacking the results. `furrr_options(seed = TRUE)` gives each worker an
independent random stream so parallel draws are not accidentally identical.

**`setDTthreads(1)`** — Restricts data.table to one thread *inside* each
parallel worker. Without it, every worker would try to use all cores at once.

**`here::here()`** — Builds a path from the project root rather than the
current working directory, so scripts run the same regardless of where they are
started from. Note that many flukeRDM scripts bypass it with absolute paths.

**`conflicts_prefer()`** — Declares which package wins when two provide the
same function name. Needed here because `plyr` and `dplyr` are both attached
and share names like `summarize` and `count`.

**Roxygen2** — The `#'` comment convention for documenting R functions, with
tags like `@param` and `@return`. Used throughout this codebase's
documentation even though flukeRDM is not an R package.

**`assign()` into an environment** — Creating a variable whose *name* is
computed at run time. The per-state model scripts use it to turn each row of a
regulation CSV into a named object, which is why identifiers like
`SFmaFH_seas1_op` appear in the code with no visible definition.

**`exists()`** — Tests whether a name is defined. Because the regulation
objects are created dynamically by `assign()`, this is the only way the code
can tell whether a scenario supplied statewide or mode-specific rules.

**Reactive (Shiny)** — An expression that re-runs automatically when its
inputs change. `reactive()` computes a value, `observeEvent()` performs an
action, and `render*()` produces UI output.

## Modeling and data vocabulary

**Draw** — One complete realization of the simulation. Uncertain inputs are
redrawn each time, so results are summarized across draws. Confusingly, the
codebase uses "draw" at several scales: `$ndraws` / `n_simulations` count whole
simulation replicates, `catch_draw` indexes the 30 catch outcomes per simulated
trip, and `ndraws = 50` in the projection code means choice occasions per
stratum.

**Stratum** — The grouping the model works in: state × wave × mode, sometimes
also by kind-of-day. Nearly every table in the pipeline is keyed this way.

**Wave** — A two-month MRIP sampling period; wave 1 is January–February through
wave 6 for November–December. Regulations, effort and catch are all reported at
this resolution.

**Mode** — How the trip was taken: `pr` private boat, `fh` for-hire (charter
and party boats), `sh` shore.

**Kind-of-day** — Weekend versus weekday, used for effort estimation. MRIP
counts federal holidays as weekend days, which is why the wrapper carries an
explicit holiday list.

**Directed trip** — A trip that targeted or caught one of the three managed
species. The denominator the whole model works in.

**Calibration year vs projection year** — The calibration year is the recent
year the model is tuned to reproduce; the projection year is the future year
whose regulations are being evaluated. Columns suffixed `_y2` hold
projection-year values.

**Status quo (SQ)** — The run using current regulations, against which
candidate scenarios are compared.

**Copula** — A way of simulating several correlated quantities while letting
each keep its own distribution. Used here because harvest and releases of three
species on the same trip move together, and simulating them independently would
understate how often very good and very poor trips occur.

**Reallocation / the proportion `p`** — The calibration's adjustment for the
fact that anglers do not perfectly follow the rules. `rel_to_keep` converts a
fraction of modeled releases into harvest (undersized fish kept);
`keep_to_rel` does the reverse (legal fish voluntarily released). `p` is that
fraction, found by search, and it is a fitted calibration parameter rather than
an estimated behavior.

**Accounting vs utility columns** — During reallocation, a fish moved from kept
to released must count as released in the totals compared to MRIP, but still
count as kept when computing whether the angler wanted to take the trip.
`calibrate_rec_catch1_final.R` therefore carries `_new` columns (accounting)
alongside `_util` columns (behavioral).

**Fish-level expansion** — Expanding a trip's catch count into one row per
fish. Necessary because a bag limit binds on individual fish in the order they
are caught, which cannot be recovered from trip totals.

**Hurdle (two-part) model** — Modeling "did this happen at all" separately from
"how much". Used for trip costs, where many trips report zero expenditure and
no single continuous distribution fits both the spike at zero and the positive
values.

**Catch-at-length** — The length composition of the fish anglers encounter.
This is what makes a minimum size limit bite, and it is the channel through
which the stock assessment enters the model.

**Age-length key** — A table converting numbers-at-age (what the assessment
produces) into numbers-at-length (what a size limit acts on), built here from
NEFSC trawl survey data.

**The 254 sentinel** — A minimum size of 254 (100 inches × 2.54 cm) meaning the
season is closed and no fish is legal. Its Stata counterpart is the bare `100`
in `set_regulations.do`. Sizes are stored in centimetres; the app collects them
in inches, hence the recurring `* 2.54`.

## Cross-cutting terms used in the documentation

**Orphaned** — Defined but never called or sourced by anything.
`Code/sim/apply_directed_trips_regs.R` is the clearest case.

**Dead toggle** — A toggle defined in the wrapper with no matching `if` block,
so setting it has no effect.

**Near-duplicate** — Two files that do the same job with only cosmetic
differences, maintained separately. The two copula scripts differ in about 18
lines out of 730.

**Sentinel value** — A specific value standing in for a condition rather than a
measurement: `254` for a closed season, `-3` for a missing FES age, `100`
inches for "no legal harvest".

**Stale reference** — A path or name that pointed at something real before a
rename. The broken projection path is the significant example.
