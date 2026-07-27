
// Partly based on Eira Fransham's static site solution based on Typst bundles:
// https://github.com/eira-fransham/troubles.md.typ/blob/main/bundle.typ
//
// This is the entry point
//
// To compile the static site, run `typst compile --features html,bundle --format bundle bundle.typ`

#import "config.typ": blog-title, posts, tagline
#import "post.typ": index

#for post in posts [
  // Hosting the document at just `post.permalink` results in the browser
  // offering to download the page instead of just display it.
  #document(post.permalink + "/index.html", post.content, format: "html") #label(post.permalink)
]

#document("index.html", title: blog-title, index(
  posts: posts,
  blog-title: blog-title,
  tagline: tagline,
)) <index>

#asset(
  "CNAME",
  read("CNAME"),
)

#asset(
  "feed.xml",
  read("feed.xml"),
)

#asset(
  "og-image.png",
  read("og-image.png", encoding: none),
)

#asset(
  "favicon.png",
  read("favicon.png", encoding: none),
)
