<p align="center">
  <a href="https://github.com/cormiertyshawn895/Retroactive/releases/download/2.0/Retroactive.2.0.zip" alt="Download Retroactive"><img width="188" height="188" src="screenshots/icon.png" alt="Download Retroactive"></a>
</p>

## Retroactive

Run Aperture, iPhoto, and iTunes on macOS Ventura, macOS Monterey, macOS Big Sur, and macOS Catalina. Xcode 11.7 on macOS Mojave. Final Cut Pro 7, Logic Pro 9, and iWork ’09 on macOS Mojave or macOS High Sierra.

<p align="center">
  <a href="https://github.com/cormiertyshawn895/Retroactive/releases/download/2.0/Retroactive.2.0.zip" alt="Download Retroactive"><img width="282" height="68" src="screenshots/resources/download-button.png" alt="Download Retroactive"></a>
<p>
<p align="center">
  <a href="https://github.com/cormiertyshawn895/Retroactive/releases" alt="View Release Page"><img width="160" height="18" src="screenshots/resources/release-button.png" alt="View Release Page"></a>
</p>

---

### Opening Retroactive

After downloading Retroactive, double click to open it. macOS may prompt you “Retroactive cannot be opened because it is from an unidentified developer.” This is completely normal and expected.

![](screenshots/2.jpg)

