from datetime import datetime, timezone
from feedgen.feed import FeedGenerator
import tomllib
from datetime import date, datetime, time
from zoneinfo import ZoneInfo

# Open the blog config
with open("config.toml", "rb") as f:
    config = tomllib.load(f)

fg = FeedGenerator()

fg.title(config["title"])
fg.link(href=config["url"])
fg.description(config["tagline"])
fg.language("en")

for post in config["posts"]:
    fe = fg.add_entry()
    fe.title(post["title"])
    fe.link(href=config["url"] + post["permalink"])
    fe.description(post["tagline"])
    fe.pubDate(datetime.combine(post["date"], time.min).replace(tzinfo=ZoneInfo("America/Los_Angeles")))

fg.rss_file("feed.xml", pretty=True)
print("RSS XML generated successfully via feedgen!")
