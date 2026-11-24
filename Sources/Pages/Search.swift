import Foundation
import Ignite

/// A client-side search page over a small JSON index of published posts.
/// The index is embedded in the page as an `application/json` script tag and
/// the page's inline script filters it as the user types — no server round-trip.
struct Search: StaticPage {
    @Environment(\.articles) var articles

    var title = "Search"
    var description = "Search the posts on this site by title, tag, or date."
    var path = "/search"

    var body: some HTML {
        Text("Search")
            .font(.title1)

        TextField("Search posts", prompt: "Type to filter…")
            .type(.search)
            .id("search-input")

        Section {
            Text("Loading…")
        }
        .class("search-results")
        .id("search-results")

        Script(code: jsonIndex)
            .type(value: "application/json")
            .id("search-index")

        Script(code: filterScript)
    }

    /// A JSON array of published posts (title, path, tags, date), safe to
    /// embed inside a `<script type="application/json">` tag: `<` is escaped
    /// so a title containing markup can never break out of the script element.
    private var jsonIndex: String {
        let posts = articles.all.map { article in
            [
                "title": article.title,
                "path": article.path,
                "tags": article.tags ?? [],
                "date": ISO8601DateFormatter().string(from: article.date)
            ]
        }
        let data = (try? JSONSerialization.data(withJSONObject: posts)) ?? Data()
        let json = String(data: data, encoding: .utf8) ?? "[]"
        return json.replacingOccurrences(of: "<", with: "\\u003c")
    }

    /// Filters the embedded index as the user types and renders matching posts
    /// into the results container. Elements are created via DOM APIs rather
    /// than innerHTML, so post titles can never inject markup.
    private var filterScript: String {
        """
        (function () {
          var input = document.getElementById('search-input');
          var results = document.getElementById('search-results');
          var index = document.getElementById('search-index');
          if (!input || !results || !index) { return; }

          var posts = [];
          try { posts = JSON.parse(index.textContent || '[]'); } catch (e) { posts = []; }

          function render(query) {
            var q = query.trim().toLowerCase();
            var matches = q === '' ? posts : posts.filter(function (p) {
              var hay = (p.title + ' ' + (p.tags || []).join(' ') + ' ' + p.date).toLowerCase();
              return hay.indexOf(q) !== -1;
            });

            results.innerHTML = '';

            if (matches.length === 0) {
              var empty = document.createElement('p');
              empty.className = 'search-empty';
              empty.textContent = q === '' ? 'No posts yet.' : 'No posts match the search.';
              results.appendChild(empty);
              return;
            }

            var list = document.createElement('ul');
            list.className = 'search-results-list';
            matches.forEach(function (p) {
              var li = document.createElement('li');
              var link = document.createElement('a');
              link.href = p.path;
              link.textContent = p.title;
              li.appendChild(link);
              if (p.tags && p.tags.length) {
                var meta = document.createElement('span');
                meta.className = 'search-meta';
                meta.textContent = p.tags.join(', ');
                li.appendChild(meta);
              }
              list.appendChild(li);
            });
            results.appendChild(list);
          }

          input.addEventListener('input', function () { render(input.value); });
          render('');
        })();
        """
    }
}
