# Timelapse Base Edition (TLBE)

[Mod](https://mods.factorio.com/mod/TLBE) for [Factorio](http://www.factorio.com) that takes screenshots of your base at specified intervals.

Features:
* Multiple camera support, each taking their own screenshots.
* Trackers to tell the camera(s) where to look at
    * Follow player until the first entity is built.
    * Follow base growth, keeping focus on specified area/city block or recenter automatically.
    * And finally follow the rocket launch.
* Camera use (ordered) tracker list, first enabled tracker is used.
* Camera gradually (configurable period) recenters and zooms out, which can be recorded in a stop-motion fashion.
* Each camera has customizable resolution, frame rate and speed gain, and show their recording area on the map.
* All screenshots are taken with full daylight or follow day cycle, and optionally show entity information.
* Flexible save options:
    * Configurable screenshot folder (e.g. to support multiple save files that are played in parallel).
    * Include map seed in path (extra measure to prevent overlaps when having multiple save files)
    * Configurable screenshot numbering, either sequential (default, more suitable for Windows ffmpeg) or game tick (easier to synchronize multiple cameras).
    * Configurable image formats (PNG or JPG).
* Optionally start recording on game start to not miss the crash in the timnelapse.

Open the TLBE settings from shortcut bar or CTRL-T (default key binding) to configure your camera(s) and trackers.

Screenshots are stored in the [script-output](https://wiki.factorio.com/Application_directory) folder, with the configured sub-directory ('Save location' setting in the Mod Settings menu).

## Check demo movie on Youtube

[![youtube](https://i.imgur.com/vX9LnBo.jpg)](https://www.youtube.com/watch?v=rJWjhw73ML8)

When you got inspired to make you own timelapse video after watching it, Bigfoot made an exellent video on how to approach making timelapse videos:

[![youtube](https://i.imgur.com/yrpay1E.jpg)](https://www.youtube.com/watch?v=cAcba1zo5mg)