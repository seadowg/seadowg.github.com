---
layout: post
title:  "Avoiding Android's Edge to Edge enforcement"
description: "Rebellion through staying within the lines"
---

The Android team has spent the last few years pushing developers to use what "edge to edge" layouts: essentially have apps layout underneath the system bars rather than between them. This admittedly looks really nice in Google Maps, but causes a few issues:

1. Developers need to ensure that content starts and ends correctly in relation to the system bars
2. Floating views (like FABs) need to have their position corrected for the system bars
3. Scrolled edge to edge content will display under the status and navigation bars which increases visual noise and results in some visible clickable items becoming unclickable

Despite these problems, Android releases have been making it harder and harder to get away with just rendering your app in between the system bars: Android 15 made edge to edge the default display mode for Activities and [the new Android 16 Beta](https://android-developers.googleblog.com/2025/03/the-third-beta-of-android-16.html) is removing the opt out flag that Android 15 introduced. The actual "why" of this change remains a mystery as far as I can tell. [Docs](https://developer.android.com/design/ui/mobile/guides/layout-and-content/edge-to-edge) [fail](https://developer.android.com/develop/ui/views/layout/edge-to-edge) to mention any tangible benefits for users other than hand waving with words like "experience" and "immersive" and discussion in Google's issue track [has been shut down] by claims that edge to edge is "preferable". I did manage one [mention of a "user study"](https://medium.com/androiddevelopers/insets-handling-tips-for-android-15s-edge-to-edge-enforcement-872774e8839b) that claims users "prefer edge-to-edge over non edge-to-edge screens". This would make sense for a single screen or app, but enforcing a visual style on millions of apps (probably resulting in tens of millions of hours of work) based on this seems frankly ridiculous. If there is some grand plan that actually justifies edge to edge enforcement, I'd love to hear about it!

I wanted to see if I could use the tooling provided by Google's Android SDK to deal with the above problems 1, 2 and 3 to completely avoid them. Specifically, when dealing with problem 2 (a floating view like a FAB), we'd do something like this:

```kotlin
ViewCompat.setOnApplyWindowInsetsListener(fab) { v, windowInsets ->
  val insets = windowInsets.getInsets(WindowInsetsCompat.Type.systemBars())

  v.updateLayoutParams<MarginLayoutParams> {
      leftMargin = insets.left
      bottomMargin = insets.bottom
      rightMargin = insets.right
  }

  WindowInsetsCompat.CONSUMED
}
```

So can we just apply this same trick to the content of an Activity as a whole and get our system bars back? Let's try! Here's [Collect's](https://github.com/getodk/collect) main menu running in Android 15 without the edge to edge opt-out flag:

<img src="/assets/img/collect-edge-to-edge.png" style="max-height: 800px; width: auto; margin-left: auto; margin-right: auto; display: block; margin-top: 1.5em; margin-bottom: 2em;"/>

Great! I'm sure users are super glad I have to fix this to make it look exactly how it did before. Let's try using `setOnApplyWindowInsetsListener` to get the whole Activity sitting inside the system bars again by applying the insets as margins to the content view:

```kotlin
ViewCompat.setOnApplyWindowInsetsListener(window.decorView.findViewById(android.R.id.content)) { v, windowInsets ->
    val insets = windowInsets.getInsets(WindowInsetsCompat.Type.systemBars())
    v.updateLayoutParams<ViewGroup.MarginLayoutParams> {
        topMargin = insets.top
        bottomMargin = insets.bottom
    }

    WindowInsetsCompat.CONSUMED
}
```

...which looks like this:

<img src="/assets/img/collect-edge-to-edge-avoid.png" style="max-height: 800px; width: auto; margin-left: auto; margin-right: auto; display: block; margin-top: 1.5em; margin-bottom: 2em;"/>

Boom! We did it. Here's that code as an extension function:

```kotlin
object EdgeToEdge {

    @JvmStatic
    fun Activity.avoidEdgeToEdge() {
        ViewCompat.setOnApplyWindowInsetsListener(window.decorView.findViewById(android.R.id.content)) { v, windowInsets ->
            val insets = windowInsets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.updateLayoutParams<ViewGroup.MarginLayoutParams> {
                topMargin = insets.top
                bottomMargin = insets.bottom

                leftMargin = insets.left
                rightMargin = insets.right
            }

            WindowInsetsCompat.CONSUMED
        }
    }
}
```

To get that working you can just add `avoidEdgeToEdge()` (or `avoidEdgeToEdge(this)`) to the bottom of the `Activity#onCreate` overrides in your app and you'll not have to deal with any of this!
