function getArticles(articleId, publishedAt) {
  if (!publishedAt || !articleId) {
    throw new Error('No article ID or published at date found');
  }

  var url = '/articles/' + articleId + '/collection_posts?published_at=' + publishedAt;

  return fetch(url).then(function(response) {
    if (!response.ok) {
      throw response;
    }

    return response.json();
  });
};

function handleUpdatedPost(collectionPost, data) {
  var i,
      posts = data.posts;

  collectionPost.data('publishedAt', data.published_at);

  for (i = 0; i < posts.length; i++) {
    App.articleQueue.push(posts[i]);
  }
}

function handleErrorOrNoResults(err) {
  if (!err.status) {
    throw err;
  }
  return;
}

function startPoller(article) {
  // Poll every 1 minute (milliseconds * seconds * minutes)
  var refreshInterval = 1000 * 60 * 1;

  var articleId = article.data('id');
  var collectionPost = article.find('article:first')

  setInterval(function() {
    var articlePublishedAt = collectionPost.data('publishedAt');

    getArticles(articleId, articlePublishedAt).then(function(data) {
      handleUpdatedPost(collectionPost, data);
    }).catch(handleErrorOrNoResults);

  }, refreshInterval)
}

$(function() {
  var article = $('article.h-entry[data-listen]')

  // Return early if no listening article is found
  if  (!article.data('listen')) { return }

  startPoller(article);
});

