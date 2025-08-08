---
layout: post
title:  "Thoughts on Compose"
description: "Fashionably late"
---

I've been working on Android apps professionally since 2013, and with that I've experienced the windy road of different trends in Android app development: the classic "multi Activity" structure, CursorLoaders, Fragments, the switch in focus to Kotlin, AndroidX introducing lifecycle aware reactivity and a formalization of MVVM with LiveData and ViewModel, and now [Compose](https://developer.android.com/compose).

Since Compose was announced in 2019, I've maintained a "healthy" (I'd argue) skepticism - we all know how [willing to kill its darlings Google can be](https://killedbygoogle.com/), and I'd seen the pain caused by Angular 1 to 2 rewrites. I was, and I still am working on [a very mature and very large app](https://github.com/getodk/collect/), so any migration would need to wait until we saw Compose mature anyway.

This January, I took some time to play around with some toy apps for myself and decided to finally give it a go. What follows is what made me happy, and what made me sad.

### Happy
- It feels really quick to get going and achieves its goal of letting you build a "declarative" UI layer that can be easily tested.
- The [`@Preview`](https://developer.android.com/develop/ui/compose/tooling/previews) feature is amazing, although it's not quite clear why it couldn't have worked for standard Android views, and I'm salty that they haven't ported it over.
- The focus of the docs is using Material Components, but you can create your own design system using `foundation` package Composables (like `BasicText` etc.) and [`CompositionLocal`](https://developer.android.com/develop/ui/compose/compositionlocal) for theming.
- You can mix Compose and standard Android views in an app **and** still test it at an instrumentation level using [`AndroidComposeTestRule`](https://developer.android.com/reference/kotlin/androidx/compose/ui/test/junit4/AndroidComposeTestRule). That said...
### Sad
- ...you always need to use some form of `ComposeTestRule` to interact with Composables in tests (you can't use Espresso) which means that the tests are locked in to the implementation somewhat, and you're always going to have to change tests when migrating to Compose. The only alternative to avoiding these costs/risks would be to use [UIAutomator](https://developer.android.com/training/testing/other-components/ui-automator).
- It's still not "production ready" for everything - [dialogs are still experimental for example](https://developer.android.com/reference/kotlin/androidx/compose/material3/package-summary#AlertDialog(kotlin.Function0,androidx.compose.ui.Modifier,androidx.compose.ui.window.DialogProperties,kotlin.Function0)).
- The level of [magic](https://giphy.com/gifs/shia-labeouf-12NUbkX6p4xOO4) is high. For example, the fact that Composables return `Unit` and "emit" views (as opposed to returning some kind of Composable super type) feels uncomfortable to me.
- Integrating with lifecycle (through the ["effects" mechanism](https://developer.android.com/topic/libraries/architecture/compose#run-code)) feels pretty awkward, and I'd be worried about this for apps that need to be lifecycle aware (for managing peripherals or background services for instance).
- The story around migration for an app with a custom Material theme is [not great](https://developer.android.com/develop/ui/compose/designsystems/views-to-compose): you end up needing to either generate a theme (using your existing colors) or create a Compose [Material Theme](https://developer.android.com/develop/ui/compose/designsystems/material3#material-theming) from scratch to match your existing one. Whichever route you take, you'll need to migrate shape and typography manually and will have to make any changes to your theme in both places while both exist.

