---
title: Building this blog with Ignite
date: 2026-09-01
tags: swift, ignite, web
---

# Building this blog with Ignite

I built this site with [Ignite](https://github.com/twostraws/Ignite), a static site generator that lets you describe web pages in Swift using a result-builder syntax that feels a lot like SwiftUI. This first post is a placeholder — replace it with your own story of setting the site up.

## Why Ignite

PLACEHOLDER: Why you chose Swift for your blog instead of Hugo, Jekyll, or a hosted platform.

## What I learned

PLACEHOLDER: Things that clicked while building this — the `Site` protocol, markdown front matter, how `ArticlePage` renders posts.

```swift
struct PersonalBlog: Site {
    var name = "My Blog"
    var homePage = Home()
    var layout = MainLayout()
}
```
