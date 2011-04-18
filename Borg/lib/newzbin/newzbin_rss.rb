require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
class NewzbinRss
  class << self
    def programme_pattern
      /(.*)\s-\s(\d{1,3})x(\d{1,3})\s-\s(.*)/
    end

    def movie_pattern

    end

  end
end

source = "http://newzbin.com/browse/category/p/movies/?ps_rb_language=4096&u_post_results_amt=50&u_v3_retention=20736000&u_post_larger_than=450&u_post_smaller_than=1700&u_post_states=0&u_completions=1&u_use_exclusions=1&apply=Apply&u_nfo_posts_only=0&u_url_posts_only=0&u_comment_posts_only=0&u_show_passworded=0&feed=rss&fauth=Njc3NjE0LTVhYTU5MWYwNmZlZjY0MDBhNjMzMzNkZmQzOWM3NzAyNmM0OGQ5NjA%3D;" # url or local file
content = "" # raw content of rss feed will be loaded here
open(source) do |s| content = s.read end
movies = RSS::Parser.parse(content, false)
source = "http://v3.newzbin.com/browse/category/p/tv/?ps_rb_language=4096&u_post_results_amt=50&u_v3_retention=20736000&u_post_larger_than=50&u_post_smaller_than=450&u_post_states=0&u_completions=1&u_use_exclusions=1&apply=Apply&u_nfo_posts_only=0&u_url_posts_only=0&u_comment_posts_only=0&u_show_passworded=0&feed=rss&fauth=Njc3NjE0LWZjNzliZGU5NzRlMDVlYTJmNjhhNzFjNDljNjk1YTllMTVkOTMxOGE%3D;:COOKIE:NzbSessionID=eea9e6e40b35902eecbd316abb26f4e7;NzbSmoke=gE9oFXIZs%24p0btaR9ggutN2ApnqqRMjz%2B33rY%3D"
content = "" # raw content of rss feed will be loaded here
open(source) do |s| content = s.read end
tv = RSS::Parser.parse(content, false)
puts(movies)
puts(tv)