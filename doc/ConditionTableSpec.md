Condition table specification for `bauhaus2`
============================================

What is this?
-------------

PacBio has an internal tertiary-analysis server called **Milhouse**.
Milhouse accepted a tabular format called a **condition table** as input
and would drive secondary analyses of raw data from different conditions
(two different sequencing chemistries, for example), ultimately then
performing comparative analyses between conditions using a battery of R
scripts. The end result would be a web page where you could navigate to
comparison plots/reports of interest.

**pbexperiment** is an attempt to codify the input specification for a
Milhouse-like system, but with support for both current BAM PacBio data.

/pbexperiment is not intended to be compatible with Milhouse, but rather
for a future Milhouse replacement or for other tertiary analysis tools./

*This is a work in progress.*

Definitions
-----------

A tertiary experiment is defined by an **analysis protocol** and a
**condition table**.

The analysis protocol defines what types of comparative plots/tables
will be generated, and implies the secondary analysis tasks that must be
run.

The condition table is a table that will be provided to the tertiary
analysis engine (perhaps interactively), indicating the input data
associated with each "condition" to analyze, and optionally recording
**variables** taking values for each condition.

Condition table schema
----------------------

The columns of the condition table encode: the **condition** name, some
specification of where the analysis **input** is to be found, and some
optional **variables**.

### "Condition" column

The "Condition" column records a name for each condition to be analyzed
and compared against other conditions. Multiple rows may share the same
condition, in which case the inputs are (conceptually) combined before
analysis.

### Input columns

Input can be either secondary data representing a mapping job, or a
primary run, in which case the tertiary engine will itself launch
mapping jobs if required by the analysis protocol.

Secondary analysis results can be specified as input data using the
columns

-   `SMRTLinkServer` and `JobId`, *xor*
-   `JobPath`, *xor*
-   `AlignmentSet`

Primary analysis input data can be encoded using columns

-   `RunCode` and `ReportsFolder` (subdirectory of run directory), *xor*
-   `ReportsPath`, *xor*
-   `SubreadSet`

Legacy primary analysis data is (`bax.h5` files) is **not** supported.

**Input data can only be specified in one way within a condition
table.** This limitation means, for example, that primary data and
secondary data can't be mixed within an experiment; nor can other types
of input source be mixed.

### Variables

Usually an experiment seeks to determine the effect of one or more
variables on some outcome measure. Variables can be used by the tertiary
analysis engine to show plots that are faceted/conditioned by one ore
more variable, making it possible to see the variable effect. The user
can encode variables as follows.

**Explicit variables** can be specified, arbitrarily, by using column
names that begin with "p\_". **Implicit variables** do not have a "p\_"
prefix; for one reason or another, the implicit variables have
significance to the workflow engine, they are not treated as simply as
something to facet/condition on in plots. At present, the only implicit
variables are as follows:

-   The mandatory column "Genome" in resequencing-based workflows is
    used to identify the mapping reference to use.

To restate: these implicit variables inform the logic in the workflow
execution and are also available for conditioning/faceting in final
tertiary analysis plots.

\*Variables must have a single value within a condition. Inputs with
different variable values are not exchangeable, so we disallow combining
them under a single condition name.\*

Example condition tables
------------------------

Here's a simple example of a condition table for resequencing-based
analysis:

| Condition   | RunCode      | ReportsFolder | Genome    | p_SnrT  |
|-------------|--------------|---------------|-----------|---------|
| Foo-r1      | 3150113-0001 |               | FooGenome | 5       |
| Foo-r2      | 3150113-0002 |               | FooGenome | 6       |
| Foo-HighSNR | 3150113-0003 |               | FooGenome | 10      |
| Bar         | 3150113-0004 |               | BarGenome | 6       |

Note that ReportsFolder is empty; the default "ReportsFolder" in the
Sequel world is now "" (same directory as the "trc.h5") so ReportsFolder
is left blank to get the default basecaller output. (For RS instruments,
the default ReportsFolder was `Analysis_Results`)

Here, we are treating each input as a separate condition; the first two
rows are being treated as two **replicates** and will run through
secondary analysis independently and will generate separate points in
some plots (though they may be binned together in some plots conditioned
on SNR).

Now, suppose we want to consider all the reads from the "normal SNR Foo"
runs as being homogeneous; we'd like to combine them together---perhaps
each run had low yield, and we need to combine them to get adequate
coverage for some analysis. We can do so by changing the condition table
as follows:

| Condition   | RunCode      | ReportsFolder | Genome    | p_SnrT  |
|-------------|--------------|---------------|-----------|---------|
| Foo         | 3150113-0001 |               | FooGenome | LOW     |
| Foo         | 3150113-0002 |               | FooGenome | LOW     |
| Foo-HighSNR | 3150113-0003 |               | FooGenome | HIGH    |
| Bar         | 3150113-0004 |               | BarGenome | LOW     |

Here, to satisfy the rule that "variables have a single value within a
condition", we have had to manually bin the variable `p_SnrT`.

In either case, since both of these runs specify a `RunCode` and
`ReportsFolder`, analysis begins from primary analysis data. Since this
is a resequencing-based analysis, the first step will be to perform
mapping.

Destiny of the condition table
------------------------------

We will store the condition table in CSV format in the tertiary job
directory for later inspection.

TODO: typed variables?
----------------------

One of the shortcomings of the "p\_" encoding of variables was that it
was never clear how it was to be interpreted. For example, is it numeric
or a factor (and if is an ordinal factor, how do we make the order
clear)? This is mainly important when it comes time to plot using the
variable as a color. Anyway, it would be nice if we could find a way to
encode this information.

Credits
-------

There is a lot of brilliance in the design of the original Milhouse, and
the credit for that all belongs to Jim Bullard.
