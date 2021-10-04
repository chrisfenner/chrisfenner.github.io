Welcome to the blag.

Posts:

{% for post in site.posts %}
* [{{ post.title }}]({{ post.url }})
  * {{ post.excerpt }}
{% endfor %}

That's all the posts.
