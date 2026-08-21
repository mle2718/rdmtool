# Recreational Decision Support Tool for Summer Flounder, Scup, and Black Sea Bass User Guide

## Welcome

This Decision Support Tool (DST) helps fishery management stakeholders answer a
practical question: if a state sets a particular combination of seasons, bag limits, 
and minimum sizes for recreational summer flounder, black sea bass, or scup next
fishing year, what is likely to happen? The DST produces an estimate of the fishing
mortality from the recreational fishery,  how many trips anglers would take, and 
how much better or worse off anglers would be under different combinations of 
fishing regulations. It is built for state and federal fishery managers working
through a regulation-setting cycle, and it does not assume any background in statistics or modeling.

This guide has three parts. The first explains how the tool works and why it gives the
answers it does. The second walks you through the screens. The third helps you
understand the results.

---

## How the Tool Works

### The question this tool helps you answer

Unlike Commercial regulations, recreational regulations work indirectly. Managers 
cannot set recreational harvest the way they set a quota. Instead managers set seasons, 
bag limits, and minimum sizes, and anglers respond deciding whether to go
fishing at all, and once they are on the water, the rules determine which fish 
they can keep and which they must release. Recreational harvest is the result of all those
individual decisions together.

That indirect link is what makes recreational harvest hard to predict. A higher
minimum size reduces harvest.  However, it also increases the 
number of fish released, and some of those released fish die.  
A more restrictive set of rules may make trips less appealing overall, so 
fewer anglers go further reducing mortality.

There is a further complication specific to these three species: anglers often
catch them on the same trip. A regulation aimed at summer flounder changes what
a trip looks like for black sea bass too, because it changes the overall appeal
of going out. The tool handles all three species together for exactly this reason.

### What the tool is built on

Four kinds of information feed the tool.

**What anglers value.** In 2022, we surveyed anglers along the coast from Massachusetts to North Carolina. 
Each person was shown pairs of hypothetical fishing trips that differed in what the trip would cost and in 
how many summer flounder, black sea bass, and scup they would keep or have to release. We simply asked which trip 
they preferred, or whether they would rather do something other than saltwater fishing. These preferences are the behavioral engine 
of the tool. You can view a sample of the [survey](SFSBSBSurvey2022.pdf). 

Those answers reveal a great deal. Anglers value keeping a fish far more than catching and releasing one — for 
summer flounder, by roughly a factor of twelve. Of the three species, summer flounder is worth the most:
the first one kept on a trip is worth about \$35 to a typical angler, against about \$15 for the first black sea bass and 
well under a dollar for scup. Each additional fish is worth less than the one before it, so the fifth fish in the cooler 
does not add nearly as much as the first.

The survey also shows that summer flounder and black sea bass act as **substitutes**. Keeping more black sea bass 
makes each summer flounder worth slightly less, and the reverse. This is why the tool treats the three species as 
one connected fishery rather than three separate ones.

