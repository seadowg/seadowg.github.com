---
layout: post
title:  "Android's Restart On Crash Behaviour"
description: ""
tweets:
    - "I've done some digging into #android's crash behaviour and found something weird..."
    - "Android will occasionally (depending on how well-behaved your app is) restart your app's process automatically. This is all well and good, but it will restore the back stack WITHOUT THE ACTIVITY THAT WAS ON TOP."
    - "I'd actually not realized that this restart behaviour existed, let alone that you'd end up sending the user to a different place than where they experienced the crash. Perhaps this was all obvious to other people though?"
    - "Anyway, more details in my post at https://seadowg.com/2022/10/24/crash-test.html. If anyone has links to official docs on this I'd to see them."
---

Usually, when an uncaught `Exception` occurs in an Android app process, the user is shown a dialog by the system informing them that the app has "stopped" or "crashed". If the user hits "Close app" (or just dismisses the dialog) the process is killed.

<img src="/assets/img/crash.png" style="max-height: 480px; width: auto; margin-left: auto; margin-right: auto; display: block; margin-top: 1.5em; margin-bottom: 2em;"/>

Sometimes though, no dialog is shown and the app simply "restarts" when it crashes: the process is killed and then started again (creating a new `Application` object and running its `onCreate`), and the back stack is recreated. This seems to only happen if the app hasn't crashed recently - a reward for good behaviour. What's surprising here is that the back stack is recreated without the Activity that was on top when the crash occurred. This also means that, as far as I've seen, we never end up doing the restart if the crash occurs with only one Activity in the stack which will be the standard state for apps that use a single Activity/multi Fragment architecture (or Compose).

I created [a demo project](https://github.com/seadowg/crash-test){:target="_blank"} to demonstrate/confirm the above behaviour. There are [several](https://stackoverflow.com/questions/5651651/prevent-android-from-recreating-activity-stack-after-crash){:target="_blank"} [Stack Overflow posts](https://stackoverflow.com/questions/5423571/prevent-activity-stack-from-being-restored){:target="_blank"} [that mention this](https://stackoverflow.com/questions/5651651/prevent-android-from-recreating-activity-stack-after-crash){:target="_blank"} restart quirk, but I haven't managed to find any documentation detailing it. I'd have assumed that this behaviour would be identical to the restart that occurs when Android kills your app to reclaim memory and then the user navigates back to it (I'm also unable to find documentation detailing this scenario). In that case however, the back stack is kept as it was before after relaunch (as you'd expect).

You never want to have your users experiences crashes in an app you create, but you'd be naive to believe that that will never happen - accounting for this behaviour is probably wise. For instance, you should avoid having any initialization or navigation code in a "launch" Activity that's doesn't stick around in the back stack (either through `noHistory` or a `finish()` call) - this could result in problems when the back stack is recreated without it. That's also something to consider for the standard app restart case, but it's also worth considering where users might end up in the specific case of a crash restart: hopefully they end up on a "main menu" screen, but this behaviour could land them somewhere strange due to the "head" of the back stack being chopped off and, if you have a single Activity, you'll not receive the blessing (or curse) of the restart. Personally, I'm now thinking that some weird *"how the hell did they get there?"* crash reports that I've seen in my time have an explanation.

If anyone is able to find official documentation on this "restart on crash" behaviour please let me know! I'd be interested to see it explained properly.
