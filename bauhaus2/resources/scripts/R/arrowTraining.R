#!/usr/bin/env Rscript
## N.B. This requires R libraries that are installed in the module R/3.2.3-bauhaus

## Training script for Arrow consensus models.  Steps: 1 - Loads a set of aligned BAM files 2 - Subsamples these to get small 'windows'
## of alignments 3 - Creates an outcome variable for these alignments by encoding PW:BP as 1-12 4 - Removes grossly discordant data (read
## length nowhere near ref length) 5 - Fits model using the hmm function 6 - Saves the fit for later use/investigation.  7 - Outputs
## cpp/json files ready to use with ConsensusCore2 8 - Outputs plots of transition/emission probabilities

## TODO: move 'cpp' and 'json' writers into the unitem library proper

suppressPackageStartupMessages({
  library(pbbamr)
  library(unitem)
  library(ggplot2)
  library(reshape2)
  library(scales)
  library(data.table)
  library(argparse)
  library(logging)
  library(jsonlite)
  library(nnet)  ## Need this in order for coef(...$cfit) to work, should be fixed by moving into unitem
  library(GenomicRanges)  ## Required for masking
})

## FIXME: make a real package
myDir = "./scripts/R"
source(file.path(myDir, "Bauhaus2.R"))

###### DEFINITIONS #######
use8Contexts = F
predictPw = T
nOutcome = 12
maskMargin = 1000


## Encode an outcome variable for the 'Emmission' in the HMM model
mkOutcome <- function(aln) {
  aln <- subset(aln, select = c(read, ref, ipd, pw, snrA, snrC, snrG, snrT))
  # Remove dummy placeholders (no read for a ref position) to avoid making more than 20 levels of the factor, these 'Deletion' states will
  # be removed anyway
  pw = aln$pw
  pw[pw == 0] = 1  # Template bases with no observation associated with them
  # Change PW to 1-3 encoding
  pw[pw > 3] = 3
  read = aln$read
  read[read == "-"] = "C"  # Dummy value that overlaps with an actual factor, hack to avoid accounting for delete case
  # Generate the outcome factor
  if (predictPw) {
    aln$outcome = factor(pw, levels = c(1, 2, 3)):factor(read, levels = c("A", "C", "G", "T"))
  } else {
    aln$outcome = factor(read, levels = c("A", "C", "G", "T"))
  }
  # Generate channel-specific SNR
  ctx = unitem::GenerateDinucleotideContextFromGappedRef(aln$ref, use8Contexts)
  snr = aln$snrA
  if (use8Contexts) {
    snr[ctx == "NC" | ctx == "CC"] = aln$snrC[1]
    snr[ctx == "NG" | ctx == "GG"] = aln$snrG[1]
    snr[ctx == "NT" | ctx == "TT"] = aln$snrT[1]
  } else {
    snr[ctx == "AC" | ctx == "CC" | ctx == "GC" | ctx == "TC"] = aln$snrC[1]
    snr[ctx == "AG" | ctx == "CG" | ctx == "GG" | ctx == "TG"] = aln$snrG[1]
    snr[ctx == "AT" | ctx == "CT" | ctx == "GT" | ctx == "TT"] = aln$snrT[1]
  }
  aln$snr = snr
  aln
}


## Filter alignents where read/reference differ by more than 50%
filterData <- function(data) {
  isGood <- function(x) {
    if (x$ref[1] == "-" | x$ref[length(x$ref)] == "-") {
      return(FALSE)
    }
    nm = sum(x$read != "-")
    no = sum(x$ref != "-")
    diff = abs(1 - nm/no)
    diff < 0.5
  }
  Filter(isGood, data)
}


## Clean the model to make for a smaller data file
cleanFit <- function(fit) {
  fit$pseudoCounts = NULL
  fit$modelMatrix = NULL
  mdls = fit$models
  cleanModel <- function(mdl) {
    # mdl$cfit$fitted.values = NULL
    mdl$cfit$residuals = NULL
    # mdl$cfit$weights = NULL
    mdl$toUse = NULL
    # Save the model to allow for plotting of TransitionPs
    mdl$model.matrix = model.matrix(mdl$cfit)
    attr(mdl$cfit$terms, ".Environment") <- NULL
    attr(mdl$cfit$terms, "dataClasses") <- NULL
    attr(mdl$cfit$terms, "predvars") <- NULL
    mdl
  }
  cleanmdls = lapply(mdls, cleanModel)
  # save(cleanmdls, file='context_models.rda')
  fit$models = cleanmdls
  fit
}


