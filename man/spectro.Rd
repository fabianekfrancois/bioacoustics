% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/spectro.R
\name{spectro}
\alias{spectro}
\title{Plot a spectrogram}
\usage{
spectro(wave, channel = "left", FFT_size = 256, FFT_overlap = 0.875,
  FFT_win = "hann", LPF, HPF = 0, tlim = NULL, flim = NULL,
  ticks_y = NULL, col = gray.colors(25, 1, 0))
}
\arguments{
\item{wave}{a \link[tuneR]{Wave} object.}

\item{channel}{character. Channel to keep for analysis in a stereo recording: "left" or "right". Default setting is left.}

\item{FFT_size}{integer. Size of the Fast Fourrier Transform (FFT) window. Default setting is 256.}

\item{FFT_overlap}{numeric. Percentage of overlap between two FFT windows (from 0 to 1). Default setting is 0.875.}

\item{FFT_win}{character. Specify the type of FFT window: "hann", "blackman4", or "blackman7".
Default setting is "hann".}

\item{LPF}{integer. Low-Pass Filter (Hz). Frequencies above the cutoff are greatly attenuated.
Default setting is the Nyquist frequency of the recording.}

\item{HPF}{integer. High-Pass Filter (Hz). Frequencies below the cutoff are greatly attenuated.
Default setting is 0 Hz.}

\item{tlim}{numeric. Specify the time limits on the X-axis in seconds (s).
Default setting is \code{NULL}, i.e no time limits.}

\item{flim}{numeric. Specify the frequency limits on the Y-axis in Hz. Default
setting is \code{NULL}, i.e. frequency limits are equal to \code{c(0, LPF)}.}

\item{ticks_y}{numeric. Whether tickmarks should be drawn on the frequency Y-axis or not.
The lower and upper bounds of the tickmarks and their intervals (in Hz) has to be specified.
Default setting is \code{NULL}.}

\item{col}{set the colors for the amplitude scale (dB) of the spectrogram.}
}
\description{
Plot a spectrogram
}
\examples{
data(myotis)
spectro(myotis, tlim = c(1, 2))

}
