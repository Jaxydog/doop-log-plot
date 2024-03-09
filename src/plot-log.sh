# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright © 2024 Jaxydog
#
# This file is part of Doop Log Plot.
#
# Doop Log Plot is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# Doop Log Plot is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with Doop Log Plot. If not, see <https://www.gnu.org/licenses/>.

cli_args="hgnf:"

display_usage() {
    echo -e "Usage: $0 [file] [$cli_args]\n"
    echo -e "-h\t\tDisplays this message."
    echo -e "-g\t\tGenerate a new CSV file."
    echo -e "-n\t\tUse a non-linear vertical scaling method."
    echo -e "-f [file]\tUse the provided CSV file."
}

if [[ -z "$1" ]]; then
    display_usage
    exit 1
fi

# Store and remove the first argument
log_file="$1"
shift

csv_file="$log_file.csv"
generate_csv=0
scaling_method="linear"

while getopts "$cli_args" arg; do
    case $arg in
        g) generate_csv=1;;
        n) scaling_method="nonlinear";;
        f) csv_file=$OPTARG;;
        h | *) display_usage; exit 0;;
    esac
done

if [[ $generate_csv == 1 ]]; then
    echo "Generating CSV file..."
    echo "" > "$csv_file"

    declare -i count
    count=0

    while read -r line; do
        date=$(echo "$line" | grep -oP '(?<=^\[)(\d{2}-?){3} (\d{2,}[:.]?){4}' | awk -F'[- ]' '{ printf("%s-%s-%sT%s-0500\n", $3, $2, $1, $4) }')
        type=$(echo "$line" | grep -oP '(?<=\()[a-z]+')
        text=$(echo "$line" | grep -oP '(?<=\) )[^:]+')

        date=$(date -d "$date" +"%s")

        echo "$date,$type,$text" >> "$csv_file"
        count+=1
    done < "$log_file"

    echo "Created $count entries within '$csv_file'."
fi

echo "Generating plot..."

gnuplot -p -e "call \"./plot-csv.gp\" \"$csv_file\" \"$scaling_method\""
