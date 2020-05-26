function startSearch(){

    $main = $global:main
    $aux = $global:aux

    if( $main -eq $null -or $aux -eq $null){

    
        [System.Windows.MessageBox]::Show('Please open main and aux file first')

    }

 
    $main_table = [ordered]@{ }
    $aux_table = [ordered]@{ }
    $date_format ="MM/dd/yyyy"
    $output_buffer = @()
 
    #build in memory table for main file
    $global:ProgressBar.Visibility = "Visible"
    $global:ProgressBar.Value = 5
    Update-Gui 
 
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
    $global:ProgressBar.Value = 10
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
    $global:ProgressBar.Value = 10
    Update-Gui 
    $i=0
    foreach ($h in $main_table.Keys) {
        $i = $i + 1
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

        $global:ProgressBar.Value = $global:ProgressBar.Value  + ($i/$main_table.Count)*90

        $integer = [int]$global:ProgressBar.Value
        if($integer % 5 -eq 0){
          Update-Gui 
        }

    }
    $global:ProgressBar.Value = 100
 
    $curr_time = get-date -Format "MM_dd_yyyy_HH_mm_ss"
 
    $output_buffer | out-file "result_$curr_time.csv"

    explorer "result_$curr_time.csv"
 
}


###GUI CODE START ####

 

[xml]$xaml = @"

<Window

    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"

    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"

    x:Name="Window">

    <Border Background="#1f3d7a" BorderThickness="1">

    <Grid x:Name="Grid">
 
            <Grid.RowDefinitions>

                <RowDefinition Height="Auto"/>

                <RowDefinition Height="Auto"/>

                <RowDefinition Height="Auto"/>

            </Grid.RowDefinitions>

            <Grid.ColumnDefinitions>

                <ColumnDefinition Width="1*"/>

                <ColumnDefinition Width="1*"/>

                <ColumnDefinition Width="1*"/>

            </Grid.ColumnDefinitions>

            <StackPanel Margin="10, 10, 5, 5" Grid.Column="1" Grid.Row="1">

                <TextBox x:Name = "AuxFileName"/>
                <Button x:Name = "OpenAux"
                Content="Open Aux File"
                />

            </StackPanel>

            <StackPanel Margin="10, 10, 5, 5" Grid.Column="0" Grid.Row="1">

                <TextBox x:Name = "MainFileName"/>
                <Button x:Name = "OpenMain"
                Content="Open Main File"
                />

            </StackPanel>

            <StackPanel Margin="10, 10, 5, 5" Grid.Column="0" Grid.Row="2">

                <Button x:Name = "Process"
                Content="Process"
                />
                <ProgressBar x:Name = "ProgressBar" Height="20" Minimum="0" Maximum="100" Value="0" />

            </StackPanel>

    </Grid>

    </Border>

</Window>

"@

$global:main = $null
$global:aux = $null


Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

#$SW_HIDE, $SW_SHOW = 0, 5
$TypeDef = '[DllImport("User32.dll")]public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'
Add-Type -MemberDefinition $TypeDef -Namespace Win32 -Name Functions
$hWnd = (Get-Process -Id $PID).MainWindowHandle
$Null = [Win32.Functions]::ShowWindow($hWnd,$SW_HIDE)
$App = [Windows.Application]::new() # or New-Object -TypeName Windows.Application
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window  = [Windows.Markup.XamlReader]::Load($reader)

# Fixes the "freeze" problem
function Update-Gui {
    # Basically WinForms Application.DoEvents()
    $App.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})
}




$OpenAuxBtn = $window.FindName("OpenAux")
$AuxFile = $window.FindName("AuxFileName")

$OpenMainBtn = $window.FindName("OpenMain")
$MainFile = $window.FindName("MainFileName")

$ProcessBtn = $window.FindName("Process")
$global:ProgressBar = $window.FindName("ProgressBar")
$global:ProgressBar.Value = 0
$global:ProgressBar.Visibility = "Visible"

write-host $PSScriptRoot


$OpenAuxBtn.Add_Click({

    $PathName = Convert-Path $PSScriptRoot
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = $PathName 
        Filter = 'CSV (*.csv)|*.csv'
    }
    $null = $FileBrowser.ShowDialog()
    if($FileBrowser.FileName.Length -lt 2)

    {
        return
    }
    
    $PathName = Get-Item -Path $FileBrowser.FileName

    $AuxFile.Text = $PathName
    $global:aux = Get-Content $PathName
    $global:ProgressBar.Value = 0
    #$global:ProgressBar.Visibility = "Hidden"

})


$OpenMainBtn.Add_Click({
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = $PSScriptRoot
        Filter = 'CSV (*.csv)|*.csv'
    }
    $null = $FileBrowser.ShowDialog()
    if($FileBrowser.FileName.Length -lt 2)

    {
        return
    }
    
    $PathName = Get-Item -Path $FileBrowser.FileName

    $MainFile.Text = $PathName
    $global:main = Get-Content $PathName
    $global:ProgressBar.Value = 0
    #$global:ProgressBar.Visibility = "Hidden"
})

$ProcessBtn.Add_Click({
    $global:ProgressBar.Value = 0
    #$global:ProgressBar.Visibility = "Visible"
    startSearch


})


# Finally

$window.ShowDialog()
$App.Run($window)

#$GetAllBatchesBtn = $window.FindName("GetAllBatchesBtn")

#$GetAllBatchesBtn.IsEnabled = $false

 

#$batchUUIDInput = $window.FindName("batchUUIDInput")

 

#$getDispatchBatchBtn = $window.FindName("getDispatchBatchBtn")

#$getDispatchBatchBtn.IsEnabled = $false

 

#$GetAllBatchesBtn.Add_Click({

#    $result = getAllBatches | Out-GridView -PassThru

#    $batchUUIDInput.Text = [String]$result.batchUID
#    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property

#})