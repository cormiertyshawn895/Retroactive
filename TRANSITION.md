## Transition from Aperture, iPhoto, iTunes, and Final Cut Pro 7 to supported apps

Because [Rosetta 2 will be removed from macOS 28](https://support.apple.com/102527), macOS Golden Gate is likely¹ the final version of macOS to support running Aperture, iPhoto, and iTunes through Retroactive.

After upgrading to macOS 28, you need to transition from Aperture, iPhoto, and iTunes to a wide range of supported apps, many of which are built into macOS or free to download.

#### iTunes

- Switch to [Music](https://support.apple.com/guide/music/welcome/mac), [TV](https://support.apple.com/guide/tvapp-mac/welcome/mac), [Podcasts](https://support.apple.com/guide/podcasts/welcome/mac), [Books](https://support.apple.com/guide/books/welcome/mac), and [Finder](https://support.apple.com/102471).
- Install Windows with [Parallels Desktop](https://www.parallels.com/products/desktop) or [VMware Fusion](https://www.vmware.com/products/fusion.html), then download [iTunes for Windows](https://apps.microsoft.com/detail/9PB2MZ1ZMB1S).
- To archive iPhone and iPad apps, use [Asspp](https://github.com/Lakr233/Asspp), [IPATool](https://github.com/majd/ipatool), [iMazing](https://imazing.com), [Apple Configurator](https://apps.apple.com/app/id1037126344) [(tutorial)](https://raw.githubusercontent.com/cormiertyshawn895/Retroactive/master/Retroactive/Support/ConfiguratorTutorial.mp4), or [iTunes 12.6.5.3 for Windows](https://secure-appldnld.apple.com/itunes12/091-87819-20180912-69177170-B085-11E8-B6AB-C1D03409AD2A6/iTunes64Setup.exe).

#### Aperture and iPhoto
- Switch to [Photos](https://support.apple.com/guide/photos/welcome/mac), [Darktable](https://www.darktable.org), or [RawTherapee](https://www.rawtherapee.com).
- Purchase or subscribe to [AfterShot Pro](https://www.aftershotpro.com), [Capture One Pro](https://www.captureone.com), [Darkroom](https://apps.apple.com/app/id953286746), [DxO PhotoLab](https://www.dxo.com/dxo-photolab), [Lightroom](https://apps.apple.com/app/id1451544217), [Lightroom Classic](https://www.adobe.com/products/photoshop-lightroom-classic.html), [Luminar Neo](https://apps.apple.com/app/id1584373150), or [Photomator](https://apps.apple.com/app/id1444636541).

#### Final Cut Pro 7
- Export your projects into XML on a compatible Mac. Then import them into [DaVinci Resolve](https://apps.apple.com/app/id571213070), [Media Composer](https://www.avid.com/media-composer), or [Premiere Pro](https://www.adobe.com/products/premiere.html). You can also use [SendToX](https://apps.apple.com/app/id496926258) to import them into the latest version of [Final Cut Pro](https://apps.apple.com/app/id424389933).

¹ It may theoretically be possible to modify Aperture, iPhoto, and iTunes in a way that makes macOS 28 treat them as older, unmaintained games, which will continue to run under a subset of Rosetta functionality.

Because Aperture, iPhoto, and iTunes likely depend on frameworks beyond this remaining subset, Aperture, iPhoto, and iTunes may need to be augmented with x86_64 frameworks extracted from the dyld shared cache from macOS Golden Gate using [dsce](https://github.com/moraea/dsce).
