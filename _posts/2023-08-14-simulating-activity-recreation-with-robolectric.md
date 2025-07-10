---
layout: post
title:  "Simulating Activity recreation with Robolectric"
description: "Ways to test Android killing your stuff"
edit_date: "10/07/2025"
edit_reason: "References to the \"System recreates Activity\" scenario were mostly removed based on clarification from the Android team that this should not happen."
---

A while ago, I submitted the issue ["No way to test 'System needs resources' situation using ActivityScenario"](https://github.com/android/android-test/issues/1825){:target="_blank"} in which I detailed a few ways to simulate various Activity recreation scenarios in [Robolectric](https://robolectric.org){:target="_blank"} (using `ActivityController`) that weren't possible using AndroidX's `ActivityScenario`. For my own benefit as much as anyone else's, I wanted to go a bit deeper into exploring the different scenarios in which an Activity is recreated in Android, and how to simulate those using Robolectric so that you can test your Activity's behaviour during them. I'm not going to be concerning myself with scenarios where the app is restarted fresh like from a "Force Stop" or a power cycle.

It's worth noting that you can hopefully avoid needing to care about these scenarios by doing good things like avoiding static/application state, adhering to the tenants of unidirectional data flow and never making any mistakes. If you're a mere human however, understanding these scenarios and protecting against bugs that they might cause is probably important. It's also worth noting that, with some noted exceptions, I haven't found a lot of solid documentation on any of this, so feel free to <a href="mailto:callum@seadowg.com">shout at/correct me</a> about anything you read here that is incorrect.

## Activity recreation scenarios

As far as I'm aware, there are 2 distinct Activity recreation scenarios:

1. **Configuration changes**: The Activity is recreated with a new configuration.
2. **System recreates process**: An app process in the background is destroyed by the system to reclaim resources and then recreated when the user returns to it (including the back stack). Alternatively, the app process can be restarted due to [a crash](/2022/10/24/crash-test.html){:target="_blank"} or app permissions changing in system setting.

In this post, I'll attempt to document these scenarios (along with a nasty twist on them) and give examples of how they can be simulated using Robolectric.

A third scenario we can refer to as "System recreated Activity" (without recreating the process) is possible to simulate with the "Don't keep activities" developer setting. This setting destroys every Activity after it is no longer visible (like when another is created on top). This is potentially a useful way to test how robust your Activities are when put through recreation, but it's important to point out that this scenario **should** never happen outside of when the setting is enabled. This was answered pretty definitively in [this Stack Overflow question](https://stackoverflow.com/questions/68778910/when-does-android-destroy-activity-without-destroying-the-entire-process) (with links to answers from the Android team themselves).

### Configuration changes

As far as I've seen, this is the only Activity recreation scenario that's been [well documented](https://developer.android.com/guide/topics/resources/runtime-changes) and can be easily tested using AndroidX Test with instrumentation or local tests. The basic premise here is that when something Android thinks of as "configuration" (like screen size, orientation, dark/light mode etc) changes at the system level, Activity object will be recreated with that new configuration. Before this happens, the system calls [`Activity#onSaveInstanceState`](https://developer.android.com/reference/android/app/Activity#onSaveInstanceState(android.os.Bundle)){:target="_blank"} which creates a `Bundle` that will eventually be passed to [`Activity#onCreate`](https://developer.android.com/reference/android/app/Activity#onCreate(android.os.Bundle)){:target="_blank"} for the new instance of the Activity. That "saved instances state" `Bundle` can therefore be used to persist state between configurations. On top of that there's two pretty big things to keep in mind:

1. Jetpack's [ViewModels](https://developer.android.com/topic/libraries/architecture/viewmodel#lifecycle){:target="_blank"} survive configuration changes (assuming they're being created using a `ViewModelProvider`) making them a good place to keep state that should stick around between rotations etc.
2. Fragments hosted in the Activity (including `DialogFragment` instances) will be recreated as part of your `super.onCreate` call. This is useful for doing things like keeping dialogs on screen between configuration changes, but it can cause problems if your code doesn't take into account setting things up for these recreated Fragments. A prime example of this that you'll need to have any custom `FragmentFactory` setup taken care of before `super.onCreate` so that Fragments can be recreated.

Here's how to simulate this scenario using Robolectric:

```kotlin
val activityController = Robolectric.buildActivity(MyActivity::class.java)
    .setup()
activityController.recreate()
```

As I said before, you can also use AndroidX Test for this:

```kotlin
val activityScenario = ActivityScenario.launch(MyActivity::class.java)
activityScenario.recreate()
```

### System recreates process

As mentioned earlier, Android will occasionally destroy app processes in the background to reclaim memory. This probably happens more than you realize according to [dontkillmyapp.com](https://dontkillmyapp.com){:target="_blank"}. When this happens, the app's process and current back stack is destroyed (with corresponding `Activity#onSaveInstanceState` calls) and then both are recreated when the user navigates back to the app. Because the back stack is recreated, we do again get to keep our saved instance state `Bundle` and our Fragments, but we'll lose ViewModels and any "process" level state (Java `static` or state we've attached to the Android `Application`). You can force this behaviour to happen whenever you switch between apps (the one now in the background will be destroyed) using the ["Background process limit" setting in Developer settings](https://developer.android.com/studio/debug/dev-options#apps){:target="_blank"}. 

I'm unable to provide a one-size-fits-all solution to simulating this scenario as what state needs to be reset or initializers that need to be run to simulate the process restart will be different for every app. Here's an example that you can bring your own `resetProcess` implementation along to however:

```kotlin
val initial = Robolectric.buildActivity(MyActivity::class.java)
    .setup()
val outState = Bundle()
initial.saveInstanceState(outState)
    .pause()
    .stop()
    .destroy()

resetProcess()
        
val recreated = Robolectric.buildActivity(MyActivity::class.java)
    .setup(outState)
```

It's probably obvious, but still worth pointing out that implementing a realistic version of `resetProcess` is always going to be challenging as you might not be aware of every piece of static state in your app. I'd definitely suggest putting your app through this scenario manually in an emulator or a test device to discover any problematic state you might have.

## Activity results

You forgot about [`Activity#startActivityForResult`](https://developer.android.com/reference/android/app/Activity#startActivityForResult(android.content.Intent,%20int)){:target="_blank"} right? Although it shouldn't cause you any problems during [configuration changes](#configuration-changes), it can add some real headaches to the [system recreates process](#system-recreates-process) scenario. Imagine that `MyActivity` from our examples starts another Activity `ResultActivity` for result. Android could destroy the whole process if the user navigates away. When `ResultActivity` returns the result after this, `onActivityResult` will be called after `MyActivity#onCreate` is called during recreation which might get you in trouble if you're loading state you expected to have ready already or if you have something important in `Activity#onResume`. Again, we can fortunately simulate this with some (arguably far nastier) Robolectric:

```kotlin
val initial = Robolectric.buildActivity(MyActivity::class.java)
    .setup()

// Action to start `ResultActivity` for result

val outState = Bundle()
initial.saveInstanceState(outState)
    .pause()
    .stop()
    .destroy()

resetProcess()
        
val recreated = Robolectric.buildActivity(MyActivity::class.java, this.intent)
    .create(outState)
    .start()
    .restoreInstanceState(outState)
    .postCreate(outState)

val startedActivityForResult = shadowOf(initial.get())
    .nextStartedActivityForResult
shadowOf(recreated.get()).receiveResult(
    startedActivityForResult.intent, 
    resultCode, 
    result
)

recreated.resume()
        .visible()
        .topActivityResumed(true)
```

Here we have to manually execute the lifecycle steps that `ActivityController#setup` was handling for us so that we can simulate the result being received (via `ShadowActivity#receiveResult`) between `postCreate` and `onResume`.

As far as I'm aware, the lifecycle steps and their ordering would be the same here if you opted to use the new [Activity Results API](https://developer.android.com/training/basics/intents/result#launch){:target="_blank"} instead of using the now deprecated `startActivityForResult`/`onActivityResult` directly (which you should if you can).

## Extensions to the rescue

We're at a point where we need a fairly noisy amount of code to simulate these scenarios, and in practice these tests would be very hard to read. I've wrapped all this up in an extension for `ActivityController` to make my (and hopefully your) life a little easier:

```kotlin
inline fun <reified A : Activity> ActivityController<A>.recreateWithProcessRestore(
    resultCode: Int? = null,
    result: Intent? = null,
    noinline resetProcess: (() -> Unit)? = null
): ActivityController<A> {
    // Destroy activity with saved instance state
    val outState = Bundle()
    this.saveInstanceState(outState).pause().stop().destroy()

    // Reset process if needed
    if (resetProcess != null) {
        resetProcess()
    }

    // Recreate with saved instance state
    val recreated = Robolectric.buildActivity(A::class.java, this.intent)
        .create(outState)
        .start()
        .restoreInstanceState(outState)
        .postCreate(outState)

    // Return result
    if (resultCode != null) {
        val startedActivityForResult = shadowOf(this.get())
            .nextStartedActivityForResult
        shadowOf(recreated.get()).receiveResult(
            startedActivityForResult.intent,
            resultCode,
            result
        )
    }

    // Resume activity
    return recreated.resume()
        .visible()
        .topActivityResumed(true)
}
```

There was probably a way to do this without `reified`, but what fun would that be?