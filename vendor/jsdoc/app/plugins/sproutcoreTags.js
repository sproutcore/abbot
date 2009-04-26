JSDOC.PluginManager.registerPlugin(
  "JSDOC.sproutcoreTags",
  {
    onDocCommentTags: function(comment) {
      for (var i = 0, l = comment.tags.length; i < l; i++) {
        var title = comment.tags[i].title.toLowerCase();
        var syn;
        if ((syn = JSDOC.sproutcoreTags.synonyms["="+title])) {
          comment.tags[i].title = syn;
        }
      }
    }
  }
);

new Namespace(
  "JSDOC.sproutcoreTags",
  function() {
    JSDOC.sproutcoreTags.synonyms = {
      "=method":    "function",
      "=delegate":  "namespace",
      "=property":  "field",
      "=singleton": "class"
    }
  }
);