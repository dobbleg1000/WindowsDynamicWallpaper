 param (
    [switch]$initialize = $false,
    [switch]$reregister = $false
 )


Function Get-DateNoSeconds{
    $date = Get-Date
    return ($date).Date.AddHours($date.Hour).AddMinutes($date.Minute)

}

Function Get-LocalDaylight {
    <#
        .SYNOPSIS
            Returns the current sunrise and sunset times for the local user in localtime.

        .EXAMPLE
            Get-LocalDaylight

            Result
            -----------
            Sunrise : 06/08/2019 06:04:57
            Sunset : 06/08/2019 20:22:17
            
    #>      
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory)]
        [Int]
        $Zipcode
    )

    $Coordinates = (Invoke-RestMethod -Uri "https://public.opendatasoft.com/api/records/1.0/search/?dataset=us-zip-code-latitude-and-longitude&q=$Zipcode&facet=state&facet=timezone&facet=dst").records[0].fields[0]


    # Return sunrise/sunset
    $Daylight = (Invoke-RestMethod "https://api.sunrise-sunset.org/json?lat=$($Coordinates.latitude)&lng=$($Coordinates.longitude)&formatted=0&date=today").results
    $Daylight2 = (Invoke-RestMethod "https://api.sunrise-sunset.org/json?lat=$($Coordinates.latitude)&lng=$($Coordinates.longitude)&formatted=0&date=$((Get-Date).adddays(1).ToString("yyyy-MM-dd"))").results
    # Convert to local time datetime objects
    $sunrise = ($Daylight.Sunrise | Get-Date).ToLocalTime()
    $sunset = ($Daylight.Sunset | Get-Date).ToLocalTime()
    $sunrise2 = ($Daylight2.Sunrise | Get-Date).ToLocalTime()
    #strip seconds
    $sunrise = (Get-Date).Date.AddHours($Sunrise.Hour).addMinutes($Sunrise.Minute)
    $sunset = (Get-Date).Date.AddHours($sunset.Hour).addMinutes($sunset.Minute)
    $sunrise2 = (Get-Date).Date.AddHours($sunrise2.Hour).addMinutes($sunrise2.Minute).AddDays(1)
    
     return  ($sunrise,$sunset,$sunrise2)
    }

Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Text;
using System.Drawing;
using System.Windows.Forms;
using System.Runtime.InteropServices;
using System.Linq;
using Microsoft.Win32;

namespace WinAPI {
  class DesktopWallpaper
  {
    [StructLayout(LayoutKind.Sequential)]
    public struct Rect
    {
      public int Left;
      public int Top;
      public int Right;
      public int Bottom;
    }

    public enum DesktopSlideshowOptions
    {
      ShuffleImages = 0x01
    }

    public enum DesktopSlideshowState
    {
      Enabled = 0x01,
      Slideshow = 0x02,
      DisabledByRemoteSession = 0x04
    }

    public enum DesktopSlideshowDirection
    {
      Forward = 0,
      Backward = 1
    }

    public enum DesktopWallpaperPosition
    {
      Center = 0,
      Tile = 1,
      Stretch = 2,
      Fit = 3,
      Fill = 4,
      Span = 5
    }

    [ComImport, Guid("B92B56A9-8B55-4E14-9A89-0199BBB6F93B"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IDesktopWallpaper
    {
      void SetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID, [MarshalAs(UnmanagedType.LPWStr)] string wallpaper);

      [return: MarshalAs(UnmanagedType.LPWStr)]
      string GetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID);

      [return: MarshalAs(UnmanagedType.LPWStr)]
      string GetMonitorDevicePathAt(uint monitorIndex);

      [return: MarshalAs(UnmanagedType.U4)]
      uint GetMonitorDevicePathCount();

      [return: MarshalAs(UnmanagedType.Struct)]
      Rect GetMonitorRECT([MarshalAs(UnmanagedType.LPWStr)] string monitorID);

      void SetBackgroundColor([MarshalAs(UnmanagedType.U4)] uint color);

      [return: MarshalAs(UnmanagedType.U4)]
      uint GetBackgroundColor();

      void SetPosition([MarshalAs(UnmanagedType.I4)] DesktopWallpaperPosition position);

      [return: MarshalAs(UnmanagedType.I4)]
      DesktopWallpaperPosition GetPosition();

      void SetSlideshow(IntPtr items);

      IntPtr GetSlideshow();

      void SetSlideshowOptions(DesktopSlideshowDirection options, uint slideshowTick);
      [PreserveSig]

      uint GetSlideshowOptions(out DesktopSlideshowDirection options, out uint slideshowTick);

      void AdvanceSlideshow([MarshalAs(UnmanagedType.LPWStr)] string monitorID, [MarshalAs(UnmanagedType.I4)] DesktopSlideshowDirection direction);

      DesktopSlideshowDirection GetStatus();

      bool Enable();
    }

