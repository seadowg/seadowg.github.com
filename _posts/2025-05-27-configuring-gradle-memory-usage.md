---
layout: post
title:  "Configuring Gradle Memory Usage"
---

## Heap configuration

The "simplest" way to configure how much memory Gradle will use is to configure the heap for the JVM process it spawns by passing args with `org.gradle.jvmargs` in `gradle.properties` (either in the project root or in your user's `.gradle` directory which overrides the former):

```properties
# Set a maximum heap size of 4 gigabytes
org.gradle.jvmargs=-Xmx4g
```

There are caveats to this though. If you want to configure Gradle for machines with tighter memory constraints (like a container based CI environment), or to take advantage of a beefier dev machine there a few more possible tweaks you'll want to be aware of:

- By default, Kotlin spawns an extra daemon for compilation using the `org.gradle.jvmargs` JVM args. It's good to keep in mind that if you configure Gradle to use a specific heap size, then you could actually end up using double that during compilation of a mixed Java/Kotlin project.
- The extra Kotlin daemon can be disabled by setting `kotlin.compiler.execution.strategy=in-process` as part of `gradle.properties` (useful for CI configuration) and [its heap can also be configured](https://kotlinlang.org/docs/gradle-compilation-and-caches.html#kotlin-daemon-jvm-options-system-property).
- The test heap can be adjusted with the `maxHeapSize` property in the `test` block of a `build.gradle` or in `unitTests.all` in `android` > `testOptions`. Remember that this heap size is additional (Gradle spawns a specific worker process for tests) to the already spawned Gradle processes handling compilation and other tasks. If you configure a heap size of **T** for tests and **D** for your standard Gradle daemon, then your peak heap memory will be **T + D** (or **T + D * 2** if you haven't disabled the extra Kotlin daemon).

## Parallelism

Gradle can also handle tasks in parallel. This is useful for multi-module projects where modules are able to be built/tested in parallel as long they don't have dependencies on each other. You can enable this feature by adding `org.gradle.parallel=true` to `gradle.properties`. There is again, a few things you should keep in mind when doing this:

- Gradle will attempt to do as much in parallel as it can, and each of these parallel pieces of work will result in another thread being spawned in one of your Gradle daemons. This means that this parallel work will share the memory heap defined by `org.gradle.jvmargs`.
- The maximum number of parallel operations can be controlled by `org.gradle.workers.max`, but this should default to the number of CPUs.
- Test parallelism is configured separately from other task parallelism. To enable more than one test task to run in parallel, you can set `maxParallelForks` (again in `test` or `unitTests.all` For Android) to a number greater than 1.  The caveat here is that this will spawn new processes instead of threads, so you need to have the capacity to handle `maxHeapSize` multiplied by `maxParallelForks` in addition to the Gradle daemon's heap.

## Thoughts

I've personally found that build tasks often benefits from a boost in heap size, but that most test runs (unless there is some underlying memory leak) are pretty happy with the default 512mb heap size. You can also think about using different `gradle.properties` for different tasks (subbing them in and out with a script) or [passing configuration as args on the command line](https://docs.gradle.org/current/userguide/command_line_interface.html). This isn't as useful on dev machines, but can work well on CI where you often end up with a pipelined set of tasks (pull down dependencies, then build, then test for instance). With this approach, you could have different memory configurations for different tasks - you can prioritize compilation memory for compilation tasks and prioritize test memory for test tasks.

It's also important to point out that the heap does not make up the total memory footprint of a JVM process: there's the "Metaspace" for storing loaded classes, each thread has its own "Thread Stack" etc. This means that depending on your project, your Gradle tasks might consume noticeably more memory than you'd expect from your heap configurations. Ultimately, playing with the values and seeing what gives you the best results for your project is something you'll need to spend time on. Using tools like [VisualVM](https://visualvm.github.io/) to analyze appropriate heap sizes for the different heaps, as well as tools like Activity Monitor on macOS (or the equivalents in other OSs) to check how large the actual processes get in memory will be really important here. Hopefully there's enough info in this post to make that process a little less mysterious!
