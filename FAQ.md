# Can I use another storage location/hard disk/SSD for the screenshots?

Factorio *always* stores files (and thus screenshots) in the `script-output` folder, located in the game's [user data directory](https://wiki.factorio.com/Application_directory#User_data_directory). This is for security reasons, as it sandboxes the game (and its mods!) into a single safe location.

Using symbolic links is the most convenient way of circumventing this: Create a symbolic link in the `script-output` folder to another folder.

This is working best with Linux/MacOS with a simple `ln -s` command, for Windows it is a bit more work, thanks to @tigar who provided the [required information /steps](https://mods.factorio.com/mod/TLBE/discussion/62f03db2b53847e0072eebef). @Cleverbum mentioned that [Junction Links](https://mods.factorio.com/mod/TLBE/discussion/619db2699268924301f5b755) are *not* working.


# The game lags when making a screenshot

TLBE uses the screenshot API/functionality of Factorio, so there is nothing that can be done by TLBE to fix this.

The longer answer: taking screenshots requires the game to render the area that is part of the screenshot. This of course requires extra resources (CPU/GPU/memory/storage bandwidth), if these resources are near their limit taking the screenshot might go over their maximum, causing (short) pauses: lag!

You can do several things to mitigate them:

1. reduce the resolution/area of the screenshots (less pixels is less workload)
2. take less screenshots/reduce the interval (less screenshots is less lags, but the lags themselves won't be gone)
3. only use one one camera (similar as previous point: less work)
4. update your hardware (more available resources is less lag), especially your storage device as the screenshots tend to be quite big (assuming you opted for high resolution/quality). So a faster storage (SSD or even NVME) will definitely help as the game needs to wait shorter for the bytes to be written)


# Is it possible to run TLBE on servers?

It is possible to run TLBE on a server/headless, but it won't do anything:

> If Factorio is running headless, this function will do nothing.

From https://lua-api.factorio.com/latest/LuaGameScript.html#LuaGameScript.take_screenshot

# The area tracker is not working

Make sure to use the correct order of left/right and top/bottom. The fields become red if the coordinates are swapped:

![GUI with red fields](https://user-images.githubusercontent.com/39400800/137288972-acc039a1-e73d-47a1-9836-8f7d9da892e1.png)


# Is it possible to use TLBE for a replay?

*Short answer:* You cannot add new mods (or any other modification) on a replay. Even if TLBE would have been loaded, you cannot change camera settings (as the game is not able to figure out that this does not influence anything on the game play, has to do with consistency/predictability that is used by Factorio (multi player))

*Longer answer* It might be possible with *a lot* of tinkering. There are people who [modify the `control.lua` of a game](https://www.reddit.com/r/factorio/comments/alwj33/is_it_possible_to_take_daytimeonly_screenshots/) to take screenshot(s) afterwards, one of the devs even has a [gist showing how it could be done](https://gist.github.com/Bilka2/579ec217ec38e055328e4a23f2fd71a3). But it would still be quite a challenge to setup the cameras and other settings using code in the `control.lua` file.

Let me know when you found a/the way! It will be interesting to learn about.

# Getting an error when making a new world

I do not experience errors with the regular mod packs, overhaul mods and popular mods. Which is expected as TLBE does not influence the game, so it should be compatible with any mod.

Nonetheless, a mod might change the game/structure in such a way that TLBE's assumptions of the game are not correct anymore.

I am happy to see if I can change these assumption in such a way that TLBE is able to run with that particular mod. For this, please figure out which mod is causing the TLBE error and report it. This can be done by the process of elimination: remove the mods you have installed one by one until the error is gone. (Or reverse: adding your mods back one by one starting with a vanilla TLBE setup)