## Output model to .cpp
outputModelToCpp <- function(fit, fname) {
  if (file.exists(fname))
    file.remove(fname)

  outputEmissions <- function(fit, fname) {
    mats = list(list(m = data.matrix(fit$mPmf), n = "matchPmf"), list(m = data.matrix(fit$bPmf), n = "branchPmf"), list(m = data.matrix(fit$sPmf),
      n = "stickPmf"))
    renderMatrix <- function(mat) {
      renderRow <- function(i) {
        paste("        {", paste(formatC(mat$m[i, 1:nOutcome], width = 15, digits = 9), collapse = ", "), "}")
      }
      paste("    {// ", mat$n, "\n", paste(sapply(1:nrow(mat$m), renderRow), collapse = ",\n"), "}", sep = "")
    }
    val <- paste("constexpr size_t OUTCOME_NUMBER = 12;\n", paste("constexpr size_t CONTEXT_NUMBER = ", nrow(fit$mPmf), ";\n", sep = ""),
      "constexpr double emissionPmf[3][CONTEXT_NUMBER][OUTCOME_NUMBER] = {\n", paste(sapply(mats, renderMatrix), collapse = ",\n"),
      "};\n", sep = "")
    write(val, file = fname, append = T)
  }

  outputTransitions <- function(fit, fname) {
    renderMatrix <- function(ctxFit, ctx) {
      cos = coef(ctxFit)
      renderRow <- function(x) {
        paste("        {", paste(formatC(cos[x, ], width = 15, digits = 9), collapse = ", "), "}")
      }
      paste(paste("    {// ", ctx, "\n", sep = ""), paste(sapply(1:3, renderRow), collapse = ",\n"), "}", sep = "")
    }
    val <- paste("constexpr double transProbs[CONTEXT_NUMBER][3][4] = {\n", paste(sapply(fit$models, function(m) renderMatrix(m$cfit,
      m$ctx)), collapse = ",\n"), "};\n", sep = "")
    write(val, file = fname, append = T)
  }

  outputEmissions(fit, fname)
  outputTransitions(fit, fname)
}


## Output to json file
extractTransitionArray <- function(fit) {
  extractTransitonMatrix <- function(cfit, ctx) {
    cos <- coef(cfit)
    names(cos) <- NULL
    unclass(cos)
  }
  array(data = lapply(fit$models, function(m) extractTransitonMatrix(m$cfit, m$ctx)))

}

outputModelToJson <- function(fit, snrRanges) {
  x <- list()
  x$ConsensusModelVersion <- unbox("3.0.0")
  x$ChemistryName <- unbox("trained_condition")
  if (predictPw) {
    x$ModelForm <- unbox("PwSnr")
  } else {
    x$ModelForm <- unbox("Snr")
  }
  x$SnrRanges <- snrRanges
  x$EmissionParameters <- array(data = as.array(list(data.matrix(fit$mPmf)[, 1:nOutcome], data.matrix(fit$bPmf)[, 1:nOutcome], data.matrix(fit$sPmf)[,
    1:nOutcome])))
  x$TransitionParameters <- extractTransitionArray(fit)
  jsonOut <- file(file.path(args$output, "fit.json"), "wt")
  cat(toJSON(x, digits = I(9), pretty = TRUE), file = jsonOut)
  close(jsonOut)
}


