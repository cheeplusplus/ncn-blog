---
title: New Blog Site
tags: emulation,hardware,hacking
date: April 8, 2020
---

So Animal Crossing came out recently for the Switch and I wanted to see if I could use my [Proxmark](https://proxmark.com/proxmark-3-hardware/proxmark-3-rdv4) to spoof amiibo tags.

A couple years ago, [@jamchamb_](https://twitter.com/jamchamb_) did a presentation on [reverse engineering the amiibo](https://jamchamb.github.io/assets/pdf/amiibo-presentation-HOPE.pdf), which led to a lot of the groundwork of dumping amiibo that made it easy for me to get it working on the Proxmark with the Switch. Their work was originally on the 3DS, but I think the Switch handles them in much the same way.

In the talk, they mention how the Switch's joycon NFC has a small antenna, and it does become extremely difficult to read from the Proxmark's card-shape antenna, but thankfully the NFC pad on the Pro Controller is much larger and somewhat easier to place and pick up. Unfortunately it's still difficult to get a good read and requires a few tries, I suspect due to the timing involved on the Proxmark's end.

To start, I obtained some of the amiibo dump bins from a friend. Writing these to a real reprogrammable tag is easy, just requiring Android software to re-encrypt the data to the new tag's (fixed) UID using keys that were pulled with James' work. I, however, had a Proxmark and no NTAG215 tags, which unsurprisingly all seem to be sold out. Weird!

Unlike a real tag, though, the Proxmark has no burned UID or security signature, all things that would cause the Switch to see the tag as invalid and reject it. But, the dumps thankfully include the original UID and signature, which means if we replay the card data exactly as structured on the amiibo, the Proxmark can pretend and the Switch won't know any different. Plus, we have the benefit of not needing any legally questionable encryption keys, just questionably obtained yet still encrypted amiibo data dumps.

Proxmark is a strange beast, where the files you get from dumping an NFC tag and the ones you use to simulate are different. Thankfully, as a fruit from the earlier reverse engineering, [a tool already exists](https://github.com/RfidResearchGroup/proxmark3/blob/master/tools/pm3_amii_bin2eml.pl) to convert the provided `bin` files to the `eml` format required for a Proxmark to replay. From there, it was a lot of digging to find out exactly the right set of commands to use. I came across [an article on how to emulate amiibo on the Proxmark](https://tomvanveen.eu/emulating-amiibos-with-a-proxmark-3/) from a while back during my search. It seemed perfect, and references the original version of the tool just linked, but unfortunately after some more digging (and failures) found out that the Proxmark's software has changed too much over the past couple years and was unable to replay in the way the Switch was expecting.

<img src="assets/2020-04-08-amiibo-emulation/not-an-amiibo.jpg" class="img-fluid">
<small>Harv's Island is a great testing ground! I saw a lot of this message.</small>

Figuring out why took some investigation. Thankfully, Proxmark includes the ability to both intercept a real NFC transaction as well as log out what occured during a simulation. Using this I was able to spy on what my Switch was doing talking to one of my real Animal Crossing amiibos (Blathers!) and compare it to what was happening during a replay. The Switch was immediately dropping the simulated tag off after trying to give it the write-allowed password, and the sim responded with a NAK (Not AcKnowledged) instead of the PACK (Password ACKnowledged) that was expected. I already knew from reading that the PACK of amiibo is hardcoded to `0x8080`, which made it stranger after digging in that both the Proxmark software claimed that the simulator mode I was using used PACK `0x8080` and that the simulator data contained the PACK independently, which meant it was dumped correctly too.

<img src="assets/2020-04-08-amiibo-emulation/sim-vs-reality.png" class="img-fluid">

After a bit of flailing, it was finally time to give in and break open Proxmark's source. I spent time at first trying to find what changed between when the article was published and the more recent versions that other people in the amiibo emulation. It took some digging, mostly into how the simulator responses specifically to the password event - it seemed like it was implemented fine! It checked if the password the reader (the Switch) was sending matched the password stored in the dump. Then I realized that the tool I was using to convert to the emulation format had helpfully been telling me that the dump's password was `00000000`. That doesn't seem right.

<img src="assets/2020-04-08-amiibo-emulation/converter-result.png" class="img-fluid">

It's not, of course! I knew from my real dump and the talk that amiibo had passwords based on their UID. The dump was missing the password because it was intended to be used with a new tag, which would have had a different password since any other (real, even reprogrammable) tag would have had a different UID burned in at the factory. Proxmark also has code specifically to reverse the password from the UID for amiibo, since it's now a known method. Unfortunately, even if I were to inject the password into the dump, the second problem raises its head - the Proxmark implentation of PACK is over-specific, responding with the first two bytes part of the password instead of the `0x8080` the Switch wants. This is a problem because (other than being obviously required) the NTAG21x specification says that the PACK value can be optionally set with write permission, depending on the tag. So Proxmark will only read some tags, but not all of them.

The reason this wasn't an issue before, remember the dump *has* the PACK value inside of it, is because while Proxmark's old dump format supported it, the factor that changed in the past two years is that they changed to a new internal format, and included an internal converter, which drops the PACK value from the old structure. Now it's not available and is implemented with the method that doesn't work.

So what's the solution? Modify the firmware so it doesn't care what the password is, and always sends back `0x8080` in response! Since we know we're simulating a card, we don't need to worry about an attacker hitting our simulated card. I also noticed some other things, like how despite it being embedded in the dump, and the data supposedly being passed through correctly, the simulator would never respond with the correct 'version' (identifiying itself as an NTAG215), so I hardcoded that in as well just to be safe.

<img src="assets/2020-04-08-amiibo-emulation/changed-source.png" class="img-fluid">

After that, it started working! 

<iframe width="560" height="315" src="https://www.youtube.com/embed/95Bm9G57vJo" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

It's still very finnicky, I think it's a mix of the NFC pad on the Pro Controller, and Proxmark's simulator. Sometimes it works immediately, sometimes I have to stop and start the entire thing a couple times just to get anything to read. I know the Proxmark is acting up sometimes because my phone will refuse to read it, too.

If you're interested, I published my patch to [a branch in my own Proxmark fork](https://github.com/cheeplusplus/proxmark3). I may help contribute upstream but given that I just hardcoded to get this to work I don't want to rush into a pull request.

There's not much to it. After building Proxmark and flashing the image, start by converting an amiibo dump into the emulation format:

```
perl tools/pm3_amii_bin2eml.pl whatever_amiibo.bin > amiibo.eml
```

then start Proxmark, load the eml file, and start the simulator.

```
hf mfu eload u amiibo 257
hf mfu sim t 7
```

Now if you'll excuse me, I'm going to go fill my campsite with villagers I actually want.
