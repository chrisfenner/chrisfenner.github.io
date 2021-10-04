Welcome to the blag.

Posts:

{% for post in site.posts %}
* [{{ post.date }}: {{ post.title }}]({{ post.url }})
{% endfor %}

That's all the posts.