## Plot emission, transition probabilities
plotEmissions <- function(fit, report) {
  mats = list(fit$mPmf, fit$bPmf, fit$sPmf)
  titles = c("Match", "Cognate Extra", "Non-Cognate Extra")
  titles = paste(titles, "Emission Rates")
  for (i in 1:3) {
    df = reshape2::melt(mats[[i]], id.vars = "CTX", value.name = "prob", variable.name = "outcome")
    if (predictPw) {
      df$BP = sapply(as.character(df$outcome), function(x) strsplit(x, ":")[[1]][2])
    } else {
      df$BP = as.character(df$outcome)
    }
    q = ggplot(df, aes(x = outcome, y = prob, fill = BP)) + geom_bar(stat = "identity") + facet_wrap(~CTX) + theme_bw(base_size = 10) +
      labs(x = "PW:BP", y = "Emission Rates", title = titles[i]) + ylim(0, 1)
    id = gsub(" ", "-", tolower(titles[i]))
    report$ggsave(
        paste0(id, ".png"),
        q,
        id = id,
        title = titles[i],
        caption = titles[i])
  }
}

plotTransitions <- function(fit, report) {
  for (i in 1:length(fit$models)) {
    cmodel = fit$models[[i]]$cfit
    tg = data.frame(cbind(predict(cmodel, type = "probs")))
    colnames(tg) <- c("Match", "Cognate Extra", "Non-Cognate Extra", "Delete")
    snr = fit$models[[i]]$model.matrix[, 2]
    tg$SNR = snr
    ctx = fit$models[[i]]$ctx
    tp = reshape2::melt(tg, id.vars = "SNR", value.name = "rate", variable.name = "Transition")
    q = ggplot(tp, aes(x = SNR, y = rate)) + geom_smooth(fill = NA) + facet_wrap(~Transition, scales = "free") + labs(title = paste(ctx,
      "Rates")) + theme_bw() + scale_y_continuous(label = percent)
    id = paste0(ctx, "-transition-rates")
    title = paste(ctx, "Transition Rates")
    report$ggsave(
        paste0(id, ".png"),
        q,
        id = id,
        title = title,
        caption = title)
  }
}

masker <- function(maskfile) {
  loginfo("loading masked regions from %s", maskfile)

  df.mask <- read.csv(
    file=maskfile,
    header=FALSE,
    sep="\t",
    col.names=c("seqname", "source", "feature", "start", "end", "score", "strand", "frame", "attributes"),
    colClasses=c("character", "character", "character", "integer", "integer", "character", "character", "character", "character"))

  # add left and right padding to increase safety margin
  createStartMargin <- function(x) {
    sapply(x, function(y) max(y - maskMargin, 1))
  }
  createEndMargin <- function(x) {
    x + maskMargin
  }

  df.mask["start"] <- lapply(df.mask["start"], createStartMargin)
  df.mask["end"] <- lapply(df.mask["end"], createEndMargin)

  maskedRegions <- makeGRangesFromDataFrame(df.mask)

  maskOutData <- function(x) {
    maskWrapper <- function(y) {
      read <- GRanges(
        y["ref"],
        IRanges(start = as.numeric(y["tstart"]), end = as.numeric(y["tend"])),
        strand="*")

      # if there is an overlap with a masked region, discard the read
      results <- findOverlaps(maskedRegions, read, type="any", select="all", ignore.strand=TRUE)
      hits <- queryHits(results)

      return (length(hits) == 0)
    }
    result <- apply(x, 1, maskWrapper)
    return(result)
  }
}


