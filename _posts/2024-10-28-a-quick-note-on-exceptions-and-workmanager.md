---
layout: post
title:  "A quick note on exceptions and WorkManager"
description: ""Silent Crashing""
---

I was recently asked a question about what happens if an error occurs (an unexpected `Exception` is thrown) while running a task in the background using [WorkManager](https://developer.android.com/topic/libraries/architecture/workmanager). I realised I had no idea, so decided to investigate.

After playing around with the debugger and a few choice placements of `throw RuntimeException()`, I've managed to conclude a couple of things:

 - Exceptions that happen as part of `Worker#doWork` are caught by WorkManager and then logged as errors, but the exception does not cause your app to crash. This is possible to see from testing, but is also clear from the [underlying code](https://android.googlesource.com/platform/frameworks/support.git/+/refs/heads/androidx-work-release/work/work-runtime/src/main/java/androidx/work/Worker.kt#102).
- WorkManager treats this work in the same way as one that returns a `Result.failure`: any work that depend on this work as part of a chain will not run, and periodic work won't run again until the next scheduled time. For example, if the work is scheduled to run every 15 minutes, it will try again in 15 minutes after an exception.

This is good news for the stability statistics of your app, but does mean that it's easy to completely miss that your background tasks are failing due to unexpected exceptions - you wouldn't see them in development unless you're paying close attention the logs and they wouldn't appear automatically in crash logs (like Crashlytics for example).

 Surprisingly, I couldn't find any documentation on this, but it seems to me like it'd be good practice to wrap your `Worker#doWork` implementations in a `try-catch` so you can handle exceptions like so:

```kotlin
class MyWorker(context: Context, workerParams: WorkerParameters) :
    Worker(context, workerParams) {
    override fun doWork(): Result {
        return try {
            // do your thing
            Result.success()
        } catch (t: Throwable) {
            // handle or log exception
            throw t
        }
    }
}
```

In theory, you could also return `Result.failure()` from the `catch` branch, but that relies on WorkManager's currently undocumented exception handling staying consistent whereas throwing the exception continues to allow WorkManager to do whatever "works" (😁) for it.