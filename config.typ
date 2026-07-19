#import "post.typ": post
#import "@preview/cmarker:0.1.8": render

#let config = toml("config.toml")

#let blog-title = config.title
#let tagline = config.at("tagline", default: "")

#let unsorted-articles = ()

#for article in config.at("articles") {
  if (article.at("draft", default: false)) {
    continue
  }

  let article_path = "posts/" + article.path
  let article_permalink = article.permalink
  let article_tagline = article.at("tagline", default: "")

  let show-post = post.with(
    post-title: article.at("title", default: none),
    post-date: article.at("date", default: none),
    blog-title: blog-title,
    tagline: tagline,
  )

  let article_content = {
    [
      #show: show-post
      #include article_path
    ]
  }

  unsorted-articles.push((
    permalink: article_permalink,
    title: article.title,
    tagline: article.tagline,
    date: article.date,
    content: article_content,
  ))
}

#let articles = unsorted-articles.sorted(key: article => article.date, by: (a, b) => a >= b)
