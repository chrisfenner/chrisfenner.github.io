#let div(class, body) = html.elem("div", attrs: (class: class), body)
#let span(class, body) = html.elem("span", attrs: (class: class), body)

#let header(blog-title: "My Blog") = [
  #html.elem("header")[
    #span("blog-name")[
      #link(<index>)[#blog-title]
    ]
  ]
  #html.elem("span")
]

#let footer(tagline: "") = [
  #divider()
  #div("footer-obligatory")[
    #emph[Opinions expressed here are my own and do not represent the official positions
      of any employer(s) of mine, past or present]
  ]
  #div("footer-columns")[
    #div("footer-column")[
      Chris Fenner's Personal Blog
    ]
    #div("footer-column")[
      #link("https://github.com/chrisfenner")[github]
    ]
    #div("footer-column")[
      #emph(tagline)
    ]
  ]
]

#let date-format = "[month repr:long] [day padding:none], [year]";

#let date(datetime) = {
  html.elem("aside", datetime.display(date-format))
}

#let _html_meta(page-title, image: "floppies.png") = (
  (charset: "utf-8"),
  (name: "viewport", content: "width=device-width, initial-scale=1"),
  (name: "og:title", content: page-title),
  (itemprop: "name", content: page-title),
  (name: "image", content: image),
  (name: "og:image", content: image),
)

#let _main(
  page-title: none,
  blog-title: none,
  tagline: none,
  meta: none,
  body,
) = [
  #let meta = if meta == none {
    _html_meta(page-title)
  } else {
    meta
  }
  #html.html[
    #html.head[
      #for meta-elem in meta {
        html.elem("meta", attrs: meta-elem)
      }
      #html.elem("title", page-title)
      // Typst currently can't emit an empty style tag.
      #html.elem("style", attrs: (rel: "stylesheet", type: "text/css"), read("stylesheet.css"))
    ]
    #html.body[
      #div("main")[
        #header(
          blog-title: blog-title,
        )
        #div("content", body)
        #footer(
          tagline: tagline,
        )
      ]
    ]
  ]
]

#let _plain-text(it) = {
  return if type(it) == str {
    it
  } else if it == [ ] {
    " "
  } else if it.has("children") {
    it.children.map(_plain-text).join()
  } else if it.has("body") {
    plain-text(it.body)
  } else if it.has("text") {
    if type(it.text) == str {
      it.text
    } else {
      _plain-text(it.text)
    }
  } else {
    // remove this to ignore all other non-text elements
    stringify-by-func(it)
  }
}

#let _slugify(text) = {
  lower(_plain-text(text).replace(regex("\W+"), "-").replace(regex("(^-+|-+$)"), ""))
}

#let post(
  post-title: none,
  post-date: none,
  blog-title: none,
  tagline: none,
  body,
) = context [
  #set quote(block: true)
  #show heading.where(level: 1): heading => [
    #let label = label(_slugify(post-title + "-" + heading.body))
    #html.elem("h2")[
      #span("section-title", heading.body)
      #span("section-link-postfix")[#link(label)[§]]
    ] #label
  ]
  #show heading.where(level: 2): heading => [
    #let label = label(_slugify(post-title + "-" + heading.body))
    #html.elem("h3")[
      #span("section-link")[#link(label)[#html.elem("span")[§]]]
      #span("section-title", heading.body)
      #span("section-link-postfix")[#link(label)[§]]
    ] #label
  ]
  #show raw.where(theme: auto, block: true): content => [
    #div("code", raw(
      theme: "syntax/.tmTheme",
      lang: content.lang,
      block: true,
      content.text,
    ))
  ]
  #show: _main.with(
    page-title: post-title + " - " + blog-title,
    blog-title: blog-title,
    meta: ((name: "og:type", content: "article"), .._html_meta(post-title)),
    tagline: tagline,
  )

  #let post-title = if post-title != none { post-title } else { body.at("title", default: none) }
  #let post-date = if post-date != none { post-date } else { body.at("date", default: none) }

  #div("title")[
    #title(post-title)
    #date(post-date)
  ]

  #div("post", [
    #body
  ])
]

#let index(articles: (), blog-title: none, tagline: none) = [
  #show: _main.with(
    page-title: blog-title,
    blog-title: blog-title,
    tagline: tagline,
  )

  #title[Posts]

  #for article in articles [
    #html.elem("div", attrs: (class: "post-link"))[
      #link(article.permalink, article.title)
      #span("article-tagline", article.tagline)
      #date(article.date)
    ]
  ]
]
