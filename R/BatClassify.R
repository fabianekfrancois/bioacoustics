#' Blob detection of a region into a spectrogram representation of the recording
#'
#' This function is a modified version of the Bat classify software developed by Christopher Scott (2014).
#' It combines several detection, filtering and audio feature extraction processes.
#'
#' @inheritParams threshold_detection
#'
#' @param min_area integer. Minimum area threshold in number of pixels.
#' Extracted segments with an area shorter than this threshold are discarded.
#' Default setting is 40 pixels.
#'
#' @param blur integer. Gaussian smoothing function for blurring the spectrogram of the audio event to reduce image noise.
#' Default setting is 2.
#'
#' @param contrast_boost integer.Edge contrast enhancement filter of the spectrogram of the audio event to improve its apparent sharpness.
#' Default setting is 20.
#'
#' @param bg_substract integer. Foreground extraction with a mean filter applied on the spectrogram of the audio even for image denoising.
#' Default setting is 20.
#'
#' @export
#'
#' @importClassesFrom tuneR Wave
#' @importFrom graphics axis box legend lines par plot text
#' @importFrom grDevices png
#' @importFrom methods is slot
#' @importFrom stats setNames
#'
#' @examples
#' data(myotis)
#' Output <- blob_detection(myotis, time_exp = 10, contrast_boost = 30, bg_substract = 30)
#' Output$event_data
#'
#' @rdname blob_detection
#'

blob_detection <- function(wave,
                           channel = 'left',
                           time_exp = 1,
                           min_dur = 1.5,
                           max_dur = 80,
                           min_area = 40,
                           TBE = 20,
                           EDG = .9,
                           LPF,
                           HPF = 16000,
                           FFT_size = 256,
                           FFT_overlap = 0.875,
                           blur = 2,
                           bg_substract = 20,
                           contrast_boost = 20,
                           settings = FALSE,
                           acoustic_feat = TRUE,
                           metadata = FALSE,
                           spectro_dir = NULL,
                           time_scale = 0.1,
                           ticks = TRUE)
{
  if (!is(wave, 'Wave'))
    wave <- read_audio(wave)

  filename <- attr(wave, 'filename')

  sample_rate <- slot(wave, 'samp.rate') * time_exp
  n_bits <- slot(wave, 'bit')

  if(missing(LPF))
    LPF <- sample_rate / 2

  if(missing(LPF))
    LPF <- sample_rate / 2
  else
    LPF <- min(LPF, sample_rate / 2)

  blobs <- blob_detection_impl(audio_samples = slot(wave, channel <- ifelse(slot(wave, 'stereo'), channel, 'left')),
                               sample_rate = sample_rate,
                               LPF = LPF,
                               HPF = HPF,
                               TBE = TBE,
                               EDG = EDG,
                               FFT_size = FFT_size,
                               FFT_overlap = FFT_overlap,
                               min_d = min_dur,
                               max_d = max_dur,
                               area = min_area,
                               blur_f = blur,
                               bg_substract = bg_substract,
                               boost = contrast_boost)

  if (length(blobs) == 0)
  {
    message(
      "No audio events found",
      if (!is.null(filename)) paste0(" for file '", basename(filename), "'")
    )
  }
  else
  {
    audio_events <- list( event_data = blobs[[1L]] )

    if (!acoustic_feat)
      audio_events$event_data <- audio_events$event_data[, c('starting_time', 'duration')]

    if ( !is.null(spectro_dir) )
    {
      if ( !dir.exists(file.path(spectro_dir, 'spectrograms')) )
        stopifnot(dir.create(file.path(spectro_dir, 'spectrograms'), recursive = TRUE)) # Stop if directory creation fails

      if (is.logical(ticks))
      {
        if (ticks)
        {
          ticks_at <- seq(0, FFT_size, length.out = 12) / FFT_size
        }
      }
      else if (is.numeric(ticks))
      {
        ticks_at <- seq(ticks[1L], ticks[2L], ticks[3L]) / (sample_rate / 2)
        ticks <- TRUE
      }

      bare_name <- if (!is.null(filename)) tools::file_path_sans_ext(filename)
      html_file <- paste0('spectrograms--', bare_name, format(Sys.time(), '--%y%m%d--%H%M%S'), '.html')

      tags <- htmltools::tags

      fft_step <- floor(FFT_size * (1 - FFT_overlap))

      html_doc <- tags$html(
        tags$head(
          tags$title(html_file)
        ),
        tags$body(
          htmltools::tagList(
            lapply(
              1:length(blobs[[2]]),
              function(i)
              {
                png_file <- file.path('spectrograms', paste0(format(Sys.time(), '%y%m%d--%H%M%S--'), bare_name, '--', i, '.png'))
                png(file.path(spectro_dir, png_file), width = (((1 - FFT_overlap) * FFT_size) / sample_rate * 1000) * ncol(blobs[[2]][[i]]) / time_scale)
                par(mar = rep_len(0L,4L), oma = c(.1,.1,.1,.1))
                .spectro(data = to_dB(rotate90(blobs[[2]][[i]]), ref = 2^(n_bits-1)), colors = gray.colors(25, 1, 0))
                lgd <- legend('topright', legend = NA, inset = 0, box.col = NA)
                text(x = lgd$rect$left + min(lgd$rect$w, 1) / 2L, y = lgd$text$y, labels = i, adj = .5)
                if (ticks)
                {
                  axis(2, at = ticks_at, tcl = .4, col = NA, col.ticks = 'black', labels = FALSE)
                }
                box()
                dev.off()
                tags$img(src = png_file)
              }
            )
          )
        )
      )

      htmltools::save_html(html = html_doc, file = file.path(spectro_dir, html_file))
      utils::browseURL(file.path(spectro_dir, html_file)) # Open html page on favorite browser
    }

    if (metadata)
    {
      audio_events$metadata <- list(
        sample_rate = sample_rate,
        n_bits = n_bits
      )
    }

    if (settings)
    {
      audio_events$settings$blob_detection <- data.frame(
        channel = channel,
        min_dur = min_dur,
        max_dur = max_dur,
        min_area = min_area,
        LPF = LPF,
        HPF = HPF,
        EDG = EDG,
        FFT_size = FFT_size,
        FFT_overlap = FFT_overlap,
        blur = blur,
        bg_substract = bg_substract,
        EDG = EDG,
        contrast_boost = contrast_boost,
        stringsAsFactors = FALSE
      )
    }

    # Add info about filename if x is a file path
    if (!is.null(filename))
      audio_events$event_data <- cbind(data.frame(filename = filename), audio_events$event_data)

    return(audio_events)
  }
}
