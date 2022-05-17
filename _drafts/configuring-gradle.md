---
layout: post
title: "Configuring Gradle memory usage for Kotlin development"
---

The "simplest" way to configure how much memory Gradle will use is to configure the JVM process it spawns by passing args with `org.gradle.jvmargs` in `gradle.properties`:

```
# Set a maximum heap size of 2048 megabytes
org.gradle.jvmargs=-Xmx2048m
```

There are caveats to this though. This process is only used for compilation (not running tests) and, by default, Kotlin spawns a second process (daemon) to do compilation. If you want to configure Gradle for machines with tighter memory constraints (like a container based CI environment), or to take advantage of a beefier dev machine there a few more possible tweaks you'll want to be aware of:

- By default Kotlin spawns an extra daemon for compilation using the `org.gradle.jvmargs` JVM args. It's good to keep in mind that if you configure Gradle to use a JVM with a heap size of **X**, then you'll actually end up using **X x 2** memory during compilation by default.
- The extra Kotlin daemon can be disabled by passing `Dkotlin.compiler.execution.strategy="in-process"` as part of `org.gradle.jvmargs`.
- Tests are run in a separate JVM process that does not use the `org.gradle.jvmargs` JVM args.
- The test heap can be adjusted with the `maxHeapSize` property in the `test` block of a `build.gradle` or in `unitTests.all` in `android` > `testOptions`. Remember that this is heap size is additonal to the already spawned Gradle processes handling compilation and other tasks. If you configure a heap size of **Y** for tests and **X** for your standard Gradle daemon (using `org.gradle.jvmargs`) then your peak memory usage will be **X + Y** (or **(X x 2) + Y** if you haven't disabled the extra Kotlin daemon).

Gradle can also handle tasks in parallel. This is useful for multi-module projects where some modules might be able to be built/tested in parallel (as long they don't have dependencies) on each other. You can enable this feature by add `org.gradle.parallel=true` to `gradle.properties`. There is again, a few things you should keep in mind when doing this:

- Gradle will attempt to do as much in parallel as it can (up to a max number of parallel operations) and each of these parallel pieces of work will result in another JVM being spawned. So if your max heap size (defined in `org.gradle.jvmargs`) is **X** then your peak memory usage will be **X** multiplied by the maximum number of parallel operations.
- The maximum number of parallel opertaions can be controlled by `org.gradle.workers.max` but this should default to the number of CPUs (although this isn’t always true in container environments like Docker).
- Tests for different modules might end up running in parallel as well (and spawning their own test JVMs) if `org.gradle.parallel` is true.

From all this, it's hopefully easy to see how you can end up with a much larger peak memory footprint than expected. Using `org.gradle.parallel` and boosting your heap sizes can seem like a great idea initially, but you might end up creating a scenario where you max out the available RAM on your machine and force everything to grind to a halt. That, or you end up with JVMs crashing due to out of memory errors. Remember to always calculate the peak memory footprint when tweaking all these values. It's also good to consider the best place to allocate memory: does anything actually get built in parallel, do your tests benefit from a larger heap? 

I've personally found that compilation often benefits from a boost in heap size, but that most test runs (unless there is some underlying memory leak) are pretty happy with the default 512mb heap size. You can also think about using different `gradle.properties` for different tasks (subbing them in and out with a script). This isn't as useful on dev machines, but can work well on CI where you often end up with a pipelined set of tasks (pull down dependencies, then build, then test for instance). With this approach, you can have different memory configurations for different tasks - you can prioritize compilation memory for compilation tasks and prioritize test memory for test tasks.

Ultimately, playing with the values and seeing what gives you the best results for your project is something you'll need to spend time on. Hopefully there's enough info in this post to make that process a little less mysterious!