    public class WallpaperWrapper
    {
      static readonly Guid CLSID_DesktopWallpaper = new Guid("{C2CF3110-460E-4fc1-B9D0-8A1C0C9CC4BD}");

      public static IDesktopWallpaper GetWallpaper()
      {
        Type typeDesktopWallpaper = Type.GetTypeFromCLSID(CLSID_DesktopWallpaper);
        return (IDesktopWallpaper)Activator.CreateInstance(typeDesktopWallpaper);
      }
    }
  }

  public class Wallpaper
  {
    public static void Main()
    {
        
    }

    public static void SetWallpaper(uint id, string path)
    {
      DesktopWallpaper.IDesktopWallpaper wallpaper = DesktopWallpaper.WallpaperWrapper.GetWallpaper();

      if (id <= wallpaper.GetMonitorDevicePathCount()) {
        string monitor = wallpaper.GetMonitorDevicePathAt(id);
        wallpaper.SetWallpaper(monitor, path);
        wallpaper.SetPosition(DesktopWallpaper.DesktopWallpaperPosition.Fill);
      }

      Marshal.ReleaseComObject(wallpaper);
    }
  }
}
"@ -ReferencedAssemblies 'System.Drawing.dll', System.Windows.Forms

Class DynamicWallpaper

{

    [String]$Id
    [Object[]]$pictures
    [Object[]]$DayPics
    [Object[]]$NightPics
    [Object[]]$SunrisePics
    [Object[]]$SunsetPics
    DynamicWallpaper ($folder)
    {
      $this.id = $folder
      $this.DayPics = Get-ChildItem -Path $folder -Filter "*- Day*" | Sort-Object -Property Name
      $this.NightPics = Get-ChildItem -Path $folder -Filter "*- Night*" | Sort-Object -Property Name
      $this.SunrisePics = Get-ChildItem -Path $folder -Filter "*- Sunrise*" | Sort-Object -Property Name
      $this.SunsetPics = Get-ChildItem -Path $folder -Filter "*- Sunset*" | Sort-Object -Property Name
      $this.pictures= $this.SunrisePics + $this.DayPics + $this.SunsetPics + $this.NightPics
    }

}


if($initialize){
	Get-ScheduledJob | where {$_.name -like "WindowsDynamicWallpaper"} | Unregister-ScheduledJob -Force
    $Zipcode = Read-Host("What is your Zipcode")
    $screenCount = [int](Read-Host("How many screens?"))
    $WallpaperPaths = @()
    foreach($i in (1..($screenCount))){
        
        $WallpaperPaths+=Read-Host "Path to Wallpapers for Screen $i"
    }
    ($sunrise,$sunset,$sunriseTomorrow) = Get-LocalDaylight -Zipcode $Zipcode
    
    [pscustomobject]@{
        Sunrise = "$sunrise"
        SunriseTomorrow = "$sunriseTomorrow"
        Sunset = "$sunset"
        zipcode = "$zipcode"
        WallpaperPaths = $WallpaperPaths 

    } | ConvertTo-Json | Out-File $PSScriptRoot\config.json
    $O = New-ScheduledJobOption -MultipleInstancePolicy IgnoreNew -StartIfOnBattery -ContinueIfGoingOnBattery -RunElevated
    $t =  New-JobTrigger -Once -At "$((Get-DateNoSeconds).addMinutes(1))" -RepetitionInterval (New-TimeSpan -Minutes 1) -RepeatIndefinitely

    
    $script =  [scriptblock]::Create("powershell.exe -f '$PSScriptRoot\WindowsDynamicWallpaper.ps1'")

    Register-ScheduledJob -ScriptBlock $script -Name WindowsDynamicWallpaper -ScheduledJobOption $O -Trigger $T

    return
}
#recreate the job if you changed the ps1
if($reregister){
    Get-ScheduledJob | where {$_.name -like "WindowsDynamicWallpaper"} | Unregister-ScheduledJob -Force
    $O = New-ScheduledJobOption -MultipleInstancePolicy IgnoreNew -StartIfOnBattery -ContinueIfGoingOnBattery -RunElevated
    $t =  New-JobTrigger -Once -At "$((Get-DateNoSeconds).addMinutes(1))" -RepetitionInterval (New-TimeSpan -Minutes 1) -RepeatIndefinitely

    $script =  [scriptblock]::Create("powershell.exe -f '$PSScriptRoot\WindowsDynamicWallpaper.ps1'")

    Register-ScheduledJob -ScriptBlock $script -Name WindowsDynamicWallpaper -ScheduledJobOption $O -Trigger $T

    return
}
if(!(Test-Path $PSScriptRoot\config.json)){

    "Please Rerun script as admin with the -initialize flag"


}
#Get-Job -Name WindowsDynamicWallpaper | where{$_.State -like "Completed"}  | Receive-Job | Out-File -FilePath $PSScriptRoot\PreviousRun.log -Force 
Get-Job -Name WindowsDynamicWallpaper | where{$_.State -like "Completed"}   | Remove-Job

