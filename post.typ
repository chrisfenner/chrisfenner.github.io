#let div(class, body) = html.elem("div", attrs: (class: class), body)
#let span(class, body) = html.elem("span", attrs: (class: class), body)
#let fancy(body) = html.elem("span", attrs: (class: "fancy"), body)

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
    #div("footer-column1")[
      Chris Fenner's Personal Blog
    ]
    #div("footer-column2")[
      // Font Awesome Free v7.3.1 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free Copyright 2026 Fonticons, Inc.
      #link("https://github.com/chrisfenner", html.elem(
        "svg",
        attrs: (viewBox: "0 0 640 640"),
      )[
        #html.elem("path", attrs: (
          d: "M280.5 426.5C214.5 418.5 168 371 168 309.5C168 284.5 177 257.5 192 239.5C185.5 223 186.5 188 194 173.5C214 171 241 181.5 257 196C276 190 296 187 320.5 187C345 187 365 190 383 195.5C398.5 181.5 426 171 446 173.5C453 187 454 222 447.5 239C463.5 258 472 283.5 472 309.5C472 371 425.5 417.5 358.5 426C375.5 437 387 461 387 488.5L387 540.5C387 555.5 399.5 564 414.5 558C505 523.5 576 433 576 321C576 179.5 461 64 319.5 64C178 64 64 179.5 64 321C64 432 134.5 524 229.5 558.5C243 563.5 256 554.5 256 541L256 501C249 504 240 506 232 506C199 506 179.5 488 165.5 454.5C160 441 154 433 142.5 431.5C136.5 431 134.5 428.5 134.5 425.5C134.5 419.5 144.5 415 154.5 415C169 415 181.5 424 194.5 442.5C204.5 457 215 463.5 227.5 463.5C240 463.5 248 459 259.5 447.5C268 439 274.5 431.5 280.5 426.5z",
        ))
      ])
      #link("/feed.xml", html.elem("svg", attrs: (viewBox: "0 0 640 640"))[
        #html.elem("path", attrs: (
          d: "M96 128C96 110.3 110.3 96 128 96C357.8 96 544 282.2 544 512C544 529.7 529.7 544 512 544C494.3 544 480 529.7 480 512C480 317.6 322.4 160 128 160C110.3 160 96 145.7 96 128zM96 480C96 444.7 124.7 416 160 416C195.3 416 224 444.7 224 480C224 515.3 195.3 544 160 544C124.7 544 96 515.3 96 480zM128 224C287.1 224 416 352.9 416 512C416 529.7 401.7 544 384 544C366.3 544 352 529.7 352 512C352 388.3 251.7 288 128 288C110.3 288 96 273.7 96 256C96 238.3 110.3 224 128 224z",
        ))
      ])
    ]
    #div("footer-column3")[
      #emph(tagline)
    ]
  ]
]

#let date-format = "[month repr:long] [day padding:none], [year]";

#let date(datetime) = {
  html.elem("aside", datetime.display(date-format))
}

#let _html_meta(title, description, og-type: none) = {
  let base-attrs = (
    (charset: "utf-8"),
    (name: "viewport", content: "width=device-width, initial-scale=1"),
    (property: "og:title", content: title),
    (property: "og:description", content: description),
    (property: "og:image", content: "https://dlp.rip/og-image.png"),
    (itemprop: "name", content: title),
  )
  if og-type != none {
    ((property: "og:type", content: og-type), ..base-attrs)
  } else {
    base-attrs
  }
}

#let _main(
  page-title: none,
  blog-title: none,
  tagline: none,
  meta: none,
  body,
) = [
  #html.elem("html", attrs: (prefix: "og: http://ogp.me/ns#"))[
    #html.head[
      #if meta != none {
        for meta-elem in meta {
          html.elem("meta", attrs: meta-elem)
        }
      }
      #html.elem("title", page-title)
      // Typst currently can't emit an empty style tag.
      #html.elem("style", attrs: (rel: "stylesheet", type: "text/css"), read("stylesheet.css"))
      // https://css-tricks.com/emoji-as-a-favicon/
      #html.elem("link", attrs: (
        rel: "icon",
        type: "image/png",
        href: "/favicon.png",
      ))
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

#let post(
  post-title: none,
  post-date: none,
  blog-title: none,
  tagline: none,
  body,
) = context [
  #set quote(block: true)

  // Self-linkify all headings.
  #show heading: heading => [
    // Fetch the id of the heading in case one was provided (or generated?).
    #let label = heading.at("label", default: none)
    #if label != none {
      html.elem("h" + str(heading.level + 1))[
        #link(label, heading.body)
      ]
    } else {
      html.elem("h" + str(heading.level + 1), heading.body)
    }
  ]
  // Wrap code blocks.
  #show raw.where(theme: auto, block: true): content => [
    #div("code", raw(
      theme: "syntax/.tmTheme",
      lang: content.lang,
      block: true,
      content.text,
    ))
  ]
  // Support non-default languages.
  #show raw.where(lang: "kconfig"): set raw(
    syntaxes: "syntax/kconfig.sublime-syntax",
  )
  // Wrap math blocks in a nice div so we can style it and make it scrollable.
  #show math.equation.where(block: true): content => [
    #div("math", content)
  ]
  #show: _main.with(
    page-title: post-title + " - " + blog-title,
    blog-title: blog-title,
    meta: _html_meta(post-title, tagline, og-type: "article"),
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

#let index(posts: (), blog-title: none, tagline: none) = [
  #show: _main.with(
    page-title: blog-title,
    blog-title: blog-title,
    meta: _html_meta(blog-title, tagline),
    tagline: tagline,
  )

  #title[Posts]

  #for post in posts [
    #html.elem("div", attrs: (class: "post-link"))[
      #link(post.permalink, post.title)
      #span("post-tagline", post.tagline)
      #date(post.date)
    ]
  ]
]
