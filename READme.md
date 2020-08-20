## Windows Dynamic Wallpaper
### Description :
Allow windows to use wallpapers from https://www.dynamicwallpaper.club/ 

### Prereqs
- powershell >5
- At least 1 folder containing image files named like "\*- Night\*", "\*- Day\*", "\*- Sunrise\*","\*- Sunset\*"

	- Example 1: 
    	```
		Island - Day.png
		Island - Night.png  
		Island - Sunrise.png  
		Island - Sunset.png  
        ```
	- Example 2:
    	```
        Index - Day 01.png  
		Index - Day 02.png  
		Index - Day 03.png  
		Index - Day 04.png  
		Index - Day 05.png  
		Index - Day 06.png  
		Index - Day 07.png  
		Index - Day 08.png  
		Index - Day 09.png  
		Index - Day 10.png  
		Index - Night 01.png  
		Index - Night 02.png  
		Index - Night 03.png  
		Index - Night 04.png  
		Index - Night 05.png  
		Index - Night 06.png  
		Index - Night 07.png  
		Index - Night 08.png  
		Index - Night 09.png  
		Index - Night 10.png  
		Index - Sunrise 01.png  
		Index - Sunrise 02.png  
		Index - Sunrise 03.png  
		Index - Sunrise 04.png  
		Index - Sunrise 05.png  
		Index - Sunset 01.png  
		Index - Sunset 02.png  
		Index - Sunset 03.png  
		Index - Sunset 04.png  
		Index - Sunset 05.png  
		```
#### Optional Prereqs
- imageMagick(used to extract HEIC to PNG)
- Bulk rename utility (helpful tool for renaming the extracted files)
	

### First Use
Run the script in a admin powershell window with the -initialize flag
Then enter requested info. (Paths should be full paths to the folder c:\temp\dynamic\island)

To create your own Dynamic Wallpaper  
	1. Download a file from https://www.dynamicwallpaper.club/  
	2. Place it in a new folder   
	3. Run 	`Path\to\imagemagick\magick.exe convert '.\*.heic' DESIREDNAME.png` in your  new folder 
