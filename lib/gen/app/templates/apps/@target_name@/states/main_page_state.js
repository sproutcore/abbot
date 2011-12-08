<%= namespace %>.MainPageState = SC.State.extend({ 
  
  initialSubstate: 'loadMainPageState',
  
    loadMainPageState: SC.State.extend({

      enterState: function() {
        <%= namespace %>.getPath('mainPage.mainPane').append();
      },
    
      exitState:function() {
        <%= namespace %>.getPath('mainPage.mainPane').remove();
      }
      
    })

});