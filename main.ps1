$main = Get-Content ./main.csv
$aux = Get-Content ./aux.csv
 
$main_table = [ordered]@{ }
$aux_table = [ordered]@{ }
$date_format ="MM/dd/yyyy"
$output_buffer = @()
 
#build in memory table for main file
 
foreach ($line in $main) {
    $values =
    $line -split "," 
    $temp_arr = @()
 
    $date = [datetime]::ParseExact($values[1], $date_format , $null)
    if ( $main_table.Contains($values[0])) {
        $temp_arr =
        $main_table[$values[0]] +
        $date
    }
    else {
        $temp_arr += $date
    }
 
    $main_table[$values[0]] =
    $temp_arr
}
 
#build in memory table for aux file
 
foreach ($line in $aux) {
 
    $values =
    $line -split ","
    $temp_arr =@()
    $date = [datetime]::ParseExact($values[1], $date_format , $null)
 
    if ($aux_table.Contains($values[0])) {

        $temp_arr =$aux_table[$values[0]] + $date
    }
    else {
        $temp_arr +=$date
    }
    $aux_table[$values[0]] = $temp_arr
}
 
# Sort main table by dates in case input wasn't sorted so it looks better when we print it
foreach ($key in $($main_table.keys)) {
    $dates =
    $main_table.Item($key)
    $main_table[$key] = $dates | Sort-Object
}
 
foreach ($key in $($aux_table.Keys)) {
    $dates = $aux_table.Item($key)
    $aux_table[$key] = $dates | Sort-Object
}
 
# Iterate through main table to compare dates with
# aux table
 
foreach ($h in $main_table.Keys) {
 
    #Write-Host "${h}: $($main_table.Item($h))"
    $dates = $main_table.Item($h)
 
    foreach ($date in $dates) {
 
        $date_string = $date.ToString($date_format)
        # now loop against aux dates for comparison
 
        $match = $false
 
        $match_date = @()
        if ($aux_table.Contains($h)) {
            $aux_dates = $aux_table[$h]
            foreach ($a in $aux_dates) {
 
                $elapsed = ($date - $a).Days
                #Mark as true if the days differnce is between 0 and 14
                if ($elapsed -ge 0 -and $elapsed -le 14) {
                    $match = $true
                    $match_date += $a.ToString($date_format)
                }
            }
        }
 
        if ($match) {
            $output_buffer += "$h,$date_string,matched:$match_date"
        }
        else {
            $output_buffer += "$h,$date_string"
        }
    }
}
 
$curr_time = get-date -Format "MM_dd_yyyy_HH_mm_ss"
 
$output_buffer | out-file "result_$curr_time.csv"
 