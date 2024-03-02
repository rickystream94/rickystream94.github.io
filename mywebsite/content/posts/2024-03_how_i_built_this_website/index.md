---
title: "How I built this website"
date: 2024-03-02
topics: ['Technology']
heroStyle: "thumbAndBackground"
---

## Background

Since 2016, I used to have a hosting plan with [Aruba](https://www.aruba.it/), where I had a Wordpress installation of my original website. As I was already quite confident with Wordpress, and I preferred using a CMS for organizing my content and leveraging the endless power of plugins, this solution was working well for me.
However, considering the relatively small amount of contents I was publishing, over the years having a CMS for a personal website turned out to be an overhead.

In 2023, I accidentally deleted the website while I was migrating my domain to a different provider, without the possibility of recovering any content at all (don't ask me how this happened and why I didn't keep a local backup 😢). Therefore, I found myself having to start from scratch again. Luckily, I could recover the content of the database at least, so not too bad in the end.

When I started investigating I knew I didn't want to come up with a complex setup and tech stack, to avoid having to invest a lot of time and to be able to be up and running again relatively quickly.
I learnt a bit about _static site generators_ and technologies like Tailwind CSS, which all sounded appealing and suitable to my scenario. And I also knew I wanted to host my new website on Azure.
And that's how it all started...

## Tech stack

* [Hugo Framework](https://gohugo.io/): is a fast, modern and open-source static site generator written in Go, and designed to make website creation fun again. You can read more about Hugo [here](https://gohugo.io/about/what-is-hugo/).
You can explore a large variety of [themes/templates](https://themes.gohugo.io/), arranged by category.
* [Blowfish](https://blowfish.page/): was the Hugo blog theme I ended up choosing, and since it was my first real hands-on opportunity on such static site generators, I was amazed by how easy it was to customize the theme, create and edit content.

Hugo was a game changer for me, and the reasons listed in [_Who should use Hugo?_](https://gohugo.io/about/what-is-hugo/#who-should-use-hugo) in the official docs resonated with me:

> Hugo is for people that prefer writing in a text editor over a browser.
>
> Hugo is for people who want to hand code their own website without worrying about setting up complicated runtimes, dependencies and databases.
>
> Hugo is for people building a blog, a company site, a portfolio site, documentation, a single landing page, or a website with thousands of pages.

## Hosting and deployment

* The whole website is under source control in my [personal GitHub repository](https://github.com/rickystream94/rickystream94.github.io).
* [Azure Static Web App](https://learn.microsoft.com/en-us/azure/static-web-apps/): is an offer from Azure which allows you to build modern web applications that automatically publish to the web as your code changes.
* Thanks to this [documentation](https://learn.microsoft.com/en-us/azure/static-web-apps/publish-hugo), it was really straightforward to setup a **GitHub Actions** workflow that would deploy the website automatically at every push to the GitHub repo.

## Logo

And if you're curious about how I created the logo for this website... You should ask [**Microsoft Copilot**](https://copilot.microsoft.com/) and its **Image Designer** feature 😁
I only had to helped myself with Photoshop to fine-tune the AI generated result:

![AI generated website logo](featured.png)