## Do the training, hooking everything up
doTrain <- function(args) {
  loginfo("Loading BAM indices")
  alnFiles = Sys.glob(file.path(normalizePath(args$alnFilesDir), "*.alignmentset.xml"))
  indexes = lapply(alnFiles, loadPBI)

  # remove empty indices
  indexes = Filter(nrow, indexes)

  # sample the BAMs and trim, to get alignment windows of ~140 bp from each of 3000 ZMWs per BAM
  getSamples <- function(i) {
    alnFile = alnFiles[[i]]
    loginfo("Loading samples from %s", alnFile)
    pbi = indexes[[i]]

    maskfile <- paste(alnFile, ".mask.gff", sep = "")
    if (file.exists(maskfile)) {
      loginfo("Filtering masked data from %s", alnFile)
      maskfilter <- masker(maskfile)
      valid_idx <- which(maskfilter(pbi))

      loginfo("Input reads for %s: %d", alnFile, nrow(pbi))
      loginfo("Number of reads after filtering for %s: %d (%.1f%%)", alnFile, length(valid_idx), length(valid_idx) / nrow(pbi) * 100)
    }
    else {
      loginfo("Sampling from complete dataset")
      valid_idx <- 1:nrow(pbi)
    }

    sampled_idx <- sample(valid_idx, min(length(valid_idx), args$zmwsPerBam))
    sampled_data <- pbi[sampled_idx,]
    large_alns = loadAlnsFromIndex(sampled_data, paste(alnFile, ".ref.fa", sep = ""))
    f_large_alns = Filter(function(x) nrow(x) > args$targetAlnLength, large_alns)
    small_alns = lapply(f_large_alns, function(x) trimAlignment(x, trimToLength = args$targetAlnLength))
    small_alns
  }
  alns = lapply(1:length(indexes), getSamples)
  alns = unlist(alns, recursive = FALSE)

  loginfo("Encoding sample data")
  training_data = lapply(alns, mkOutcome)

  loginfo("Filtering highly discrepant alignments")
  filt_training = filterData(training_data)

  fit <- hmm(outcome ~ snr + I(snr^2) + I(snr^3), filt_training, filter = FALSE, end_dif = 0.00015, use8Contexts = use8Contexts)
  print(fit)

  loginfo("Saving fit data")
  fit.cleaned <- cleanFit(fit)
  save(fit.cleaned, file = file.path(args$output, "fit.rda"), compress = TRUE)

  ## Get RANGE of SNR values fit for clamping
  loginfo("Calculating SNR clamp range")
  alns = data.frame(data.table::rbindlist(filt_training))

  qRange <- function(xs) {
    c(quantile(xs, 0.01), quantile(xs, 0.99))
  }

  snrRanges <- rbind(qRange(alns$snrA), qRange(alns$snrC), qRange(alns$snrG), qRange(alns$snrT))

  list(fit = fit, fit.cleaned = fit.cleaned, snrRanges = snrRanges)
}


if (!interactive()) {
  sink(stdout(), type = "message")
  logging::basicConfig()

  parser <- ArgumentParser()
  parser$add_argument("alnFilesDir", nargs = 1, help = "path to the training data")
  parser$add_argument("--seed", nargs = 1, type = "integer", default = 42, help = "seed value for setSeed")
  parser$add_argument("--zmwsPerBam", nargs = 1, type = "integer", default = 5000, help = "number of ZMWs to sample ber BAM file")
  parser$add_argument("--targetAlnLength", nargs = 1, type = "integer", default = 140, help = "target length of alignment slices")
  parser$add_argument("--noPw", dest = "predictPw", action = "store_false", help = "omit PulseWidth emissions from the model")
  parser$add_argument("--use8Contexts", action = "store_true", help = "use 8 context model instead of the default 16")
  parser$add_argument("-o", "--output", nargs = 1, default = getwd(), help = "output directory [default = \"%(default)s\"]")

  # args <- list(alnFilesDir = "training", seed = 42, zmwsPerBam = 5000, targetAlnLength = 140)
  args <- parser$parse_args()
  set.seed(args$seed)
  predictPw <<- args$predictPw
  use8Contexts <<- args$use8Contexts
  if (predictPw) {
    nOutcome <<- 12
  } else {
    nOutcome <<- 4
  }

  training <- doTrain(args)

  report <- bh2Reporter("condition-table.csv", "reports/ArrowTraining/report.json", "Consensus arrow training")

  loginfo("Outputting model to fit.cpp")
  outputModelToCpp(training$fit, file.path(args$output, "fit.cpp"))

  loginfo("Outputting model to fit.json")
  outputModelToJson(training$fit, training$snrRanges) # TODO: have these represented in the report

  loginfo("Plotting emission, transition probabilities")
  plotEmissions(training$fit.cleaned, report)
  plotTransitions(training$fit.cleaned, report)

  ## Dump the ctt table
  # report$write.table("coverage-titration.csv", tbl, id = "coverage-titration", title = "Coverage titration summary table")

  ## Generate plots
  report$write.report()
  loginfo("Done!")
}
