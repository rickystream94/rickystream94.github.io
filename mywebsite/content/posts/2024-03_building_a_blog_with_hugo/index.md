---
title: "Building a blog with Hugo"
date: 2024-03-02
topics: ['Technology']
featureImage: "https://richmondwebmedia.blob.core.windows.net/media/static_assets/logo.png"
---

## Background

Since 2016, I used to have a hosting plan with [Aruba](https://www.aruba.it/), where I had a Wordpress installation of my original website. As I was already quite confident with Wordpress, and I preferred using a CMS for organizing my content and leveraging the endless power of plugins, this solution was working well for me.
However, considering the relatively small amount of contents I was publishing, over the years having a CMS for a personal website turned out to be an overhead.

In 2023, I accidentally deleted the website while I was migrating my domain to a different provider, without the possibility of recovering any content at all (don't ask me how this happened and why I didn't keep a local backup 😢). Therefore, I found myself having to start from scratch again. Luckily, I could recover the content of the database at least, so not too bad in the end.

When I started looking around, I knew I didn't want to end up with a complex setup and tech stack, to avoid having to invest a lot of time and to be able to be up and running again relatively quickly.
I learnt a bit about _static site generators_ and technologies like Tailwind CSS, which all sounded appealing and suitable to my scenario. And I also knew I wanted to host my new website on Azure.
And that's how it all started...

## Tech stack

* [Hugo Framework](https://gohugo.io/): is a fast, modern and open-source static site generator written in Go, and designed to make website creation fun again. You can read more about Hugo [here](https://gohugo.io/about/what-is-hugo/).
You can explore a large variety of [themes/templates](https://themes.gohugo.io/), arranged by category.
* [Blowfish](https://blowfish.page/): was the Hugo blog theme I ended up choosing, and since it was my first real hands-on opportunity on such static site generators, I was amazed by how easy it was to customize the theme, create and edit content.

I quickly perceived Hugo as a game changer, and the reasons listed in [_Who should use Hugo?_](https://gohugo.io/about/what-is-hugo/#who-should-use-hugo) in the official docs resonated with me:

> Hugo is for people that prefer writing in a text editor over a browser.
>
> Hugo is for people who want to hand code their own website without worrying about setting up complicated runtimes, dependencies and databases.
>
> Hugo is for people building a blog, a company site, a portfolio site, documentation, a single landing page, or a website with thousands of pages.

Furthermore, I enjoy a lot the local development experience:
1. The `hugo server` command runs a slim Hugo server to serve your website on `localhost`.
1. While the server is running, you can work on updating your website content: editing Markdown files, adding/removing image files and so on.
1. Hugo rebuilds your site locally whenever it detects a change, which results in an automatically refreshed web page and you can see the results immediately on the browser. This is _so cool_!

## Hosting and deployment

* The whole website is under source control on **GitHub**:
    {{< github repo="rickystream94/rickystream94.github.io" >}}
* To keep the repository as "light" as possible, I am storing most media files in an external [Azure Storage BLOB container](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction).
* [Azure Static Web App](https://learn.microsoft.com/en-us/azure/static-web-apps/): is an offer from Azure which allows you to build modern web applications that automatically publish to the web as your code changes.
* Thanks to this [documentation](https://learn.microsoft.com/en-us/azure/static-web-apps/publish-hugo), it was really straightforward to setup a **GitHub Actions** workflow that would deploy the website automatically at every push to the GitHub repo.



## Logo

And if you're curious about how I created the logo for this website... You should ask [**Microsoft Copilot**](https://copilot.microsoft.com/) and its **Image Designer** feature 😁
I only had to help myself with Photoshop to fine-tune the AI generated result:

![AI generated website logo](https://richmondwebmedia.blob.core.windows.net/media/static_assets/logo.png)