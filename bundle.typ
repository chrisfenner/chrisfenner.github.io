
// Partly based on Eira Fransham's static site solution based on Typst bundles:
// https://github.com/eira-fransham/troubles.md.typ/blob/main/bundle.typ
//
// This is the entry point
//
// To compile the static site, run `typst compile --features html,bundle --format bundle bundle.typ`

#import "config.typ": articles, blog-title, tagline
#import "post.typ": index

#for article in articles [
  #document(article.permalink, article.content, format: "html") #label(article.permalink)
]

#document("index.html", title: blog-title, index(
  articles: articles,
  blog-title: blog-title,
  tagline: tagline,
)) <index>

#asset(
  "CNAME",
  read("CNAME"),
)
