<%= namespace %>.ReadyState = SC.State.extend({ 
  
  enterState: function() {
    <%= namespace %>.getPath('mainPage.mainPane').append();
  },

  exitState: function() {
    <%= namespace %>.getPath('mainPage.mainPane').remove();
  }

});