$time = Get-DateNoSeconds

$config = Get-Content $PSScriptRoot\config.json | ConvertFrom-Json






$Sunrise = get-date($config.Sunrise)
$Sunset = get-date($config.Sunset)
$sunriseTomorrow = get-date($config.SunriseTomorrow)



$SunriseStart = $Sunrise.AddHours(-1)
$SunriseEnd = $Sunrise.AddHours(2)
$SunsetStart = $Sunset.AddHours(-2)
$SunsetEnd = $Sunset.AddHours(1)

#update Daylight at the start of sunrise the next day
if($time -ge ($sunriseTomorrow.AddHours(-1))){
    
    ($sunrise,$sunset,$sunriseTomorrow) = Get-LocalDaylight -Zipcode $config.Zipcode
    $SunriseStart = $Sunrise.AddHours(-1)
    $SunriseEnd = $Sunrise.AddHours(2)
    $SunsetStart = $Sunset.AddHours(-2)
    $SunsetEnd = $Sunset.AddHours(1)
    [pscustomobject]@{
        Sunrise = "$sunrise"
        Sunset = "$sunset"
        SunriseTomorrow = "$sunriseTomorrow"
        zipcode = "$($config.zipcode)"
        WallpaperPaths = $($config.WallpaperPaths) 

    } | ConvertTo-Json | Out-File $PSScriptRoot\config.json

}


$state = "Day"


if($time -ge $SunriseStart -and $time -lt $SunriseEnd){

    $state = "Sunrise"

} elseif ($time -ge $SunriseEnd -and $time -lt $SunsetStart){

    $state = "Day"

} elseif ($time -ge $SunsetStart -and $time -lt $SunsetEnd){

    $state = "Sunset"

} else{

    $state = "Night"

}


$time
$state

foreach($i in (0..($config.WallpaperPaths.count-1))){
$wall = [DynamicWallpaper]::new($config.WallpaperPaths[$i])

switch($state){
   "Sunrise" {
     $max = $SunriseEnd - $SunriseStart
     $indexTime = $time - $SunriseStart
     $index = [Math]::Floor((($indexTime.TotalMinutes)*($wall.SunrisePics.Count))/($max.TotalMinutes))   
     [WinAPI.Wallpaper]::SetWallpaper($i,$wall.SunrisePics[$index].FullName)   
   }
   "Day" {
     $max = $SunsetStart - $SunriseEnd
     $indexTime = $time - $SunriseEnd
     $index = [Math]::Floor((($indexTime.TotalMinutes)*($wall.DayPics.Count))/($max.TotalMinutes))   
     [WinAPI.Wallpaper]::SetWallpaper($i,$wall.DayPics[$index].FullName)
   }
   "Sunset" {
     $max = $SunsetEnd - $SunsetStart
     $indexTime = $time - $SunsetStart
     $index = [Math]::Floor((($indexTime.TotalMinutes)*($wall.SunsetPics.Count))/($max.TotalMinutes))   
     [WinAPI.Wallpaper]::SetWallpaper($i,$wall.SunsetPics[$index].FullName)
   
   }
   "Night" {
    $sunriseTomorrow = $sunriseTomorrow.AddHours(-1)
    $max = $sunriseTomorrow - $SunsetEnd
    $indexTime = $time - $SunsetEnd
    $index = [Math]::Floor((($indexTime.TotalMinutes)*($wall.NightPics.Count))/($max.TotalMinutes))
    [WinAPI.Wallpaper]::SetWallpaper($i,$wall.NightPics[$index].FullName)
   }
}
}