**What anglers actually catch.** Historical catch and effort estimates from the Marine Recreational
Information Program (MRIP) tell us how many trips are taken, when, and by which mode (for hire boat, private boat, or shore).  It 
also tells us how many Summer Flounder, Scup, and Black Sea Bass a trip typically catches. This is where  observed 
variability in trip outcomes comes from; for example many trips catch few fish, 
and a small number catch many.  We have launched the [RecDST data dashboard](https://connect.fisheries.noaa.gov/content/c257deee-a657-4c10-be8a-92827cb5bdfe/)
to help you understand the data that goes into this tool.

**How big the fish are.** Stock assessment projections supply the expected number
of Summer Flounder, Scup, and Black Sea Bass in the water next year for each Age Class. This matters a
great deal for recreational management, because how much a minimum size limit
affects anglers depends entirely on how many fish in the water are near that size.
Combined with historical information about which sizes anglers actually catch, 
this tells the tool what a typical catch looks like.  We know that recreational anglers 
are good at catching fish so we adjust historical catch to take account changes in biomass. For example, if the 
stock assessment contains a very large 3-year old class of fish in 2025, then in 2026, those 4-year old
fish will be a bit longer and the DST accounts for this.

**What trips cost.** Survey data on angler trip expenditures gives the tool a 
realistic spread of trip costs, which is what lets us convert changes in trip 
quality into dollars.

### What the simulation actually does

The simulation builds up a big answer from many small, realistic pieces. Rather 
than applying an average rule to the whole fishery, the tool imagines a very 
large number of individual fishing opportunities and works through each one, 
then adds up the results.

Here is a simplified version of what happens for a single opportunity — 
think of it as one person, on one day, deciding whether to go fishing.

1. **Set the scene.** The tool assigns this person a trip cost and some personal
characteristics like age and avidity level, drawn at random from realistic distributions. 
Age and avidity matter because they affect if people take or do not take a trip.

2. **Figure out what they would catch.** It draws a number of summer flounder, black sea bass, and scup 
from the catch-per-trip patterns for that state, time of year, and mode. Then it gives each individual fish 
a length, drawn from the size distribution of fish anglers are expected to encounter next year.

3. **Apply the rules.** Each fish is checked against the minimum size and bag limit in force on that date, for 
that mode and species. Legal fish are kept until the bag limit is reached; everything else is released.

4. **Decide whether the trip happens.** Now the tool knows what this trip would be like. 
Using the angler preferences from the survey, it works out how appealing the trip is compared with not 
fishing, and converts that into a probability that the trip takes place.
Because each trip contributes in proportion to how likely it is to happen, a set of regulations that makes 
fishing less attractive automatically produces fewer trips and less harvest. 

Once every opportunity has been worked through, the tool expands the results to
the size of the real fishery and converts numbers of fish into pounds. It also
applies discard mortality rates to estimate how many released fish do not survive.

**Calibration.** Before any of this is used to project fishing outcomes, the tool 
is verified against reality. It is set up so that the number of trips it produces
under baseline conditions matches the MRIP estimate for that year, and so that
the harvest it produces matches the MRIP harvest estimate for each state, mode, and species. 

**Repetition.** Finally, the whole process runs 100 times over. Each run uses a 
different plausible set of inputs, reflecting that MRIP estimates and stock 
projections are estimates rather than  exact counts. The result is a  spread of 
outcomes rather than a single number.

**Build a Baseline.** We always provide a set of results for "last year's" conditions 
and rules, giving a baseline for comparison for the same person on the same day.


### Assumptions worth knowing about

A few modeling choices shape how you should read the results.

**This is a one-year projection.** The tool estimates what happens next year given the projected stock. 
It does not carry that year's mortality forward into future stock size.

**Some things simply are not in the model.** Weather is the clearest example. A cold,
wet June will move effort in ways the tool cannot anticipate.

**Regulatory compliance is assumed.** The tool assumes anglers follow the rules.

**Everyone in a state, mode, and season is treated alike.** Within those categories, all anglers draw 
from the same catch and size distributions.  While differences in skill, location, and targeting 
are not modeled individually, the catch and size distributions have these attributes baked in. 

---

## Using the App

### Getting Started

The app opens with two tabs across the top.

**Summary Page** is where you look at results. It shows every model run that has been completed, both 
coastwide and state by state.

**Regulation Selection** is where you build a new scenario and submit it.

Two things to know before you start.

**The summary page takes about a minute to load the first time** you open the app, because it reads in every
 completed run. This is normal.

**The app does not run the model while you wait.** When you submit a scenario, the app saves your 
regulations and puts your run in a queue. The model runs elsewhere and takes a substantial amount of 
time — each state is a separate job. Your results appear on the summary page once it finishes, which
 means you submit, go do something else, and come back later.

[SCREENSHOT: the two main tabs at the top of the app, with the Summary Page open]

### Building a Scenario: the Regulation Selection Tab

The instructions at the top of this tab lay out the sequence: name your policy, 
pick your states, set your regulations, and click Run Me. Take them in that order 
— the regulation controls do not appear until you have selected a state.

#### Step 1: Name your run

The first box asks for a unique name. Use your initials and a number — `AB1`, `AB2`,
and so on. This name labels your run everywhere in the results, so pick something 
you will recognize. Each run needs a different name.

#### Step 2: Choose your states

Below the name box is a row of checkboxes: **MA, RI, CT, NY, NJ, DE, MD, VA, NC**.
Tick every state you want in this run.

When you tick a state, a colored panel of regulation controls appears further down 
the page for that state. Tick several and you get several panels, each in its own 
color. Untick a state and its panel disappears.

Selecting more states means a longer wait for results, since each state is modeled separately.

[SCREENSHOT: run name box and the row of state checkboxes]

#### Step 3: Set the regulations

Each state's panel is laid out in three columns:**Summer Flounder**, **Black Sea Bass**,
and **Scup.** We  pre-loaded current regulations.  If you only want to test one
change, change that one control and leave the rest alone.

The walkthrough below uses **Massachusetts** as the example. Every state works
the same way; they differ only in how many seasons each species offers and in
whether the mode selector described below is available. The table at the end of
this section lists those differences. 


**The three modes.** Regulations are set separately for **For Hire**, **Private**, 
and **Shore**. Each gets its own season dates, bag limit, and minimum size.

**Setting a season.** A season is a slider with two handles running from January 1 
to December 31. Drag the left handle to the opening date and the right handle to
the closing date; the dates display as month and day. Unlike the fishing-year species 
elsewhere in the region, these seasons run on the calendar year.

**Setting a bag limit.** Type a number into the Bag Limit box — the fish per angler per day.

**Setting a minimum size.** Drag the Min Length slider. It moves in **half-inch steps**,
so 17.5 inches is available as well as 17 and 18.

[SCREENSHOT: a season slider, bag limit box, and minimum length slider for one species and mode]

**Summer flounder in Massachusetts.** Three blocks appear, one per mode, each with 
a season, bag limit, and minimum size. 

**Black sea bass in Massachusetts.** This column starts with a dropdown reading
**"Regulations combined or separated by mode?"** with two choices:

- **All Modes Combined** gives you one set of controls — one season, one bag limit
, one minimum size — applied to every mode. Use this when the state's rules are
the same across modes. It is fewer controls to set and fewer chances to make a mistake.
- **Separated By Mode** gives you three sets, one per mode, exactly like summer flounder above.

Switching between the two swaps the controls in place.

Not every state and species offers this dropdown. Where it does not appear,
regulations are always set separately by mode.

[SCREENSHOT: the "Regulations combined or separated by mode?" dropdown with All Modes Combined selected]

**Scup in Massachusetts.** Scup in Massachusetts is set by default to two seasons. 

#### Adding more seasons

Below each species column is an **Add Season** button. Clicking it reveals another
block of season, bag limit, and minimum size controls for every mode of that
species at once. Click again to hide it.

The extra seasons come pre-set to December 31 with a bag limit of zero, which means
they do nothing until you change them. This is deliberate — revealing a season 
does not commit you to using it.

Each state and species has a maximum number of seasons, listed in the table below.
Once you have used them, the Add Season button has nothing further to reveal.

[SCREENSHOT: the Add Season button and the additional season block it reveals]

#### How seasons and closures are handled

Two rules govern how your dates become a fishing calendar.

**Any day not covered by a season is closed.** You do not need to enter a closure.
If a date falls outside every season you have set for a species and mode, no fish 
of that species may be kept that day. Anything caught is released.

**If seasons overlap, the higher-numbered season wins.** Say Season 1 runs May through 
October with a 30-fish bag and Season 2 runs July through August with a 10-fish bag.
July and August will use the 10-fish bag. This is useful when you want a broad season
with a more restrictive window carved out of it — set the general rules as Season 1 
and the exception as Season 2.

**To close a season you have opened,** set its bag limit to zero. Seasons with a 
zero bag limit are dropped from the regulations table in the results, so they will
not clutter your comparison.

#### Step 4: Submit the run

When your regulations are set, click **Run Me**.

**Click it once.** Clicking repeatedly submits the same run more than once. 
After one click, a message confirms your regulations were saved.

To submit another scenario, change the run name first, then adjust your regulations
and click Run Me again.

[SCREENSHOT: the Run Me button and the confirmation message]

#### How states differ

Every state's panel works the way Massachusetts does. These are the differences.

| State | Summer flounder seasons | Black sea bass seasons | Scup seasons | Offers the mode dropdown for |
|---|---|---|---|---|
| **MA** Massachusetts | 2 | 2 | 3 For Hire, 2 Private and Shore | Black sea bass |
| **RI** Rhode Island | 2 | 3 | 4 For Hire, 2 Private and Shore | Summer flounder |
| **CT** Connecticut | 3 | 3 | 4 For Hire, 2 Private and Shore | Summer flounder |
| **NY** New York | 3 | 3 | 4 For Hire, 2 Private and Shore | Summer flounder, black sea bass |
| **NJ** New Jersey | 2 | 5 | 3 | All three species |
| **DE** Delaware | 3 | 3 | 2 | All three species |
| **MD** Maryland | 3 | 3 | 2 | All three species |
| **VA** Virginia | 3 | 3 | 2 | All three species |
| **NC** North Carolina | 2 | 3 | 2 | All three species |

Where a species does not offer the mode dropdown, its regulations are always set 
separately for For Hire, Private, and Shore. 

### Viewing Results: the Summary Page

The Summary Page has two levels. The top of the page compares every state at once.
Below that is a second row of tabs — one per state, plus a Regulations tab — where 
you can look at a single state in detail.

**Everything on this page is measured against the status quo run.** The tool compares
each of your scenarios against a baseline run whose name contains "SQ." If no such
run is present, the percent changes cannot be calculated and the figures will be empty.
If your comparisons look wrong or missing, that is the first thing to check.

[SCREENSHOT: the Summary Page showing the coastwide figure, the summary table, and
the row of state tabs beneath]

---

## Interpreting Your Results

Start at the top of the Summary Page. The coastwide figure and the summary table
tell you, in one look, whether any of your scenarios move harvest in the direction
and by the amount you need. Once you have narrowed the field, go into the state 
tabs for the detail.

Every figure in this tool shares the same horizontal axis: **percent change in harvest from the status quo**. 
Zero means the scenario produces the same harvest as current regulations. Negative 
values are reductions; positive values are liberalizations. This is deliberate —
it lets you see, for any given harvest change, what else comes with it.

### The Coastwide Harvest Change Figure

At the top of the Summary Page is a figure titled **Percentage change in Recreational Harvest By State**.
It is divided into small panels, one per state. Within each panel, the three species
are spread along the horizontal axis and the vertical axis shows the median percent
change in harvest. Each point is one model run, labeled with its run name. A horizontal
line marks zero.

**How to read it.** Find your run's label. Points below the zero line are reductions
in harvest relative to the status quo; points above it are increases. Reading across
the state panels shows you how the same set of rules plays out in different places — a 
coastwide measure rarely produces the same percent change everywhere, because states
differ in their current regulations, their stock availability, and their mix of modes.

Reading across species within a panel shows you the spillovers. A set of rules aimed at
summer flounder will usually move black sea bass and scup harvest too, because changing
the appeal of a trip changes how many trips happen at all.

**Hover over any point** to see the underlying numbers.

[SCREENSHOT: coastwide harvest change figure with panels for each state]

### The Summary Table

Directly below is a sortable table with one row per state and run. Click any column
heading to sort.

| Column | What it shows |
|---|---|
| **State** | The state the row refers to |
| **Run Name** | The name you gave the run |
| **SF Median % Change** | Median percent change in summer flounder harvest weight from the status quo |
| **BSB Median % Change** | Median percent change in black sea bass harvest weight |
| **Scup Median % Change** | Median percent change in scup harvest weight |

These are the same numbers plotted in the figure above, in a form you can sort and read precisely. 
This is usually the fastest way to check whether a scenario delivers the reduction you need. 
Note that harvest here is measured in **weight**, not numbers of fish — which is the basis harvest limits are set on.

[SCREENSHOT: summary table showing percent change columns for several runs and states]

### The State Tabs

Each state tab holds five figures for that state, stacked top to bottom. All five share 
the same horizontal axis — percent change in harvest from the status quo — and all but
the first are split into panels by species.

#### 1. Percentage change in Recreational Harvest

The same figure as the coastwide one, narrowed to this state. It is repeated here so 
you have the harvest change in front of you while reading the four figures below it.

#### 2. Angler Satisfaction

Angler satisfaction in millions of dollars, on the vertical axis, against percent 
change in harvest.

**What the dollar figure means.** This measures how much better or worse off anglers
are under your regulations compared with baseline conditions, in dollars. It is not revenue,
and it is not what anglers spend. It is the dollar value of the change in the quality 
of the fishing they get — the amount of money that would leave anglers exactly as well
off as they were before.

Negative values mean anglers are worse off, and the number is what it would take to 
compensate them so they are as well off as before. Positive values mean they are better off. 
More restrictive sets of rules generally produce more negative values.

**How to use it.** This figure shows the trade-off directly. Two sets of rules that
deliver the same harvest reduction can differ substantially in what they cost anglers.
If you must reduce harvest by a set percentage, this identifies which way of getting
there costs anglers the least. Look for the point that sits highest on the satisfaction
axis among the options that meet your harvest requirement.

The species panels matter here. A set of rules can be nearly costless for scup while being 
expensive for summer flounder, because anglers value the two so differently.

[SCREENSHOT: angler satisfaction figure with panels for each species]

#### 3. Discards

The weight of fish released, in millions of pounds, against percent change in harvest.

**What this is.** These are all released fish, not just the ones that die. It is the 
total weight anglers put back.

**Why it matters.** Discards are the side effect of restriction. Raising a minimum size
reliably reduces harvest, but the fish do not disappear — they get caught and released 
instead. If a scenario delivers its harvest reduction while sending discards sharply upward,
it is achieving the reduction by making anglers throw more fish back, and a share of those
will not survive. That has a conservation cost that the harvest number alone does not show.

[SCREENSHOT: discards figure with panels for each species]

#### 4. Total Mortality

Total mortality against percent change in harvest.

**What this is.** Total mortality is harvest plus dead discards — everything the 
recreational fishery removes. It is calculated by applying discard mortality rates 
to the released fish.

**Why it matters.** This is the number that reflects the fishery's actual removals. 
Harvest and total mortality usually move together, but not always by the same amount. 
A set of rules that cuts harvest hard by raising the minimum size can leave total mortality 
nearly flat, because the fish that stopped being landed are now being released, and some 
of them die anyway. 

[SCREENSHOT: total mortality figure with panels for each species]

#### 5. Number of Trips

Predicted trips, in millions, against percent change in harvest.

**What this tells you.** This is the tool's estimate of how many fishing trips
happen under your regulations. Because the tool decides trip by trip whether
fishing is worth it, restrictive sets of rules produce fewer trips. That drop is part 
of how a set of rules reduces harvest — and it also signals effects beyond the fishery.

If two sets of rules produce similar harvest reductions but one keeps noticeably more trips
on the water, that set of rules delivers the same conservation outcome with less disruption.

[SCREENSHOT: predicted trips figure with panels for each species]

### The Regulations Tab

The last tab in the state row is **Regulations**. It has two parts.

**A table of every submitted scenario**, showing the run name, state, species, mode,
bag limit, minimum size, and season dates. Where you used the All Modes Combined option,
the mode reads "All modes." Seasons you left with a zero bag limit are left out.
Use this to confirm exactly what a run contained — particularly useful when you 
come back to a run submitted weeks earlier, or when you are comparing someone else's
run with your own.

**A download control.** The dropdown lists every completed result file by state 
and run name. Pick one and click **Download Selected File** to save the full results 
to your computer. The download contains every simulation of every measure, not just 
the medians shown in the figures — which is what you want if you need to build your
own summary, put results into a memo or a briefing document, or look at a measure
the app does not display.

[SCREENSHOT: the Regulations tab showing the file dropdown, download button, and regulations table]

### Understanding Uncertainty in Your Results

The tool does not run once. It runs the whole simulation **100 times**, and each
run is called a draw.

**Why there is more than one run.** Several of the tool's inputs are estimates
rather than exact counts. MRIP catch and effort figures come from a survey of 
a sample of anglers, so they carry sampling variability — the estimate of how 
many trips a state took in a given month has a range around it, sometimes a wide 
one. Stock assessment projections of how many fish will be in the water next year,
and at what sizes, come with their own range. So does the average weight of a harvested fish.

For each of the 100 draws, the tool pulls a different plausible value for each of
these inputs, then simulates the entire fishery from start to finish using those
values. The result is 100 answers rather than one — a range of outcomes, all consistent 
with what is actually known about the fishery.

**What the reported numbers are.** Every number in the tables and figures is a
**median** across the 100 draws. The median is the middle value: half the draws 
came in higher, half came in lower. A median is used rather than an average because 
a few extreme draws pull an average around, while the median stays put.

**How the percent changes are calculated.** The tool does not compare one summary
number against another. It compares your scenario against the status quo run **draw by draw**
— draw 1 of your scenario against draw 1 of the status quo, draw 2 against draw 2, and so on
— which produces 100 percent changes. What you see is the median of those. This matters 
because it holds the uncertain inputs constant on both sides of each comparison. 
The percent change you are reading is the effect of the regulations, with the 
year-to-year uncertainty removed from the comparison rather than left to muddy it.

**What this means for reading results.** A median percent change of −12 percent
means that in half the simulations the reduction was larger than 12 percent and 
in half it was smaller. It does not mean the reduction will be exactly 12 percent.
When two scenarios differ by a percentage point or two, that difference is small 
relative to what the tool can resolve, and the two should be treated as roughly 
equivalent. Differences of several percentage points or more are meaningful.

If you need the full spread rather than the middle, download the result file from 
the Regulations tab. Every one of the 100 simulations is in there.

---

## Questions or Feedback

If you have questions about this tool, need help interpreting a run, or want to 
suggest an improvement, contact the RecDST team at nefsc.recdst@noaa.gov.