To open Retroactive, [right-click](https://support.apple.com/HT207700) on the Retroactive app in Finder, and click “Open” as shown below.

![](screenshots/3.jpg)

If you right-clicked when opening Retroactive for the first time, you need to [right-click](https://support.apple.com/HT207700) for a second time. If Retroactive still can’t be opened, [check your GateKeeper settings](https://support.apple.com/en-us/HT202491) under the General tab in System Preferences > Security & Privacy. Click “Open Anyway” to open Retroactive.

Retroactive will not harm your Mac. This alert only shows up because Retroactive is not notarized. Retroactive is open source, so you can always examine its source code to make sure it’s safe.

---

### Picking an app

On macOS Ventura, macOS Monterey, macOS Big Sur, and macOS Catalina, Retroactive can unlock Aperture and iPhoto, or install iTunes. Pick the app you want to run. If you want to run multiple apps from here, pick any one of them. You will always be able to get back to this screen later.

![](screenshots/4.jpg)

On macOS Mojave and macOS High Sierra, Retroactive can also unlock Final Cut Pro 7, Logic Pro 9 (experimental), Xcode 11.7 (requires macOS Mojave), and fix iWork ’09.

![](screenshots/4b.jpg)

I’ll use Aperture as the example, but the same process also works for iPhoto, iTunes, Final Cut Pro 7, Logic Pro 9, Xcode 11.7, and iWork ’09.

---

### Locating the app or choosing a version

Retroactive will automatically scan your Mac to locate an existing Aperture, iPhoto, Final Cut Pro 7, Logic Pro 9, Xcode 11.7, or iWork ’09 install. If Retroactive has already located the app you would like to run, skip to the next section.

If Retroactive can’t locate an existing install, you’ll either be asked to download it from the Purchased list in App Store, or re-install it from a DVD disc. You can also find the app on another Mac you own, then AirDrop it to this Mac, or restore the app from a Time Machine backup.

![](screenshots/5.jpg)

If you chose iTunes, Retroactive will ask you which version to install, then automatically download and install it for you.

- iTunes 12.9.5 supports Dark Mode and most DJ apps.
- iTunes 12.6.5 supports Ringtones and iTunes U.
- iTunes 11.4 has a classic look.
- iTunes 10.7 supports CoverFlow.

If you don’t know which version to install, keep the default setting and click “Continue”.

---

### Authenticating Retroactive

To install or modify the app you chose, you need to authenticate with your login password first. Click “Authenticate”, and enter your login password.

![](screenshots/6.jpg)

Your password is never stored or sent anywhere. To verify this, you can view Retroactive’s source code.

---

### Modifying the app

Retroactive will install or modify the app you chose. Modifying the app should only take about 2 minutes.

![](screenshots/7.jpg)

If you chose to install iTunes, this process may longer. 

- Depending on the version you chose, it can take between 10 minutes to an hour.
- It is completely normal for the fans to spin up during the process.
- If Retroactive asks for your login password again, re-enter it again.
- If iTunes 12.9.5 can’t be installed, try to install iTunes 12.6.5.

![](screenshots/7a.jpg)

After installing iTunes, Retroactive will ask you about iPod syncing. If you need to sync with iPod devices, click "Enable Full Disk Access", and follow on-screen instructions provided by Retroactive.

![](screenshots/8.jpg)

That's it! You can use the app now.

---

### Using the app

After successfully modifying or installing the app, you can play with it to your heart's content.

![](screenshots/9.jpg)

- All Aperture features should be available except for playing videos, exporting slideshows, Photo Stream, and iCloud Photo Sharing. If RAW photos can't be opened, [you need to reprocess them](https://github.com/cormiertyshawn895/Retroactive#reprocessing-raw-photos-in-aperture).

- All iPhoto features should be available except for playing videos, exporting slideshows, Photo Stream, and iCloud Photo Sharing.

- All features should work for iTunes 12.9.5.

- Most features should work for iTunes 12.6.5. Use iTunes 12.9.5 or Finder to back up your device instead. Use [Apple Configurator 2](https://apps.apple.com/app/apple-configurator-2/id1037126344) to [download iOS apps on your Mac](https://www.youtube.com/watch?v=M_3t06FEhR0).

- Movies and TV Shows downloaded from the iTunes Store may be unable to play in iTunes. Download or play them in the TV app instead. 

- Some dialogs in iTunes may display a crossed-out iTunes icon. This is purely cosmetic and has no functional impact.

- All Final Cut Pro 7 features should work.

- Support for Logic Pro 9 is experimental. You may see frequent freezes and hangs.

- Most Xcode 11.7 features should work.

- After fixing iWork ’09, text format and paragraph alignment controls in the format bar should appear correctly. Scroll bars will no longer appear behind the document canvas.

- After fixing Keynote ’09 with Retroactive, you can normally play slideshows.

- After fixing Pages ’09 with Retroactive, typing and scrolling in Pages ’09 should be more responsive.

---

### Syncing with a device

If you connect an Apple device to your Mac, and either see nothing in iTunes, or "The device is in use by another user on this computer":

- Disconnect the device from your Mac, but keep iTunes open.
- Click on the Spotlight icon (magnifying glass) on the menu bar.
- Type "Terminal" and press return to open the Terminal app.
- Enter `killall AMPDevicesAgent` in the Terminal window, and press return.
- Connect the Apple device back to your Mac.

If you connect an Apple device to your Mac, and see "iTunes cannot read the contents of the device. Go to the Summary tab in device preferences and click Restore to restore this device to factory settings":

- You may have installed iTunes with Retroactive 1.4 or earlier.
- Once you reinstall iTunes [using the latest version of Retroactive](https://github.com/cormiertyshawn895/Retroactive/releases/), iTunes should be able to read the contents of your device as expected.
- At the end of the installation process, Retroactive will ask you about iPod syncing. If you need to sync with iPod devices, click "Enable Full Disk Access".

If you try to enable VoiceOver for iPod shuffle, but see "iTunes was unable to install the VoiceOver Kit. An unknown error occurred (1701)":

- [Directly download the VoiceOver 1.4.2 installer here](https://swdist.apple.com/content/downloads/29/37/041-91732-A_LSWLP6NLRV/bk8l36k29x8d146doiwcvuv8qemu3mzxwk/VoiceOver.pkg).
- Install the downloaded VoiceOver.pkg.
- Quit and re-open iTunes.

---

### Downloading iOS Apps

Starting from April 2020, you'll need to use [Apple Configurator 2](https://apps.apple.com/app/apple-configurator-2/id1037126344) to [download iOS apps on your Mac](https://www.youtube.com/watch?v=M_3t06FEhR0).

---

### Final Cut Pro 7 and the Apple Pro Video Formats update

If you install Apple Pro Video Formats update from Software Update, you may need to [follow these instructions](https://github.com/cormiertyshawn895/Retroactive/issues/130#issuecomment-724078303) to re-enable Final Cut Pro 7.

---

### Reprocessing RAW photos in Aperture

- In Aperture, if your RAW photos show up as “*Unsupported Image Format*”, open the “*Photos*” menu, click on “*Reprocess original…*”, and reprocess all photos. After reprocessing your RAW photos, you will be able to preview and adjust them as before.

![](screenshots/reprocess.jpg)

💡 Tip:

- If some RAW photos still show up as "*Unsupported Image Format*" after reprocessing, repeat the process above to reprocess all photos again. In other words, you may need to reprocess all photos twice. 

---

### Workaround to install Final Cut Pro 7 in VMware Fusion

If you don't have a Mac released before Late 2019, you can still install Final Cut Pro 7 in VMware Fusion to export existing Final Cut Pro 7 projects into XML files. This lets SendToX, DaVinci Resolve, Media Composer, and Premiere Pro open them. 

- [Install macOS Mojave virtual machine with VMware Fusion](https://www.huibdijkstra.nl/how-to-set-up-a-osx-mojave-vm-in-vmware-fusion/). Other virtual machine software, such as Parallels Desktop, is not supported and will not work.
- After mounting the Final Cut Studio installer in VMware Fusion, right click on Install Final Cut Studio.pkg > Show Original, then copy FinalCutStudio.mpkg and Packages to VMware Fusion's Desktop
- Right click on the copied FinalCutStudio.mpkg > Show Package Contents > Resources
- Right click on Requirements Checker.app > Show Package Contents > Contents > Resources
- Delete minsys.plist
- Double click on the modified FinalCutStudio.mpkg to start the install
- Use Retroactive as usual

To use editing features such as timeline and preview, install macOS Mojave on a real, older Mac released before Late 2019, then run Retroactive as usual.

---

### Last words
- If GateKeeper prevents you from running modified versions of your chosen app, [temporarily disable GateKeeper in Terminal](http://osxdaily.com/2015/05/04/disable-gatekeeper-command-line-mac-osx/) with `sudo spctl --master-disable`.

- To learn more about how Retroactive works, [take a technical deep dive](https://medium.com/@cormiertyshawn895/deep-dive-how-does-retroactive-work-95fe0e5ea49e).
