plot_title = "Doop Log Frequency"

# 24 hours (in seconds).
capture_seconds = 60 * 60 * 24

# Format plot.
set title plot_title
set term wxt title plot_title size 900,700 font "sans,12"
set datafile separator comma
set grid
# Sets the left and bottom sides, unsets the top and right sides.
set border 3
# Only have tics on the left, at twice the normal scale.
set tics nomirror out scale 2
set key outside center bottom  title " " font ",8"
# Prevent dates from overflowing the view.
set lmargin 10
set rmargin 10
# Properly format x & y axes.
set xlabel "Date"
set xtics timedate format "%m/%d/%y"
set ylabel "Occurences"

# Line styles
set style fill transparent solid 0.5 border
set linetype 1 linecolor "gray"                 # Entries
set linetype 2 linecolor "dark-turquoise"       # Info
set linetype 3 linecolor "chartreuse"           # Warn
set linetype 4 linecolor "light-red"            # Error
set linetype 5 linecolor "violet"               # Mean

# Macro that automatically bins times together within intervals of `capture_seconds`. To be used for an X position.
bin_x = "(capture_seconds * floor(timecolumn(1, \"%s\") / capture_seconds))"

# Enable non-linear scaling. This uses scaling based off of a square root, rather than logarithms, for a softer curve.
if (ARG2 eq "nonlinear") {
    scale_y_normal(y) = sqrt(y)
    scale_y_inverse(y) = y ** 2

    set nonlinear y via scale_y_normal(y) inverse scale_y_inverse(y)
}

# Throwaway plot to calculate the highest bin.
#
# TODO: Currently, this throws away the highest value.
#       This may be amended by moving `max` and `y` outside of the plot's scope,
#       and then adding another check after plotting.
plot max = 0, y = 0, last = 0 ARG1 using @bin_x:( \
    time = @bin_x, last == time \
        ? (y = y + 1, 0) \
        : (last = time, y > max ? max = y : 0, y = 1, 1) \
    )

# Set the Y axis's maximum value to the maximum value, rounding up to the nearest 10.
set yrange [0:((floor(max / 10) * 10) + (max % 10 == 0 ? 0 : 10))]
# Add tics every 10 units, with extras added manually at the beginning.
set ytics autofreq 10
set ytics add (5, 15, 25)
# Discard the generated plot.
clear

# Simple macros to reduce repetition.
freq_fill = "smooth frequency with fillsteps"
freq_step = "smooth frequency with steps"
freq_line = "smooth frequency with lines"
type_is = "stringcolumn(2) eq"

# Generates a macro string that creates a step plot with both fill and a border.
freq_plot(title, type, style) = \
    "'' using @bin_x:(@type_is \"" . type . "\" ? 1 : 0) " . \
        "@freq_fill title \"" . title . "\" ls " . style . ", " . \
    "'' using @bin_x:(@type_is \"" . type . "\" ? 1 : 0) " . \
        "@freq_step notitle ls " . style . " lw 2"

# Generated plot types.
freq_plot_info = freq_plot("Info logs", "info", 2)
freq_plot_warn = freq_plot("Warn logs", "warn", 3)
freq_plot_error = freq_plot("Error logs", "error", 4)

# TODO: Ensure the logic for the cumulative mean is *actually* correct.
plot sum = 0, y = 0, last = 0, bin = 0 \
    ARG1 using @bin_x:(1) @freq_fill title "Entries per day" ls 1, \
    '' using @bin_x:(1) @freq_step notitle ls 1 lw 2, \
    \
    @freq_plot_info, @freq_plot_warn, @freq_plot_error, \
    \
    '' using @bin_x:( \
        time = @bin_x, last == time \
            ? (y = y + 1, 0) \
            : (last = time, bin = bin + 1, sum = sum + y, y = 1, sum / (bin + 1)) \
        ) \
        @freq_line title "Cumulative mean" ls 5 lw 2
