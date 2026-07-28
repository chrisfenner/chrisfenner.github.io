#import "post.typ": post

#let config = toml("config.toml")

#let blog-title = config.title
#let tagline = config.at("tagline", default: "")

#let unsorted-posts = ()

#let doc-version = sys.inputs.at("version", default: "Final")

#for this_post in config.at("posts") {
  if (this_post.at("draft", default: false) and doc-version != "Draft") {
    continue
  }

  let post_path = "posts/" + this_post.path
  let post_permalink = this_post.permalink
  let post_tagline = this_post.at("tagline", default: "")
  let post_image = this_post.at("preview", default: none)

  let show-post = post.with(
    post-title: this_post.at("title", default: none),
    post-date: this_post.at("date", default: none),
    blog-title: blog-title,
    tagline: post_tagline,
    preview-image: post_image,
  )

  let post_content = {
    [
      #show: show-post
      #include post_path
    ]
  }

  unsorted-posts.push((
    permalink: post_permalink,
    title: this_post.title,
    tagline: this_post.tagline,
    date: this_post.date,
    content: post_content,
    post-image: post_image,
  ))
}

#let posts = unsorted-posts.sorted(key: post => post.date, by: (a, b) => a >= b)
